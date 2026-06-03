USE RentalDW;
GO

--BEGIN TRAN

-- ETL CONTROL TABLE
IF NOT EXISTS (
    SELECT 1 FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'MiniProject' AND t.name = 'ETL_Control'
)
BEGIN
    CREATE TABLE MiniProject.ETL_Control (
        procedure_name  NVARCHAR(100)   NOT NULL,
        last_run        DATETIME        NOT NULL,

        CONSTRAINT PK_ETL_Control PRIMARY KEY (procedure_name)
    );

    -- Initialize with a date before earliest data
    INSERT INTO MiniProject.ETL_Control (procedure_name, last_run)
    VALUES
        ('usp_Load_DimDate', '2024-02-01'),
        ('usp_Load_DimCustomer', '2024-02-01'),
        ('usp_Load_DimGeography', '2024-02-01'),
        ('usp_Load_DimItem', '2024-02-01'),
        ('usp_Load_FactSales', '2024-02-01');

    PRINT 'ETL_Control table created and initialized.';
END;
GO


-- usp_Load_DimDate
CREATE OR ALTER PROCEDURE MiniProject.usp_Load_DimDate
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @max_key    INT;
    DECLARE @start_date DATE;
    DECLARE @end_date   DATE;

    -- DELETE instead of TRUNCATE — respects FK constraints
    DELETE FROM MiniProject.DimDate;

    SELECT @max_key = ISNULL(MAX(date_key), 0) FROM MiniProject.DimDate;

    SELECT
        @start_date = '2024-02-01',
        @end_date   = '2026-12-31';

    WITH DateRange AS (
        SELECT @start_date AS d
        UNION ALL
        SELECT DATEADD(DAY, 1, d)
        FROM DateRange
        WHERE d < @end_date
    ),
    NewDates AS (
        SELECT
            ROW_NUMBER() OVER (ORDER BY d) AS rn,
            d
        FROM DateRange
        WHERE NOT EXISTS (
            SELECT 1 FROM MiniProject.DimDate dd
            WHERE dd.date = DateRange.d
        )
    )
    INSERT INTO MiniProject.DimDate (
        date_key, date, year, quarter, month, week, day
    )
    SELECT
        @max_key + rn                           AS date_key,
        d                                       AS date,
        YEAR(d)                                 AS year,
        DATEPART(QUARTER, d)                    AS quarter,
        MONTH(d)                                AS month,
        CAST(DATEPART(WEEK, d)  AS TINYINT)     AS week,
        CAST(DAY(d)             AS TINYINT)     AS day
    FROM NewDates
    OPTION (MAXRECURSION 0);

    UPDATE MiniProject.ETL_Control
    SET last_run = GETDATE()
    WHERE procedure_name = 'usp_Load_DimDate';

    PRINT 'DimDate loaded at ' + CONVERT(NVARCHAR, GETDATE(), 120);
END;
GO

-- usp_Load_DimCustomer
CREATE OR ALTER PROCEDURE MiniProject.usp_Load_DimCustomer
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM MiniProject.DimCustomer;

    INSERT INTO MiniProject.DimCustomer (
        customer_key, customer_id, first_name, last_name, address, city, country, email, phone
    )
    SELECT
        ROW_NUMBER() OVER (ORDER BY c.customer_id) AS customer_key, -- Assign new keys sequentially starting from current max
        c.customer_id,
        c.first_name,
        c.last_name,
        c.address,
        c.city,
        c.country,
        c.email,
        c.phone
    FROM RentalOperationsDB.MiniProject.Customer c;

    UPDATE MiniProject.ETL_Control
    SET last_run = GETDATE()
    WHERE procedure_name = 'usp_Load_DimCustomer';

    PRINT 'DimCustomer loaded at ' + CONVERT(NVARCHAR, GETDATE(), 120);
END;
GO

-- usp_Load_DimGeography
CREATE OR ALTER PROCEDURE MiniProject.usp_Load_DimGeography
AS
BEGIN
    SET NOCOUNT ON;

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

    UPDATE MiniProject.ETL_Control
    SET last_run = GETDATE()
    WHERE procedure_name = 'usp_Load_DimGeography';

    PRINT 'DimGeography loaded at ' + CONVERT(NVARCHAR, GETDATE(), 120);
END;
GO

-- usp_Load_DimItem
CREATE OR ALTER PROCEDURE MiniProject.usp_Load_DimItem
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM MiniProject.DimItem;

    INSERT INTO MiniProject.DimItem (
        item_key,
        item_id,
        model_id,
        category_id,
        serial_number,
        status,
        is_usable,
        model_name,
        model_brand,
        category_name,
        hourly_rate,
        maintenance_id,
        maintenance_start,
        maintenance_end,
        maintenance_type,
        maintenance_cost
    )
    SELECT
        ROW_NUMBER() OVER (ORDER BY i.item_id) AS item_key,
        i.item_id,
        i.model_id,
        mo.category_id,
        i.serial_number,
        i.status,
        i.is_usable,
        mo.name AS model_name,
        mo.brand AS model_brand,
        ec.name AS category_name,
        mo.hourly_rate,
        m.maintenance_id,
        m.maintenance_start,
        m.maintenance_end,
        m.type AS maintenance_type,
        m.cost AS maintenance_cost
    FROM RentalOperationsDB.MiniProject.Item i
    JOIN RentalOperationsDB.MiniProject.Model mo
        ON i.model_id = mo.model_id
    JOIN RentalOperationsDB.MiniProject.EquipmentCategory ec
        ON mo.category_id = ec.category_id
    LEFT JOIN (
        SELECT *
        FROM RentalOperationsDB.MiniProject.MaintenanceRecord
        WHERE maintenance_id IN (
            SELECT MAX(maintenance_id)
            FROM RentalOperationsDB.MiniProject.MaintenanceRecord
            GROUP BY item_id
        )
    ) m ON i.item_id = m.item_id;

    UPDATE MiniProject.ETL_Control
    SET last_run = GETDATE()
    WHERE procedure_name = 'usp_Load_DimItem';

    PRINT 'DimItem loaded at ' + CONVERT(NVARCHAR, GETDATE(), 120);
END;
GO

-- usp_Load_FactSales
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
        end_time
    )
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
        CAST(rt.rental_end   AS TIME) AS end_time
        --DATEDIFF(MINUTE, rt.rental_start, rt.rental_end) AS rental_duration_minutes
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
        ON rt.pickup_location_id = dg.rentallocation_id;

    UPDATE MiniProject.ETL_Control
    SET last_run = GETDATE()
    WHERE procedure_name = 'usp_Load_FactSales';

    PRINT 'FactSales loaded at ' + CONVERT(NVARCHAR, GETDATE(), 120);
END;
GO

ALTER TABLE MiniProject.FactSales
    ALTER COLUMN price DECIMAL(18,2) NULL;
GO

-- usp_Run_Full_ETL
CREATE OR ALTER PROCEDURE MiniProject.usp_Run_Full_ETL
AS
BEGIN
    SET NOCOUNT ON;

    PRINT '== ETL Start: ' + CONVERT(NVARCHAR, GETDATE(), 120) + ' ==';

    -- Clear fact first to allow dim deletes
    DELETE FROM MiniProject.FactSales;

    EXEC MiniProject.usp_Load_DimDate;
    EXEC MiniProject.usp_Load_DimCustomer;
    EXEC MiniProject.usp_Load_DimGeography;
    EXEC MiniProject.usp_Load_DimItem;
    EXEC MiniProject.usp_Load_FactSales;

    PRINT '== ETL Complete: ' + CONVERT(NVARCHAR, GETDATE(), 120) + ' ==';
END;
GO

-----------------------------------------------------------
EXEC MiniProject.usp_Run_Full_ETL;
GO

SELECT * FROM MiniProject.ETL_Control;


--ROLLBACK
--COMMIT