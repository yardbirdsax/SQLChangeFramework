SET NOCOUNT ON;

DECLARE @TableDef sqlchange.t_TableDef;

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES t WHERE t.TABLE_SCHEMA = 'dbo' AND t.TABLE_NAME = 'IndexTable')
  DROP TABLE dbo.IndexTable;

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
  0
UNION
SELECT
  'MyColumn3',
  'datetime',
  null,
  null,
  0,
  null,
  0;

EXEC SQLChange.CreateModifyTable
  @TableName='IndexTable',
  @TableSchema='dbo',
  @TableDef = @TableDef,
  @ForReal = 1;

DECLARE @IndexDef sqlchange.t_IndexDef;

INSERT INTO @IndexDef
VALUES (1, 'MyColumn',0,0);

-- Should create index
EXEC sqlchange.CreateModifyIndex
	@TableName = N'IndexTable',
	@TableSchema = N'dbo',
	@IndexDef = @IndexDef,
	@IndexName = N'IXIndexTable',
	@ForReal = 1;

INSERT INTO @IndexDef
VALUES (1, 'MyColumn2',1,0);

-- Should drop an recreate index with included column
EXEC sqlchange.CreateModifyIndex
	@TableName = N'IndexTable',
	@TableSchema = N'dbo',
	@IndexDef = @IndexDef,
	@IndexName = N'IXIndexTable',
	@ForReal = 1;

-- Should do nothing
EXEC sqlchange.CreateModifyIndex
	@TableName = N'IndexTable',
	@TableSchema = N'dbo',
	@IndexDef = @IndexDef,
	@IndexName = N'IXIndexTable',
	@ForReal = 1;

DROP INDEX IXIndexTable on dbo.IndexTable;
CREATE INDEX IXIndexTable on dbo.IndexTable (MyColumn) INCLUDE (MyColumn2,MyColumn3);

-- Should drop an recreate index with only one included column
EXEC sqlchange.CreateModifyIndex
	@TableName = N'IndexTable',
	@TableSchema = N'dbo',
	@IndexDef = @IndexDef,
	@IndexName = N'IXIndexTable',
	@ForReal = 1;

UPDATE @IndexDef SET [@IndexDef].DescOrderFlag = 1 WHERE [@IndexDef].ColumnName = 'MyColumn';

-- Should drop an recreate index with the key column being descending
EXEC sqlchange.CreateModifyIndex
	@TableName = N'IndexTable',
	@TableSchema = N'dbo',
	@IndexDef = @IndexDef,
	@IndexName = N'IXIndexTable',
	@ForReal = 1;

-- Should drop an recreate index as unique
EXEC sqlchange.CreateModifyIndex
	@TableName = N'IndexTable',
	@TableSchema = N'dbo',
	@IndexDef = @IndexDef,
	@IndexName = N'IXIndexTable',
     @UniqueFlag = 1,
	@ForReal = 1;