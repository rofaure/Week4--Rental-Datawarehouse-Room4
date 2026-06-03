/*
====================================================================
 Data Engineer Mini Project - Validation Queries
====================================================================
 Purpose:
   Run this script after loading the source database and after loading
   the data warehouse. Queries that return rows usually indicate data
   quality issues that should be investigated.

 Databases used:
   - RentalOperationsDB: source/OLTP database
   - RentalDW: dimensional data warehouse

 Notes:
   - Some checks are expected to return zero rows.
   - Row-count checks return summary numbers for reconciliation.
   - This script is written for Microsoft SQL Server / T-SQL.
====================================================================
*/

/*====================================================================
  SECTION 1: SOURCE / OLTP VALIDATION
====================================================================*/

USE RentalOperationsDB;
GO

/*
1. Source row counts
Explanation:
  Confirms that every source table has loaded data and gives a quick
  baseline for comparing source tables against warehouse tables.
Expected result:
  Each table should show the expected number of rows for the dataset.
*/
SELECT 'Customer' AS table_name, COUNT(*) AS row_count FROM MiniProject.Customer
UNION ALL SELECT 'Employee', COUNT(*) FROM MiniProject.Employee
UNION ALL SELECT 'RentalLocation', COUNT(*) FROM MiniProject.RentalLocation
UNION ALL SELECT 'EquipmentCategory', COUNT(*) FROM MiniProject.EquipmentCategory
UNION ALL SELECT 'Model', COUNT(*) FROM MiniProject.Model
UNION ALL SELECT 'Item', COUNT(*) FROM MiniProject.Item
UNION ALL SELECT 'RentalTransaction', COUNT(*) FROM MiniProject.RentalTransaction
UNION ALL SELECT 'RentalTransactionLines', COUNT(*) FROM MiniProject.RentalTransactionLines
UNION ALL SELECT 'MaintenanceRecord', COUNT(*) FROM MiniProject.MaintenanceRecord;
GO

/*
2. Null checks for required source columns
Explanation:
  Validates that important NOT NULL business columns have values.
Expected result:
  This query should return zero rows.
*/
SELECT 'Customer' AS table_name, 'first_name/last_name/email' AS issue, customer_id AS record_id
FROM MiniProject.Customer
WHERE first_name IS NULL OR last_name IS NULL OR email IS NULL
UNION ALL
SELECT 'Employee', 'first_name/last_name/role', employee_id
FROM MiniProject.Employee
WHERE first_name IS NULL OR last_name IS NULL OR role IS NULL
UNION ALL
SELECT 'RentalLocation', 'name/city/country', rentallocation_id
FROM MiniProject.RentalLocation
WHERE name IS NULL OR city IS NULL OR country IS NULL
UNION ALL
SELECT 'Model', 'category_id/brand/name/hourly_rate', model_id
FROM MiniProject.Model
WHERE category_id IS NULL OR brand IS NULL OR name IS NULL OR hourly_rate IS NULL
UNION ALL
SELECT 'Item', 'model_id/status/serial_number/is_usable', item_id
FROM MiniProject.Item
WHERE model_id IS NULL OR status IS NULL OR serial_number IS NULL OR is_usable IS NULL
UNION ALL
SELECT 'RentalTransaction', 'customer_id/pickup_location_id/rental_start', transaction_id
FROM MiniProject.RentalTransaction
WHERE customer_id IS NULL OR pickup_location_id IS NULL OR rental_start IS NULL
UNION ALL
SELECT 'MaintenanceRecord', 'maintenance_start/cost/item_id', maintenance_id
FROM MiniProject.MaintenanceRecord
WHERE maintenance_start IS NULL OR cost IS NULL OR item_id IS NULL;
GO

/*
3. Duplicate customer emails
Explanation:
  Email is defined as a unique customer identifier in the source model.
Expected result:
  This query should return zero rows.
*/
SELECT email, COUNT(*) AS duplicate_count
FROM MiniProject.Customer
GROUP BY email
HAVING COUNT(*) > 1;
GO

/*
4. Duplicate item serial numbers
Explanation:
  Serial number should uniquely identify a physical rental item.
Expected result:
  This query should return zero rows.
*/
SELECT serial_number, COUNT(*) AS duplicate_count
FROM MiniProject.Item
GROUP BY serial_number
HAVING COUNT(*) > 1;
GO

/*
5. Duplicate item in the same rental transaction
Explanation:
  The same item should not appear more than once in one transaction.
Expected result:
  This query should return zero rows.
*/
SELECT transaction_id, item_id, COUNT(*) AS duplicate_count
FROM MiniProject.RentalTransactionLines
GROUP BY transaction_id, item_id
HAVING COUNT(*) > 1;
GO

/*
6. Broken customer references in rental transactions
Explanation:
  Every rental transaction must belong to an existing customer.
Expected result:
  This query should return zero rows.
*/
SELECT rt.*
FROM MiniProject.RentalTransaction AS rt
LEFT JOIN MiniProject.Customer AS c
    ON rt.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
GO

/*
7. Broken pickup location references in rental transactions
Explanation:
  Every rental transaction must have a valid pickup location.
Expected result:
  This query should return zero rows.
*/
SELECT rt.*
FROM MiniProject.RentalTransaction AS rt
LEFT JOIN MiniProject.RentalLocation AS rl
    ON rt.pickup_location_id = rl.rentallocation_id
WHERE rl.rentallocation_id IS NULL;
GO

/*
8. Broken return location references in completed rental transactions
Explanation:
  If a return location is populated, it must exist in RentalLocation.
Expected result:
  This query should return zero rows.
*/
SELECT rt.*
FROM MiniProject.RentalTransaction AS rt
LEFT JOIN MiniProject.RentalLocation AS rl
    ON rt.return_location_id = rl.rentallocation_id
WHERE rt.return_location_id IS NOT NULL
  AND rl.rentallocation_id IS NULL;
GO

/*
9. Broken rental line transaction references
Explanation:
  Every rental line must belong to an existing rental transaction.
Expected result:
  This query should return zero rows.
*/
SELECT rtl.*
FROM MiniProject.RentalTransactionLines AS rtl
LEFT JOIN MiniProject.RentalTransaction AS rt
    ON rtl.transaction_id = rt.transaction_id
WHERE rt.transaction_id IS NULL;
GO

/*
10. Broken rental line item references
Explanation:
  Every rental line must reference an existing item.
Expected result:
  This query should return zero rows.
*/
SELECT rtl.*
FROM MiniProject.RentalTransactionLines AS rtl
LEFT JOIN MiniProject.Item AS i
    ON rtl.item_id = i.item_id
WHERE i.item_id IS NULL;
GO

/*
11. Broken item model references
Explanation:
  Every item must reference an existing model.
Expected result:
  This query should return zero rows.
*/
SELECT i.*
FROM MiniProject.Item AS i
LEFT JOIN MiniProject.Model AS m
    ON i.model_id = m.model_id
WHERE m.model_id IS NULL;
GO

/*
12. Broken model category references
Explanation:
  Every equipment model must belong to an existing equipment category.
Expected result:
  This query should return zero rows.
*/
SELECT m.*
FROM MiniProject.Model AS m
LEFT JOIN MiniProject.EquipmentCategory AS ec
    ON m.category_id = ec.category_id
WHERE ec.category_id IS NULL;
GO

/*
13. Broken maintenance item references
Explanation:
  Every maintenance record must reference an existing item.
Expected result:
  This query should return zero rows.
*/
SELECT mr.*
FROM MiniProject.MaintenanceRecord AS mr
LEFT JOIN MiniProject.Item AS i
    ON mr.item_id = i.item_id
WHERE i.item_id IS NULL;
GO

/*
14. Invalid rental dates
Explanation:
  Completed rentals must end after they start.
Expected result:
  This query should return zero rows.
*/
SELECT *
FROM MiniProject.RentalTransaction
WHERE rental_end IS NOT NULL
  AND rental_end <= rental_start;
GO

/*
15. Invalid maintenance dates
Explanation:
  Completed maintenance must end after it starts.
Expected result:
  This query should return zero rows.
*/
SELECT *
FROM MiniProject.MaintenanceRecord
WHERE maintenance_end IS NOT NULL
  AND maintenance_end <= maintenance_start;
GO

/*
16. Invalid source amounts and rates
Explanation:
  Prices, costs, and rates should not be negative or zero where business
  rules require positive values.
Expected result:
  This query should return zero rows.
*/
SELECT 'RentalTransactionLines' AS table_name, transaction_id AS record_id, line_amount AS amount_value, 'line_amount <= 0' AS issue
FROM MiniProject.RentalTransactionLines
WHERE line_amount IS NOT NULL AND line_amount <= 0
UNION ALL
SELECT 'Model', model_id, hourly_rate, 'hourly_rate <= 0'
FROM MiniProject.Model
WHERE hourly_rate <= 0
UNION ALL
SELECT 'MaintenanceRecord', maintenance_id, cost, 'cost < 0'
FROM MiniProject.MaintenanceRecord
WHERE cost < 0
UNION ALL
SELECT 'RentalTransaction', transaction_id, total_amount, 'total_amount < 0'
FROM MiniProject.RentalTransaction
WHERE total_amount IS NOT NULL AND total_amount < 0;
GO

/*
17. Invalid item status values
Explanation:
  Item status must match the allowed source-system values.
Expected result:
  This query should return zero rows.
*/
SELECT *
FROM MiniProject.Item
WHERE status NOT IN ('available', 'rented', 'maintenance', 'retired');
GO

/*
18. Invalid maintenance type values
Explanation:
  Maintenance type must match the allowed source-system values.
Expected result:
  This query should return zero rows.
*/
SELECT *
FROM MiniProject.MaintenanceRecord
WHERE type NOT IN ('Inspection', 'Repair', 'Battery Replacement', 'Other')
   OR type IS NULL;
GO

/*
19. Open rentals with return details
Explanation:
  If a rental is still open, it should not have return location or final
  total amount populated.
Expected result:
  This query should return zero rows, unless the business rules allow
  estimated totals for open rentals.
*/
SELECT *
FROM MiniProject.RentalTransaction
WHERE rental_end IS NULL
  AND (return_location_id IS NOT NULL OR total_amount IS NOT NULL);
GO

/*
20. Completed rentals missing return details
Explanation:
  If a rental has ended, it should have return location and total amount.
Expected result:
  This query should return zero rows.
*/
SELECT *
FROM MiniProject.RentalTransaction
WHERE rental_end IS NOT NULL
  AND (return_location_id IS NULL OR total_amount IS NULL);
GO

/*
21. Rental total does not equal sum of line amounts
Explanation:
  The transaction total should equal the sum of its rental line amounts.
Expected result:
  This query should return zero rows.
*/
SELECT
    rt.transaction_id,
    rt.total_amount,
    SUM(rtl.line_amount) AS calculated_line_total,
    rt.total_amount - SUM(rtl.line_amount) AS difference
FROM MiniProject.RentalTransaction AS rt
JOIN MiniProject.RentalTransactionLines AS rtl
    ON rt.transaction_id = rtl.transaction_id
WHERE rt.total_amount IS NOT NULL
GROUP BY rt.transaction_id, rt.total_amount
HAVING ABS(rt.total_amount - SUM(rtl.line_amount)) > 0.01;
GO

/*
22. Rental transactions without rental lines
Explanation:
  A rental transaction should have at least one item line.
Expected result:
  This query should return zero rows.
*/
SELECT rt.*
FROM MiniProject.RentalTransaction AS rt
LEFT JOIN MiniProject.RentalTransactionLines AS rtl
    ON rt.transaction_id = rtl.transaction_id
WHERE rtl.transaction_id IS NULL;
GO

/*
23. Overlapping rentals for the same item
Explanation:
  The same physical item should not be rented to two transactions at the
  same time.
Expected result:
  This query should return zero rows.
*/
WITH rentals AS (
    SELECT
        rtl.item_id,
        rt.transaction_id,
        rt.rental_start,
        rt.rental_end
    FROM MiniProject.RentalTransaction AS rt
    JOIN MiniProject.RentalTransactionLines AS rtl
        ON rt.transaction_id = rtl.transaction_id
    WHERE rt.rental_end IS NOT NULL
)
SELECT
    r1.item_id,
    r1.transaction_id AS transaction_id_1,
    r1.rental_start AS rental_start_1,
    r1.rental_end AS rental_end_1,
    r2.transaction_id AS transaction_id_2,
    r2.rental_start AS rental_start_2,
    r2.rental_end AS rental_end_2
FROM rentals AS r1
JOIN rentals AS r2
    ON r1.item_id = r2.item_id
   AND r1.transaction_id < r2.transaction_id
   AND r1.rental_start < r2.rental_end
   AND r2.rental_start < r1.rental_end;
GO

/*
24. Rentals that overlap maintenance for the same item
Explanation:
  An item should not be rented during a maintenance period.
Expected result:
  This query should return zero rows.
*/
SELECT
    rtl.item_id,
    rt.transaction_id,
    rt.rental_start,
    rt.rental_end,
    mr.maintenance_id,
    mr.maintenance_start,
    mr.maintenance_end
FROM MiniProject.RentalTransaction AS rt
JOIN MiniProject.RentalTransactionLines AS rtl
    ON rt.transaction_id = rtl.transaction_id
JOIN MiniProject.MaintenanceRecord AS mr
    ON rtl.item_id = mr.item_id
WHERE rt.rental_end IS NOT NULL
  AND CAST(rt.rental_start AS date) <= ISNULL(mr.maintenance_end, '9999-12-31')
  AND CAST(rt.rental_end AS date) >= mr.maintenance_start;
GO

/*====================================================================
  SECTION 2: DATA WAREHOUSE VALIDATION
====================================================================*/

USE RentalDW;
GO

/*
25. Warehouse row counts
Explanation:
  Confirms that all dimension and fact tables loaded successfully.
Expected result:
  Counts should match expected ETL output volumes.
*/
SELECT 'DimCustomer' AS table_name, COUNT(*) AS row_count FROM MiniProject.DimCustomer
UNION ALL SELECT 'DimDate', COUNT(*) FROM MiniProject.DimDate
UNION ALL SELECT 'DimGeography', COUNT(*) FROM MiniProject.DimGeography
UNION ALL SELECT 'DimItem', COUNT(*) FROM MiniProject.DimItem
UNION ALL SELECT 'FactSales', COUNT(*) FROM MiniProject.FactSales;
GO

/*
26. Source-to-warehouse row-count reconciliation
Explanation:
  FactSales should normally have one row per source rental transaction line.
Expected result:
  source_rental_line_count should equal warehouse_fact_count.
*/
SELECT
    src.source_rental_line_count,
    dw.warehouse_fact_count,
    src.source_rental_line_count - dw.warehouse_fact_count AS difference
FROM (
    SELECT COUNT(*) AS source_rental_line_count
    FROM RentalOperationsDB.MiniProject.RentalTransactionLines
) AS src
CROSS JOIN (
    SELECT COUNT(*) AS warehouse_fact_count
    FROM RentalDW.MiniProject.FactSales
) AS dw;
GO

/*
27. Missing source rental lines in FactSales
Explanation:
  Finds source rental lines that did not load into the warehouse fact table.
Expected result:
  This query should return zero rows.
*/
SELECT
    rtl.transaction_id,
    rtl.transactionline_id,
    rtl.item_id,
    rtl.line_amount
FROM RentalOperationsDB.MiniProject.RentalTransactionLines AS rtl
LEFT JOIN RentalDW.MiniProject.FactSales AS f
    ON rtl.transaction_id = f.transaction_id
   AND rtl.transactionline_id = f.transactionline_id
WHERE f.transaction_id IS NULL;
GO

/*
28. FactSales rows without matching source rental lines
Explanation:
  Finds fact rows that do not exist in the source rental transaction lines.
Expected result:
  This query should return zero rows.
*/
SELECT
    f.transaction_id,
    f.transactionline_id
FROM RentalDW.MiniProject.FactSales AS f
LEFT JOIN RentalOperationsDB.MiniProject.RentalTransactionLines AS rtl
    ON f.transaction_id = rtl.transaction_id
   AND f.transactionline_id = rtl.transactionline_id
WHERE rtl.transaction_id IS NULL;
GO

/*
29. FactSales orphan customer keys
Explanation:
  Every fact row must reference an existing customer dimension row.
Expected result:
  This query should return zero rows.
*/
SELECT f.*
FROM MiniProject.FactSales AS f
LEFT JOIN MiniProject.DimCustomer AS c
    ON f.customer_key = c.customer_key
WHERE c.customer_key IS NULL;
GO

/*
30. FactSales orphan item keys
Explanation:
  Every fact row must reference an existing item dimension row.
Expected result:
  This query should return zero rows.
*/
SELECT f.*
FROM MiniProject.FactSales AS f
LEFT JOIN MiniProject.DimItem AS i
    ON f.item_key = i.item_key
WHERE i.item_key IS NULL;
GO

/*
31. FactSales orphan start date keys
Explanation:
  Every fact row must have a valid start date in DimDate.
Expected result:
  This query should return zero rows.
*/
SELECT f.*
FROM MiniProject.FactSales AS f
LEFT JOIN MiniProject.DimDate AS d
    ON f.startdate_key = d.date_key
WHERE d.date_key IS NULL;
GO

/*
32. FactSales orphan end date keys
Explanation:
  If enddate_key is populated, it must exist in DimDate.
Expected result:
  This query should return zero rows.
*/
SELECT f.*
FROM MiniProject.FactSales AS f
LEFT JOIN MiniProject.DimDate AS d
    ON f.enddate_key = d.date_key
WHERE f.enddate_key IS NOT NULL
  AND d.date_key IS NULL;
GO

/*
33. FactSales orphan geography keys
Explanation:
  Every fact row must reference an existing geography dimension row.
Expected result:
  This query should return zero rows.
*/
SELECT f.*
FROM MiniProject.FactSales AS f
LEFT JOIN MiniProject.DimGeography AS g
    ON f.geography_key = g.geography_key
WHERE g.geography_key IS NULL;
GO

/*
34. Duplicate dimension business keys
Explanation:
  In this basic dimensional model, each source business key should appear
  once in each dimension unless SCD Type 2 logic is intentionally added.
Expected result:
  These queries should return zero rows.
*/
SELECT 'DimCustomer' AS dimension_name, customer_id AS business_key, COUNT(*) AS duplicate_count
FROM MiniProject.DimCustomer
GROUP BY customer_id
HAVING COUNT(*) > 1
UNION ALL
SELECT 'DimGeography', rentallocation_id, COUNT(*)
FROM MiniProject.DimGeography
GROUP BY rentallocation_id
HAVING COUNT(*) > 1
UNION ALL
SELECT 'DimItem', item_id, COUNT(*)
FROM MiniProject.DimItem
GROUP BY item_id
HAVING COUNT(*) > 1;
GO

/*
35. Duplicate dates in DimDate
Explanation:
  Each calendar date should appear once in DimDate.
Expected result:
  This query should return zero rows.
*/
SELECT [date], COUNT(*) AS duplicate_count
FROM MiniProject.DimDate
GROUP BY [date]
HAVING COUNT(*) > 1;
GO

/*
36. Invalid date key format in DimDate
Explanation:
  date_key should match YYYYMMDD representation of the date.
Expected result:
  This query should return zero rows.
*/
SELECT *
FROM MiniProject.DimDate
WHERE date_key <> CONVERT(int, CONVERT(char(8), [date], 112));
GO

/*
37. FactSales date/time consistency
Explanation:
  End date/time should not be before start date/time for completed rentals.
Expected result:
  This query should return zero rows.
*/
SELECT
    f.*,
    sd.[date] AS start_date,
    ed.[date] AS end_date
FROM MiniProject.FactSales AS f
JOIN MiniProject.DimDate AS sd
    ON f.startdate_key = sd.date_key
LEFT JOIN MiniProject.DimDate AS ed
    ON f.enddate_key = ed.date_key
WHERE f.enddate_key IS NOT NULL
  AND (
        ed.[date] < sd.[date]
        OR (ed.[date] = sd.[date] AND f.end_time <= f.start_time)
      );
GO

/*
38. FactSales amount reconciliation against source
Explanation:
  Fact price should match the source rental line amount, and fact total
  amount should match the source transaction total.
Expected result:
  This query should return zero rows.
*/
SELECT
    f.transaction_id,
    f.transactionline_id,
    f.price AS fact_price,
    rtl.line_amount AS source_line_amount,
    f.total_amount AS fact_total_amount,
    rt.total_amount AS source_total_amount
FROM RentalDW.MiniProject.FactSales AS f
JOIN RentalOperationsDB.MiniProject.RentalTransactionLines AS rtl
    ON f.transaction_id = rtl.transaction_id
   AND f.transactionline_id = rtl.transactionline_id
JOIN RentalOperationsDB.MiniProject.RentalTransaction AS rt
    ON rtl.transaction_id = rt.transaction_id
WHERE ISNULL(f.price, -1) <> ISNULL(rtl.line_amount, -1)
   OR ISNULL(f.total_amount, -1) <> ISNULL(rt.total_amount, -1);
GO

/*
39. DimCustomer reconciliation against source Customer
Explanation:
  Validates that customer dimension descriptive attributes match the source.
Expected result:
  This query should return zero rows.
*/
SELECT
    dc.customer_id,
    dc.first_name AS dw_first_name,
    c.first_name AS source_first_name,
    dc.last_name AS dw_last_name,
    c.last_name AS source_last_name,
    dc.email AS dw_email,
    c.email AS source_email
FROM RentalDW.MiniProject.DimCustomer AS dc
JOIN RentalOperationsDB.MiniProject.Customer AS c
    ON dc.customer_id = c.customer_id
WHERE dc.first_name <> c.first_name
   OR dc.last_name <> c.last_name
   OR dc.address <> c.address
   OR dc.city <> c.city
   OR dc.country <> c.country
   OR dc.email <> c.email
   OR dc.phone <> c.phone;
GO

/*
40. DimItem reconciliation against source Item, Model, Category, and Maintenance
Explanation:
  Validates that item dimension attributes match source item/model/category
  details. Maintenance fields may produce multiple rows if the ETL models
  one item with multiple maintenance records.
Expected result:
  This query should return zero rows if DimItem is designed as one row per
  item and current/related maintenance record.
*/
SELECT
    di.item_id,
    di.model_id AS dw_model_id,
    i.model_id AS source_model_id,
    di.category_id AS dw_category_id,
    m.category_id AS source_category_id,
    di.category_name AS dw_category_name,
    ec.name AS source_category_name,
    di.model_brand AS dw_model_brand,
    m.brand AS source_model_brand,
    di.model_name AS dw_model_name,
    m.name AS source_model_name,
    di.status AS dw_status,
    i.status AS source_status,
    di.serial_number AS dw_serial_number,
    i.serial_number AS source_serial_number,
    di.hourly_rate AS dw_hourly_rate,
    m.hourly_rate AS source_hourly_rate,
    di.is_usable AS dw_is_usable,
    i.is_usable AS source_is_usable
FROM RentalDW.MiniProject.DimItem AS di
JOIN RentalOperationsDB.MiniProject.Item AS i
    ON di.item_id = i.item_id
JOIN RentalOperationsDB.MiniProject.Model AS m
    ON i.model_id = m.model_id
JOIN RentalOperationsDB.MiniProject.EquipmentCategory AS ec
    ON m.category_id = ec.category_id
WHERE di.model_id <> i.model_id
   OR di.category_id <> m.category_id
   OR di.category_name <> ec.name
   OR di.model_brand <> m.brand
   OR di.model_name <> m.name
   OR di.status <> i.status
   OR di.serial_number <> i.serial_number
   OR di.hourly_rate <> m.hourly_rate
   OR di.is_usable <> i.is_usable;
GO

/*
41. DimGeography reconciliation against source RentalLocation
Explanation:
  Validates that geography/location dimension attributes match the source.
Expected result:
  This query should return zero rows.
*/
SELECT
    dg.rentallocation_id,
    dg.name AS dw_name,
    rl.name AS source_name,
    dg.city AS dw_city,
    rl.city AS source_city,
    dg.country AS dw_country,
    rl.country AS source_country
FROM RentalDW.MiniProject.DimGeography AS dg
JOIN RentalOperationsDB.MiniProject.RentalLocation AS rl
    ON dg.rentallocation_id = rl.rentallocation_id
WHERE dg.name <> rl.name
   OR dg.address <> rl.address
   OR dg.city <> rl.city
   OR dg.country <> rl.country
   OR dg.is_manned <> rl.is_manned;
GO

/*
42. Final validation summary
Explanation:
  Provides a compact pass/fail-style summary for the most important checks.
Expected result:
  issue_count should be 0 for all rows except row-count comparison, where
  the difference should be 0.
*/
SELECT 'Duplicate customer emails' AS validation_check, COUNT(*) AS issue_count
FROM (
    SELECT email
    FROM RentalOperationsDB.MiniProject.Customer
    GROUP BY email
    HAVING COUNT(*) > 1
) AS x
UNION ALL
SELECT 'Duplicate item serial numbers', COUNT(*)
FROM (
    SELECT serial_number
    FROM RentalOperationsDB.MiniProject.Item
    GROUP BY serial_number
    HAVING COUNT(*) > 1
) AS x
UNION ALL
SELECT 'Invalid rental dates', COUNT(*)
FROM RentalOperationsDB.MiniProject.RentalTransaction
WHERE rental_end IS NOT NULL AND rental_end <= rental_start
UNION ALL
SELECT 'Invalid maintenance dates', COUNT(*)
FROM RentalOperationsDB.MiniProject.MaintenanceRecord
WHERE maintenance_end IS NOT NULL AND maintenance_end <= maintenance_start
UNION ALL
SELECT 'Missing source lines in FactSales', COUNT(*)
FROM RentalOperationsDB.MiniProject.RentalTransactionLines AS rtl
LEFT JOIN RentalDW.MiniProject.FactSales AS f
    ON rtl.transaction_id = f.transaction_id
   AND rtl.transactionline_id = f.transactionline_id
WHERE f.transaction_id IS NULL
UNION ALL
SELECT 'FactSales rows without source lines', COUNT(*)
FROM RentalDW.MiniProject.FactSales AS f
LEFT JOIN RentalOperationsDB.MiniProject.RentalTransactionLines AS rtl
    ON f.transaction_id = rtl.transaction_id
   AND f.transactionline_id = rtl.transactionline_id
WHERE rtl.transaction_id IS NULL;
GO
