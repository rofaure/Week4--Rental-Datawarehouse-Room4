USE RentalOperationsDB;
GO

-- ============================================================
--Creating schema
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'MiniProject')
    EXEC('CREATE SCHEMA MiniProject');
GO

-- ============================================================
--Creating tables without FK, constraints and checks
-- ============================================================
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
	 phone       nvarchar(50) NOT NULL
);
GO

CREATE TABLE MiniProject.RentalLocation (
	rentallocation_id	INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	name NVARCHAR(50) NOT NULL,
	address NVARCHAR(200) NOT NULL,
	city NVARCHAR(50) NOT NULL,
	country NVARCHAR(50) NOT NULL,
	is_manned BIT NOT NULL DEFAULT 0,
	employee_id INT NULL
);

CREATE TABLE MiniProject.RentalTransaction (
	transaction_id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	customer_id INT NOT NULL,
	pickup_location_id INT NOT NULL,
	return_location_id INT NULL,
	rental_start DATETIME NOT NULL,
	rental_end DATETIME NULL,
	total_amount DECIMAL(18,2) NULL
);

CREATE TABLE MiniProject.RentalTransactionLines (
	transactionline_id INT IDENTITY(1,1) NOT NULL,
	transaction_id INT NOT NULL,
	item_id INT NOT NULL,
	line_amount DECIMAL(18,2) NULL,
CONSTRAINT PK_RentalTransactionLines PRIMARY KEY (transaction_id, transactionline_id)
);

CREATE TABLE MiniProject.Employee (
	employee_id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	first_name nvarchar(50) NOT NULL,
	last_name nvarchar(50) NOT NULL,
	role nvarchar(50) NOT NULL
);

CREATE TABLE MiniProject.EquipmentCategory (
	category_id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	name nvarchar(50) NOT NULL
);

CREATE TABLE MiniProject.Model (
	model_id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	category_id INT NOT NULL,
	brand nvarchar(50) NOT NULL,
	name nvarchar(50) NOT NULL,
	hourly_rate decimal(18,2) NOT NULL
);

CREATE TABLE MiniProject.Item (
	item_id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	model_id INT NOT NULL,
	status nvarchar(50) NOT NULL,
	serial_number nvarchar(50) NOT NULL,
	is_usable bit NOT NULL
);

CREATE TABLE MiniProject.MaintenanceRecord (
	maintenance_id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
	maintenance_start date NOT NULL,
	maintenance_end date NULL,
	type nvarchar(50) NULL,
	cost decimal(18,2) NOT NULL,
	item_id INT NOT NULL
);

-- ============================================================
-- FOREIGN KEYS
-- ============================================================
ALTER TABLE MiniProject.RentalLocation
ADD CONSTRAINT FK_RentalLocation_Employee
FOREIGN KEY (employee_id)
REFERENCES MiniProject.Employee(employee_id);
 
ALTER TABLE MiniProject.Model
ADD CONSTRAINT FK_Model_Category
FOREIGN KEY (category_id)
REFERENCES MiniProject.EquipmentCategory(category_id);
 
ALTER TABLE MiniProject.Item
ADD CONSTRAINT FK_Item_Model
FOREIGN KEY (model_id)
REFERENCES MiniProject.Model(model_id);
 
ALTER TABLE MiniProject.RentalTransaction
ADD CONSTRAINT FK_RentalTransaction_Customer
FOREIGN KEY (customer_id)
REFERENCES MiniProject.Customer(customer_id);
 
ALTER TABLE MiniProject.RentalTransaction
ADD CONSTRAINT FK_RentalTransaction_Pickup
FOREIGN KEY (pickup_location_id)
REFERENCES MiniProject.RentalLocation(rentallocation_id);
 
ALTER TABLE MiniProject.RentalTransaction
ADD CONSTRAINT FK_RentalTransaction_Return
FOREIGN KEY (return_location_id)
REFERENCES MiniProject.RentalLocation(rentallocation_id);
 
ALTER TABLE MiniProject.RentalTransactionLines
ADD CONSTRAINT FK_RentalLines_Transaction
FOREIGN KEY (transaction_id)
REFERENCES MiniProject.RentalTransaction(transaction_id);
 
ALTER TABLE MiniProject.RentalTransactionLines
ADD CONSTRAINT FK_RentalLines_Item
FOREIGN KEY (item_id)
REFERENCES MiniProject.Item(item_id);
 
ALTER TABLE MiniProject.MaintenanceRecord
ADD CONSTRAINT FK_Maintenance_Item
FOREIGN KEY (item_id)
REFERENCES MiniProject.Item(item_id);

-- ============================================================
-- UNIQUE CONSTRAINTS 
-- ============================================================
ALTER TABLE MiniProject.Customer
ADD CONSTRAINT UQ_Customer_Email
UNIQUE (email);
 
ALTER TABLE MiniProject.RentalTransactionLines
ADD CONSTRAINT CK_RentalLines_LineAmount
CHECK (line_amount IS NULL OR line_amount > 0);
 
ALTER TABLE MiniProject.Item
ADD CONSTRAINT UQ_Item_SerialNumber
UNIQUE (serial_number);
 
ALTER TABLE MiniProject.RentalTransactionLines
ADD CONSTRAINT UQ_RentalLines_TransactionItem
UNIQUE (transaction_id, item_id);
GO
 
 
-- ============================================================
-- CHECK CONSTRAINTS
-- ============================================================
 
ALTER TABLE MiniProject.Item
ADD CONSTRAINT CK_Item_Status
CHECK (status IN ('available', 'rented', 'maintenance', 'retired'));
 
ALTER TABLE MiniProject.RentalTransaction
ADD CONSTRAINT CK_RentalTransaction_Dates
CHECK (rental_end IS NULL OR rental_end > rental_start);
 
ALTER TABLE MiniProject.MaintenanceRecord
ADD CONSTRAINT CK_Maintenance_Dates
CHECK (maintenance_end IS NULL OR maintenance_end > maintenance_start);
 
ALTER TABLE MiniProject.MaintenanceRecord
ADD CONSTRAINT CK_Maintenance_Type
CHECK (type IN ('Inspection', 'Repair', 'Battery Replacement', 'Other'));
GO
