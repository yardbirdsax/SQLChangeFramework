SET QUOTED_IDENTIFIER ON;

IF NOT EXISTS (SELECT 1
                 FROM INFORMATION_SCHEMA.ROUTINES
                WHERE ROUTINE_NAME = 'CreateModifyTable'
                  AND ROUTINE_SCHEMA = 'SQLChange')
BEGIN
  EXEC ('CREATE PROCEDURE SQLChange.CreateModifyTable AS BEGIN PRINT ''STUB FOR PROCEDURE'' END');
END  
GO

/***
=StartDoc
================================================================================
# CreateModifyTable
Author      : Joshua Feierman

=head2 Description
Creates or modifies a table based on provided descriptions about the makeup of the table.

This code and all contents are copyright 2016 Joshua Feierman, all rights reserved.

===============================================================================
## Parameters

Name                  | I/O   | Description
--------------------- | ----- | -------------------------------------------------
TableName             | I     | The name of the table being created / modified.
TableSchema           | I     | The schema in which the table resides.
TableDef              | I     | A user defined table type that contains metadata about the columns for the table.

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

ALTER PROCEDURE SQLChange.CreateModifyTable
  @TableName sysname,
  @TableSchema sysname,
  @TableDef SQLChange.t_TableDef READONLY,
  @ForReal bit = 0
AS

DECLARE @SQL nvarchar(max);

-- Check if the passed in type is present.
IF EXISTS (SELECT DataTypeName FROM @TableDef WHERE DataTypeName NOT IN (SELECT name FROM sys.types t)) BEGIN
  RAISERROR('One or more types specified do not exist in the database.',16,1);
  RETURN;
END;

-- Create table if it does not exist
IF NOT EXISTS (
  SELECT 1
   FROM INFORMATION_SCHEMA.TABLES t
  WHERE t.TABLE_SCHEMA = @TableSchema
        AND t.TABLE_NAME = @TableName
) BEGIN

  SET @SQL = 'CREATE TABLE ' + QUOTENAME(@TableSchema) + '.' + QUOTENAME(@TableName) + '( ' + (
    SELECT quotename(t.ColumnName) + ' ' + t.DataTypeName + 
            CASE 
              WHEN t.DataTypeName IN ('varchar','nvarchar') THEN '(' + CASE t.ColumnLength WHEN -1 THEN 'MAX' ELSE CONVERT(varchar,t.ColumnLength) END + ')' 
              WHEN t.DataTypeName = 'DECIMAL' then '(' + convert(varchar,t.ColumnLength) + ',' + convert(varchar,t.ColumnPrecision) + ')'
              ELSE ''
            END + 
            CASE t.IdentityFlag WHEN 1 THEN ' IDENTITY ' ELSE '' END +
            CASE t.NullableFlag WHEN 0 THEN ' NOT NULL' ELSE '' END +
            CASE t.ColumnID WHEN 1 THEN '' ELSE ',' END + CHAR(13)
      FROM @TableDef t
    FOR XML PATH(''),TYPE,ROOT('MySQL')
  ).value('(/MySQL)[1]','nvarchar(max)') + ');';

  IF @ForReal = 0
    RAISERROR(@SQL,10,1) WITH NOWAIT;
  ELSE
    EXEC sp_executesql @SQL;

END; -- Create table if not exists

GO

SET QUOTED_IDENTIFIER OFF;