-- ============================================================
-- Delete all data from all tables in RentalOperationsDB
-- ============================================================

USE RentalOperationsDB;
GO

-- Drop all foreign keys in MiniProject schema
DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql += N'
ALTER TABLE ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) +
N' DROP CONSTRAINT ' + QUOTENAME(fk.name) + N';'
FROM sys.foreign_keys fk
JOIN sys.tables t ON fk.parent_object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = 'MiniProject';

EXEC sp_executesql @sql;
GO

-- Drop all remaining constraints: PK, UQ, CK, DEFAULT
DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql += N'
ALTER TABLE ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) +
N' DROP CONSTRAINT ' + QUOTENAME(c.name) + N';'
FROM sys.objects c
JOIN sys.tables t ON c.parent_object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = 'MiniProject'
  AND c.type IN ('PK', 'UQ', 'C', 'D');

EXEC sp_executesql @sql;
GO

-- Drop tables
DROP TABLE IF EXISTS MiniProject.MaintenanceRecord;
DROP TABLE IF EXISTS MiniProject.RentalTransactionLines;
DROP TABLE IF EXISTS MiniProject.RentalTransaction;
DROP TABLE IF EXISTS MiniProject.RentalLocation;
DROP TABLE IF EXISTS MiniProject.Item;
DROP TABLE IF EXISTS MiniProject.Model;
DROP TABLE IF EXISTS MiniProject.EquipmentCategory;
DROP TABLE IF EXISTS MiniProject.Employee;
DROP TABLE IF EXISTS MiniProject.Customer;
GO

-- Optional: drop schema if empty
DROP SCHEMA IF EXISTS MiniProject;
GO
