SET QUOTED_IDENTIFIER ON;

IF NOT EXISTS (SELECT 1
                 FROM INFORMATION_SCHEMA.ROUTINES
                WHERE ROUTINE_NAME = 'CreateModifyIndex'
                  AND ROUTINE_SCHEMA = 'SQLChange')
BEGIN
  EXEC ('CREATE PROCEDURE SQLChange.CreateModifyIndex AS BEGIN PRINT ''STUB FOR PROCEDURE'' END');
END  
GO

/***
=StartDoc
================================================================================
# CreateModifyIndex
Author      : Joshua Feierman

=head2 Description
Creates or modifies a index based on provided descriptions about the makeup of the index.

This code and all contents are copyright 2016 Joshua Feierman, all rights reserved, and is released under the
Apache License 2.0.

===============================================================================
## Parameters

Name                  | I/O   | Description
--------------------- | ----- | -------------------------------------------------
TableName             | I     | The name of the table being created / modified.
TableSchema           | I     | The schema in which the table resides.
IndexName             | I     | The name of the index to be created.
IndexDef              | I     | A user defined table type that contains metadata about the columns for the index.
UniqueFlag            | I     | If set to 1, the index will be marked as unique.

## Result Set

Column Name   | Data Type       | Source Procedure        | Description
------------- | --------------- | ----------------------- | ------------------------
If record set is retuned give brief description of the fields being returned

Return Value: Return code
     Success : 0
     Failure : Error number and Description

## Revisions

Ini|   Date   | Description
-- | -------- | -------------------------------------------------------------

=enddoc
================================================================================
***/

ALTER PROCEDURE SQLChange.CreateModifyIndex
  @TableName sysname,
  @TableSchema sysname,
  @IndexDef SQLChange.t_IndexDef READONLY,
  @IndexName sysname,
  @UniqueFlag bit = 0,
  @ForReal bit = 0
AS

DECLARE @SQL nvarchar(max);
DECLARE @DropFl bit = 0;
DECLARE @CreateFl bit = 1;

-- If the index with the same name exists and the definition doesn't match, then drop it
IF EXISTS (
  SELECT 1 
    FROM sys.indexes i JOIN sys.objects o ON o.object_id = i.object_id
         JOIN sys.schemas s ON s.schema_id = o.schema_id
   WHERE i.name = @IndexName
         AND o.name = @TableName
         AND s.name = @TableSchema
)
BEGIN

  IF EXISTS (
    -- Will show results where columns are part of index definition but not in existing index
    (
    SELECT ColumnID
          ,ColumnName
          ,DescOrderFlag
      FROM @IndexDef
     WHERE IncludeColFlag = 0
    EXCEPT
    SELECT ic.key_ordinal
          ,c.name
          ,ic.is_descending_key
      FROM sys.indexes i JOIN sys.objects o ON o.object_id = i.object_id
           JOIN sys.schemas s ON s.schema_id = o.schema_id
           JOIN sys.index_columns ic ON ic.index_id = i.index_id
            AND ic.object_id = i.object_id
           JOIN sys.columns c ON c.column_id = ic.column_id
            AND c.object_id = i.object_id
     WHERE i.name = @IndexName
           AND o.name = @TableName
           AND s.name = @TableSchema
           AND ic.is_included_column = 0
    )
    UNION ALL
    -- Will show results where columns in existing index but not in desired definition
    (
    SELECT ic.key_ordinal
          ,c.name
          ,ic.is_descending_key
      FROM sys.indexes i JOIN sys.objects o ON o.object_id = i.object_id
           JOIN sys.schemas s ON s.schema_id = o.schema_id
           JOIN sys.index_columns ic ON ic.index_id = i.index_id
            AND ic.object_id = i.object_id
           JOIN sys.columns c ON c.column_id = ic.column_id
            AND c.object_id = i.object_id
     WHERE i.name = @IndexName
           AND o.name = @TableName
           AND s.name = @TableSchema
           AND ic.is_included_column = 0
    EXCEPT 
    SELECT ColumnID
          ,ColumnName
          ,DescOrderFlag
      FROM @IndexDef
     WHERE IncludeColFlag = 0
    )
  ) OR EXISTS (
    (
      SELECT ColumnName
        FROM @IndexDef
        WHERE IncludeColFlag = 1
      EXCEPT
      SELECT c.name
        FROM sys.indexes i JOIN sys.objects o ON o.object_id = i.object_id
              JOIN sys.schemas s ON s.schema_id = o.schema_id
              JOIN sys.index_columns ic ON ic.index_id = i.index_id
              AND ic.object_id = i.object_id
              JOIN sys.columns c ON c.column_id = ic.column_id
              AND c.object_id = i.object_id
        WHERE i.name = @IndexName
              AND o.name = @TableName
              AND s.name = @TableSchema
              AND ic.is_included_column = 1
    )
    UNION ALL
    (
      SELECT c.name
        FROM sys.indexes i JOIN sys.objects o ON o.object_id = i.object_id
              JOIN sys.schemas s ON s.schema_id = o.schema_id
              JOIN sys.index_columns ic ON ic.index_id = i.index_id
              AND ic.object_id = i.object_id
              JOIN sys.columns c ON c.column_id = ic.column_id
              AND c.object_id = i.object_id
        WHERE i.name = @IndexName
              AND o.name = @TableName
              AND s.name = @TableSchema
              AND ic.is_included_column = 1
      EXCEPT
      SELECT ColumnName
        FROM @IndexDef
        WHERE IncludeColFlag = 1
    )
  )
  BEGIN -- The index exists but the definition does not match, so it must be dropped.
    SET @DropFl = 1;
    RAISERROR('Dropping index %s on %s.%s.',10,1,@IndexName,@TableSchema,@TableName) WITH NOWAIT;
  END;
  ELSE IF EXISTS (
    SELECT 1 
      FROM sys.indexes i JOIN sys.objects o ON o.object_id = i.object_id
           JOIN sys.schemas s ON s.schema_id = o.schema_id
     WHERE i.name = @IndexName
           AND o.name = @TableName
           AND s.name = @TableSchema
           AND ((i.is_unique = 0 AND @UniqueFlag = 1) OR (i.is_unique = 1 AND @UniqueFlag = 0))
  )
  BEGIN -- The index exists but the unique attribute does not match, so it must be dropped.
    SET @DropFl = 1;
    RAISERROR('Dropping index %s on %s.%s.',10,1,@IndexName,@TableSchema,@TableName) WITH NOWAIT;
  END;
  ELSE BEGIN  -- The index exists, but the definition matches so nothing needs to be done.
    SET @CreateFl = 0;
    RAISERROR('No changes for index %s on %s.%s.',10,1,@IndexName,@TableSchema,@TableName) WITH NOWAIT;
  END;
END; -- If index with matching name exists

-- Create index if it does not exist
IF @CreateFl = 1 BEGIN
  RAISERROR('Creating index %s on %s.%s.',10,1,@IndexName,@TableSchema,@TableName) WITH NOWAIT;
  SET @SQL = 'CREATE ' + CASE @UniqueFlag WHEN 1 THEN ' UNIQUE ' ELSE '' END + 
              'INDEX ' + QUOTENAME(@IndexName) + ' ON ' + QUOTENAME(@TableSchema) + '.' + QUOTENAME(@TableName) + '( ' + (
    SELECT CASE t.ColumnID WHEN 1 THEN '' ELSE ',' END + CHAR(13) +
            quotename(t.ColumnName) + 
            CASE t.DescOrderFlag WHEN 1 THEN ' DESC ' ELSE '' END
      FROM @IndexDef t
     WHERE t.IncludeColFlag = 0
    ORDER BY t.ColumnID
    FOR XML PATH(''),TYPE,ROOT('MySQL')
  ).value('(/MySQL)[1]','nvarchar(max)') + ')';

  IF EXISTS (SELECT 1 FROM @IndexDef WHERE IncludeColFlag = 1)
    SET @SQL = @SQL + ' INCLUDE ( ' + (
      SELECT CASE t.ColumnID WHEN 1 THEN '' ELSE ',' END + CHAR(13) +
              quotename(t.ColumnName)
        FROM @IndexDef t
       WHERE t.IncludeColFlag = 1
      ORDER BY t.ColumnID
      FOR XML PATH(''),TYPE,ROOT('MySQL')
    ).value('(/MySQL)[1]','nvarchar(max)') + ')';

  SET @SQL = @SQL + ';';

END; -- Create index if not exists

IF @DropFl = 1
  SET @SQL = 'DROP INDEX ' + QUOTENAME(@IndexName) + ' ON ' + QUOTENAME(@TableSchema) + '.' + QUOTENAME(@TableName) + ';' + CHAR(13) + @SQL;

IF @ForReal = 0
  RAISERROR(@SQL,10,1) WITH NOWAIT;
ELSE
  EXEC sp_executesql @SQL;


GO

SET QUOTED_IDENTIFIER OFF;