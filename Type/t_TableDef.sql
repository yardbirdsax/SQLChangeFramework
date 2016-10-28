EXEC sqlchange.dropdependentroutines 'sqlchange','t_tabledef',1;
IF EXISTS (SELECT 1 FROM sys.types t WHERE t.name = 't_TableDef' AND SCHEMA_NAME(t.schema_id) = 'SQLChange')
  DROP TYPE SQLChange.t_TableDef;
GO

CREATE TYPE SQLChange.t_TableDef AS TABLE
(
  ColumnID INT IDENTITY,
  ColumnName sysname PRIMARY KEY,
  DataTypeName sysname,
  ColumnLength int,
  ColumnPrecision int,
  NullableFlag bit DEFAULT 0,
  DefaultVal nvarchar(4000),
  IdentityFlag bit DEFAULT 0
);

