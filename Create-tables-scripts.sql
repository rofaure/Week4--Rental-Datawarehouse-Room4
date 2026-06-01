USE RentalOperationsDB;
GO


--Creating schema
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'MiniProject')
    EXEC('CREATE SCHEMA MiniProject');
GO

--Creating tables without FK, constraints and checks
IF NOT EXISTS (SELECT * FROM sys.tables t join sys.schemas s ON (t.schema_id = s.schema_id) WHERE s.name='MiniProject' and t.name='Customer')
CREATE TABLE MiniProject.Customer
(
	 customer_id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	 first_name  nvarchar(50) NOT NULL ,
	 last_name   nvarchar(50) NOT NULL ,
	 address     nvarchar(200) NOT NULL ,
	 country     nvarchar(50) NOT NULL ,
	 city        nvarchar(50) NOT NULL ,
	 email       nvarchar(200) NOT NULL ,
	 phone       nvarchar(50) NOT NULL ,
);
GO

CREATE TABLE MiniProject.RentalLocation (
	rentallocation_id	INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	name NVARCHAR(50) NOT NULL,
	address NVARCHAR(200) NOT NULL,
	city NVARCHAR(50) NOT NULL,
	country NVARCHAR(50) NOT NULL,
	is_manned BIT NOT NULL DEFAULT 0,
	employee_id INT NULL,
);

CREATE TABLE MiniProject.RentalTransaction (
	transaction_id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	customer_id INT NOT NULL,
	pickup_location_id INT NOT NULL,
	return_location_id INT NULL,
	employee_id INT NULL,
	rental_start DATETIME NOT NULL,
	rental_end DATETIME NULL,
	total_amount DECIMAL(18,2) NULL,
);

CREATE TABLE MiniProject.RentalTransactionLines (
	transactionline_id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	transaction_id INT NOT NULL,
	item_id INT NOT NULL,
	line_amount DECIMAL(18,2) NULL,
);

