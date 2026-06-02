USE RentalDW;
GO

-- Drop stored procedures in the schema first
DROP PROCEDURE IF EXISTS MiniProject.usp_Load_DimGeography;
DROP PROCEDURE IF EXISTS MiniProject.usp_Load_DimItem;
DROP PROCEDURE IF EXISTS MiniProject.usp_Load_DimCustomer;
DROP PROCEDURE IF EXISTS MiniProject.usp_Load_DimDate;
DROP PROCEDURE IF EXISTS MiniProject.usp_Load_FactSales;
GO

-- Drop all foreign keys in MiniProject schema
DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql += N'
ALTER TABLE ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) +
N' DROP CONSTRAINT ' + QUOTENAME(fk.name) + N';'
FROM sys.foreign_keys fk
JOIN sys.tables t 
    ON fk.parent_object_id = t.object_id
JOIN sys.schemas s 
    ON t.schema_id = s.schema_id
WHERE s.name = 'MiniProject';

EXEC sp_executesql @sql;
GO

-- Drop remaining constraints
DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql += N'
ALTER TABLE ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) +
N' DROP CONSTRAINT ' + QUOTENAME(c.name) + N';'
FROM sys.objects c
JOIN sys.tables t 
    ON c.parent_object_id = t.object_id
JOIN sys.schemas s 
    ON t.schema_id = s.schema_id
WHERE s.name = 'MiniProject'
  AND c.type IN ('PK', 'UQ', 'C', 'D');

EXEC sp_executesql @sql;
GO

-- Drop tables
DROP TABLE IF EXISTS MiniProject.FactSales;
DROP TABLE IF EXISTS MiniProject.DimItem;
DROP TABLE IF EXISTS MiniProject.DimGeography;
DROP TABLE IF EXISTS MiniProject.DimDate;
DROP TABLE IF EXISTS MiniProject.DimCustomer;
GO

-- Drop schema
DROP SCHEMA IF EXISTS MiniProject;
GO