-- Load procedure and execution for DimDate

USE RentalDW;
GO

CREATE OR ALTER PROCEDURE MiniProject.LoadDimDate
AS
BEGIN
    SET NOCOUNT ON;

    -- Generate the dates between @StartDate and @EndDate with a numbers/tally table approach
    DECLARE @StartDate date = '2024-02-01';
    DECLARE @EndDate   date = '2026-06-30';

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

EXEC RentalDW.MiniProject.LoadDimDate;
GO

--SELECT * FROM RentalDW.MiniProject.DimDate;


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
