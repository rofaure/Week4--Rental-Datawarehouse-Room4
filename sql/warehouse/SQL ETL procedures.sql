USE RentalDW;
GO

-- Run this block before executing any procedure
TRUNCATE TABLE MiniProject.FactSales;      -- fact first
TRUNCATE TABLE MiniProject.DimDate;
TRUNCATE TABLE MiniProject.DimCustomer;
TRUNCATE TABLE MiniProject.DimGeography;
TRUNCATE TABLE MiniProject.DimItem;
GO

--DimGeography loading procedure
ALTER PROCEDURE MiniProject.usp_Load_DimGeography
AS
BEGIN
    SET NOCOUNT ON;

    -- Drop FK constraint temporarily
    ALTER TABLE MiniProject.FactSales
        DROP CONSTRAINT FK_FactSales_DimGeography;

    DELETE FROM MiniProject.DimGeography;

    INSERT INTO MiniProject.DimGeography (
        geography_key,
        rentallocation_id,
        name,
        address,
        city,
        country,
        is_manned
    )
    SELECT
        ROW_NUMBER() OVER (ORDER BY rl.rentallocation_id) AS geography_key,
        rl.rentallocation_id,
        rl.name,
        rl.address,
        rl.city,
        rl.country,
        rl.is_manned
    FROM RentalOperationsDB.MiniProject.RentalLocation rl;

    -- Recreate FK constraint
    ALTER TABLE MiniProject.FactSales
        ADD CONSTRAINT FK_FactSales_DimGeography
            FOREIGN KEY (geography_key)
            REFERENCES MiniProject.DimGeography(geography_key);

END;
GO

EXEC MiniProject.usp_Load_DimGeography;
GO
SELECT * FROM MiniProject.DimGeography;

-- FactSales loading procedure
CREATE PROCEDURE MiniProject.usp_Load_FactSales
AS 
BEGIN
	SET NOCOUNT ON;

	DELETE FROM MiniProject.FactSales;
    DELETE FROM MiniProject.DimGeography;

	INSERT INTO MiniProject.FactSales (
		transaction_id, 
		transactionline_id, 
		customer_key, 
		startdate_key, 
		enddate_key,
		geography_key,
		item_key, 
		total_amount, 
		price, 
		start_time, 
		end_time)

	SELECT 
		rt.transaction_id,
		rtl.transactionline_id,
		dc.customer_key,
		dd_start.date_key AS startdate_key,
		dd_end.date_key AS enddate_key,
		dg.geography_key,
		di.item_key,
		rt.total_amount,
		rtl.line_amount AS price,
		CAST(rt.rental_start AS TIME) AS start_time,
		CAST(rt.rental_end AS TIME) AS end_time
		--DATEDIFF(MINUTE, rt.rental_start, rt.rental_end) AS rental_duration_minutes,
	FROM RentalOperationsDB.MiniProject.RentalTransaction AS rt
	JOIN RentalOperationsDB.MiniProject.RentalTransactionLines AS rtl 
		ON rt.transaction_id = rtl.transaction_id
	JOIN MiniProject.DimDate AS dd_start
		ON CAST(rt.rental_start AS DATE) = dd_start.date
	LEFT JOIN MiniProject.DimDate AS dd_end
		ON CAST(rt.rental_end AS DATE) = dd_end.date
	JOIN MiniProject.DimCustomer AS dc
		ON rt.customer_id = dc.customer_id
	JOIN MiniProject.DimItem AS di
		ON rtl.item_id = di.item_id
	JOIN MiniProject.DimGeography AS dg
		ON rt.pickup_location_id = dg.rentallocation_id

END;

BEGIN TRAN
EXEC MiniProject.usp_Load_FactSales;
ROLLBACK
COMMIT
GO

EXEC MiniProject.usp_Load_DimDate;
EXEC MiniProject.usp_Load_DimCustomer;
EXEC MiniProject.usp_Load_DimGeography;
EXEC MiniProject.usp_Load_DimItem;
EXEC MiniProject.usp_Load_FactSales;
GO


