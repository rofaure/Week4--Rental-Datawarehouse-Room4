-- ============================================================
--Creating database_name
-- ============================================================

CREATE DATABASE RentalDW;
GO


USE RentalDW;
GO

-- ============================================================
--Creating schema
-- ============================================================

CREATE SCHEMA MiniProject;
GO

-- ============================================================
--Creating tables without FK, constraints and checks
-- ============================================================

-- ************************************** MiniProject.DimCustomer
CREATE TABLE MiniProject.DimCustomer
(
 customer_key int NOT NULL ,
 customer_id  int NOT NULL ,
 first_name   nvarchar(50) NOT NULL ,
 last_name    nvarchar(50) NOT NULL ,
 address      nvarchar(200) NOT NULL ,
 city         nvarchar(50) NOT NULL ,
 country      nvarchar(50) NOT NULL ,
 email        nvarchar(200) NOT NULL ,
 phone        nvarchar(50) NOT NULL ,

 CONSTRAINT PK_1 PRIMARY KEY CLUSTERED (customer_key ASC)
);
GO

-- ************************************** MiniProject.DimDate
CREATE TABLE MiniProject.DimDate
(
 date_key int NOT NULL ,
 [date]   date NOT NULL ,
 [year]   int NOT NULL ,
 quarter  tinyint NOT NULL ,
 [month]  tinyint NOT NULL ,
 week     tinyint NOT NULL ,
 [day]    tinyint NOT NULL ,

 CONSTRAINT PK_1 PRIMARY KEY CLUSTERED (date_key ASC)
);
GO

-- ************************************** MiniProject.DimGeography
CREATE TABLE MiniProject.DimGeography
(
 geography_key     int NOT NULL ,
 rentallocation_id int NOT NULL ,
 name              nvarchar(50) NOT NULL ,
 address           nvarchar(200) NOT NULL ,
 city              nvarchar(50) NOT NULL ,
 country           nvarchar(50) NOT NULL ,
 is_manned         bit NOT NULL ,

 CONSTRAINT PK_1 PRIMARY KEY CLUSTERED (geography_key ASC)
);
GO

-- ************************************** MiniProject.DimItem
CREATE TABLE MiniProject.DimItem
(
 item_key          int NOT NULL ,
 item_id           int NOT NULL ,
 model_id          int NOT NULL ,
 category_id       int NOT NULL ,
 maintenance_id    int NOT NULL ,
 category_name     nvarchar(50) NOT NULL ,
 model_brand       nvarchar(50) NOT NULL ,
 model_name        nvarchar(50) NOT NULL ,
 status            nvarchar(50) NOT NULL ,
 serial_number     nvarchar(50) NOT NULL ,
 hourly_rate       decimal(18,2) NOT NULL ,
 is_usable         bit NOT NULL ,
 maintenance_start date NOT NULL ,
 maintenance_end   date NULL ,
 maintenance_type  nvarchar(50) NOT NULL ,
 maintenance_cost  decimal(18,2) NOT NULL ,

 CONSTRAINT PK_1 PRIMARY KEY CLUSTERED (item_key ASC)
);
GO

-- ************************************** MiniProject.FactSales
CREATE TABLE MiniProject.FactSales
(
 transaction_id     int identity NOT NULL ,
 transactionline_id int identity NOT NULL ,
 customer_key       int NOT NULL ,
 startdate_key      int NOT NULL ,
 enddate_key        int NULL ,
 geography_key      int NOT NULL ,
 item_key           int NOT NULL ,
 total_amount       decimal(18,2) NULL ,
 price              decimal(18,2) NOT NULL ,
 start_time         time NOT NULL ,
 end_time           time NULL ,

 CONSTRAINT PK_1 PRIMARY KEY CLUSTERED (transaction_id ASC, transactionline_id ASC),
 CONSTRAINT FK_1 FOREIGN KEY (customer_key)  REFERENCES MiniProject.DimCustomer(customer_key),
 CONSTRAINT FK_2 FOREIGN KEY (startdate_key)  REFERENCES MiniProject.DimDate(date_key),
 CONSTRAINT FK_3 FOREIGN KEY (enddate_key)  REFERENCES MiniProject.DimDate(date_key),
 CONSTRAINT FK_4 FOREIGN KEY (geography_key)  REFERENCES MiniProject.DimGeography(geography_key),
 CONSTRAINT FK_5 FOREIGN KEY (item_key)  REFERENCES MiniProject.DimItem(item_key)
);
GO