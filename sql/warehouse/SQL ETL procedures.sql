USE RentalDW;
GO

BEGIN TRAN

--DimGeography loading procedure
CREATE OR ALTER PROCEDURE MiniProject.usp_Load_DimGeography
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

EXEC RentalDW.MiniProject.usp_Load_DimGeography;
GO
SELECT * FROM MiniProject.DimGeography;

-- Load DimItems
CREATE OR ALTER PROCEDURE MiniProject.usp_Load_DimItem
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO MiniProject.DimItem
    (
        item_key,
        item_id,
        model_id,
        category_id,
        maintenance_id,
        category_name,
        model_brand,
        model_name,
        status,
        serial_number,
        hourly_rate,
        is_usable,
        maintenance_start,
        maintenance_end,
        maintenance_type,
        maintenance_cost
    )
    SELECT
        ROW_NUMBER() OVER (ORDER BY item.item_id) AS item_key,
        item.item_id,
        item.model_id,
        model.category_id,
        mr.maintenance_id,
        eq.name AS category_name,
        model.brand AS model_brand,
        model.name AS model_name,
        item.status,
        item.serial_number,
        model.hourly_rate,
        item.is_usable,
        mr.maintenance_start,
        mr.maintenance_end,
        mr.type AS maintenance_type,
        mr.cost AS maintenance_cost
    FROM RentalOperationsDB.MiniProject.Item AS item
    JOIN RentalOperationsDB.MiniProject.Model AS model
        ON model.model_id = item.model_id
    JOIN RentalOperationsDB.MiniProject.EquipmentCategory AS eq
        ON eq.category_id = model.category_id
    LEFT JOIN RentalOperationsDB.MiniProject.MaintenanceRecord AS mr
        ON item.item_id = mr.item_id;
END;
GO

EXEC RentalDW.MiniProject.usp_Load_DimItem;
GO
SELECT * FROM MiniProject.DimItem;

--Load DimCustomer
CREATE OR ALTER PROCEDURE MiniProject.usp_Load_DimCustomer
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

EXEC RentalDW.MiniProject.usp_Load_DimCustomer;
GO
SELECT * FROM MiniProject.DimCustomer;

--Load DimDate
CREATE OR ALTER PROCEDURE MiniProject.usp_Load_DimDate
    @StartDate date,
    @EndDate date
AS
BEGIN
    SET NOCOUNT ON;

    -- Generate the dates between @StartDate and @EndDate with a numbers/tally table approach
    WITH Numbers AS
    (
        -- Generate a sequence of numbers, e.g. 0..880, which can then be added to the start date
        SELECT TOP (DATEDIFF(day, @StartDate, @EndDate) + 1) -- calculate the range, include both dates
               -- ROW_NUMBER: every row gets a unique sequential number
               ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n -- SELECT NULL: Any order is fine, just assign row numbers
        -- We're not interested in the actual contents. We only need a source that has "many rows".
        FROM sys.all_objects -- a system view that contains metadata about objects in the database
    )
    INSERT INTO MiniProject.DimDate
    (
        date_key,
        [date],
        [year],
        quarter,
        [month],
        week,
        [day]
    )
    SELECT
        CAST(CONVERT(char(8), DATEADD(day, n, @StartDate), 112) AS int) AS date_key,
        DATEADD(day, n, @StartDate) AS [date],
        YEAR(DATEADD(day, n, @StartDate)) AS [year],
        DATEPART(QUARTER, DATEADD(day, n, @StartDate)) AS quarter,
        MONTH(DATEADD(day, n, @StartDate)) AS [month],
        DATEPART(ISO_WEEK, DATEADD(day, n, @StartDate)) AS week,
        DAY(DATEADD(day, n, @StartDate)) AS [day]
    FROM Numbers;
END;
GO

-- Define the start date and end date of DimDate here
EXEC RentalDW.MiniProject.usp_Load_DimDate
    @StartDate = '2024-02-01',
    @EndDate   = '2026-06-30';
GO

SELECT * FROM RentalDW.MiniProject.DimDate;


/*
Visual summary:

sys.all_objects
      │
      ▼
ROW_NUMBER()
      │
      ▼
1,2,3,4,...
      │
      ▼
-1
      │
      ▼
0,1,2,3,...
      │
      ▼
DATEADD(day, n, @StartDate)
      │
      ▼
2024-02-01
2024-02-02
2024-02-03
...
2026-06-30

*/

-- FactSales loading procedure
CREATE OR ALTER PROCEDURE MiniProject.usp_Load_FactSales
AS 
BEGIN
	SET NOCOUNT ON;

	DELETE FROM MiniProject.FactSales;

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


EXEC MiniProject.usp_Load_FactSales;
SELECT * FROM MiniProject.FactSales;
ROLLBACK
COMMIT
GO
