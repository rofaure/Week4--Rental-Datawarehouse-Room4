CREATE OR ALTER PROCEDURE MiniProject.LoadDimCustomer
AS
BEGIN
    SET NOCOUNT ON;

INSERT INTO MiniProject.DimCustomer
(
    customer_key,
    customer_id,
    first_name,
    last_name,
    address,
    city,
    country,
    email,
    phone
)
SELECT
    ROW_NUMBER() OVER (ORDER BY c.customer_id) AS customer_key,
    c.customer_id,
    c.first_name,
    c.last_name,
    c.address,
    c.city,
    c.country,
    c.email,
    c.phone
FROM RentalOperationsDB.MiniProject.Customer c
END;
GO

EXEC RentalDW.MiniProject.LoadDimCustomer;
GO

-- Compare customer rows between operational database and data warehouse

-- SELECT *
-- FROM RentalOperationsDB.MiniProject.Customer
-- GO

-- SELECT *
-- FROM RentalDW.MiniProject.DimCustomer
-- GO