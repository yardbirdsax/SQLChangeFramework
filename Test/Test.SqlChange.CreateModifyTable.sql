SET NOCOUNT ON;

DECLARE @TableDef sqlchange.t_TableDef;

INSERT INTO @TableDef
(
  ColumnName,
  DataTypeName,
  ColumnLength,
  ColumnPrecision,
  NullableFlag,
  DefaultVal
)
VALUES
(
  'MyColumn',
  'badtype',
  '-1',
  null,
  0,
  null
);

BEGIN TRY
  EXEC SQLChange.CreateModifyTable
       @TableName ='SomeTable',
       @TableSchema = 'dbo',
	  @TableDef = @TableDef;
  RAISERROR('Procedure did not throw error when invalid data type passed.',16,1);
END TRY
BEGIN CATCH
  DECLARE @ErrorMessage nvarchar(2048) = ERROR_MESSAGE();
  IF @ErrorMessage != 'One or more types specified do not exist in the database.' BEGIN
    RAISERROR('Test ''Check for invalid data types'' failed: %s',16,1,@ErrorMessage);
  END;
END CATCH;

DELETE FROM @TableDef;

INSERT INTO @TableDef
(
  ColumnName,
  DataTypeName,
  ColumnLength,
  ColumnPrecision,
  NullableFlag,
  DefaultVal,
  IdentityFlag
)
SELECT
  'MyColumn',
  'int',
  null,
  null,
  0,
  NULL,
  1
UNION
SELECT
  'MyColumn2',
  'varchar',
  '-1',
  null,
  0,
  null,
  0;

EXEC SQLChange.CreateModifyTable
  @TableName='SomeTable',
  @TableSchema='dbo',
  @TableDef = @TableDef;