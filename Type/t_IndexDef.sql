EXEC sqlchange.dropdependentroutines 'sqlchange','t_IndexDef',1;
IF EXISTS (SELECT 1 FROM sys.types t WHERE t.name = 't_IndexDef' AND SCHEMA_NAME(t.schema_id) = 'SQLChange')
  DROP TYPE SQLChange.t_IndexDef;
GO

CREATE TYPE SQLChange.t_IndexDef AS TABLE
(
  ColumnID INT,
  ColumnName sysname PRIMARY KEY,
  IncludeColFlag bit DEFAULT 0,
  DescOrderFlag bit DEFAULT 0
);

