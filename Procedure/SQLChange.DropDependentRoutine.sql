SET QUOTED_IDENTIFIER ON;

IF NOT EXISTS (SELECT 1
                 FROM INFORMATION_SCHEMA.ROUTINES
                WHERE ROUTINE_NAME = 'DropDependentRoutines'
                  AND ROUTINE_SCHEMA = 'SQLChange')
BEGIN
  EXEC ('CREATE PROCEDURE SQLChange.DropDependentRoutines AS BEGIN PRINT ''STUB FOR PROCEDURE'' END');
END  
GO

/***
=StartDoc
================================================================================
# DropDependentRoutines
**Author      : Joshua Feierman**

## Description
Drops all programmable objects associated with a given object.

This code and all contents are copyright 2016 Joshua Feierman, all rights reserved.

===============================================================================
## Parameters

Name                  | I/O   | Description
 -------------------- | ----- | -------------------------------------------------


## Result Set

Column Name   | Data Type       | Source Procedure        | Description
------------------ | ----------------- | -------------------------- | ------------------------
If record set is retuned give brief description of the fields being returned

Return Value: Return code
     Success : 0
     Failure : Error number and Description

## Revisions

Ini        |   Date   | Description
-------  | -------- | -------------------------------------------------------------

=enddoc
================================================================================
***/

ALTER PROCEDURE SQLChange.DropDependentRoutines
  @ObjectSchema sysname,
  @ObjectName sysname,
  @ForReal bit = 0
AS

DECLARE @SQL nvarchar(max);

SET @SQL = (
SELECT 'RAISERROR(''Dropping object ' + s.name + '.' + o.name +'.'',10,1) WITH NOWAIT;
        DROP ' + CASE o.type_desc WHEN 'SQL_STORED_PROCEDURE' THEN 'PROCEDURE' END +
        ' ' + QUOTENAME(s.name) + '.' + QUOTENAME(o.name) + ';'
--SELECT o.name,o.type_desc
  FROM sys.sql_expression_dependencies sed JOIN sys.objects o ON sed.referencing_id = o.object_id
       JOIN sys.schemas s ON s.schema_id = o.schema_id
 WHERE sed.referenced_schema_name = @ObjectSchema
       AND sed.referenced_entity_name = @ObjectName
FOR XML PATH(''),TYPE,ROOT('MySQL')
).value('(/MySQL)[1]','nvarchar(max)');

IF @ForReal = 1
  EXEC sp_executesql @SQL;
ELSE
  RAISERROR(@SQL,10,1) WITH NOWAIT;
GO

SET QUOTED_IDENTIFIER OFF;