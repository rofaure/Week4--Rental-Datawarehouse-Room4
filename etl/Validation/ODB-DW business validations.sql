USE RentalDW;
GO

-- ============================================================
-- Pass/Fail Validation Summary
-- ============================================================

SELECT 'Duplicate customer keys' AS test_name,
       CASE WHEN EXISTS (
           SELECT customer_key
           FROM MiniProject.DimCustomer
           GROUP BY customer_key
           HAVING COUNT(*) > 1
       )
       THEN 'FAIL' ELSE 'PASS' END AS result

UNION ALL

SELECT 'Duplicate customer business keys',
       CASE WHEN EXISTS (
           SELECT customer_id
           FROM MiniProject.DimCustomer
           GROUP BY customer_id
           HAVING COUNT(*) > 1
       )
       THEN 'FAIL' ELSE 'PASS' END

UNION ALL

SELECT 'Fact rows missing customers',
       CASE WHEN EXISTS (
           SELECT 1
           FROM MiniProject.FactSales f
           LEFT JOIN MiniProject.DimCustomer c
               ON f.customer_key = c.customer_key
           WHERE c.customer_key IS NULL
       )
       THEN 'FAIL' ELSE 'PASS' END

UNION ALL

SELECT 'Invalid fact dates',
       CASE WHEN EXISTS (
           SELECT 1
           FROM MiniProject.FactSales
           WHERE enddate_key IS NOT NULL
             AND enddate_key < startdate_key
       )
       THEN 'FAIL' ELSE 'PASS' END

UNION ALL

SELECT 'Negative sales amounts',
       CASE WHEN EXISTS (
           SELECT 1
           FROM MiniProject.FactSales
           WHERE price < 0
              OR total_amount < 0
       )
       THEN 'FAIL' ELSE 'PASS' END

UNION ALL

SELECT 'Duplicate fact rows',
       CASE WHEN EXISTS (
           SELECT transaction_id, transactionline_id
           FROM MiniProject.FactSales
           GROUP BY transaction_id, transactionline_id
           HAVING COUNT(*) > 1
       )
       THEN 'FAIL' ELSE 'PASS' END;


-- ============================================================
-- Data Summary
-- ============================================================

-- Table row count 
SELECT 'DimCustomer' AS table_name, COUNT(*) AS row_count FROM MiniProject.DimCustomer
UNION ALL
SELECT 'DimDate', COUNT(*) FROM MiniProject.DimDate
UNION ALL
SELECT 'DimGeography', COUNT(*) FROM MiniProject.DimGeography
UNION ALL
SELECT 'DimItem', COUNT(*) FROM MiniProject.DimItem
UNION ALL
SELECT 'FactSales', COUNT(*) FROM MiniProject.FactSales;

-- Sales totals
SELECT
    COUNT(*) AS fact_rows,
    COUNT(DISTINCT transaction_id) AS total_transactions,
    COUNT(transactionline_id) AS total_transaction_lines,
    SUM(price) AS total_line_price,
    SUM(total_amount) AS total_sales_amount,
    AVG(price) AS avg_line_price,
    AVG(total_amount) AS avg_transaction_amount,
    MIN(total_amount) AS min_transaction_amount,
    MAX(total_amount) AS max_transaction_amount
FROM MiniProject.FactSales;

-- Sales by customer
SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT f.transaction_id) AS total_transactions,
    COUNT(*) AS total_lines,
    SUM(f.price) AS total_spent
FROM MiniProject.FactSales f
JOIN MiniProject.DimCustomer c
    ON f.customer_key = c.customer_key
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY total_spent DESC;

-- Sales by geography
SELECT
    g.country,
    g.city,
    g.name AS rental_location,
    COUNT(DISTINCT f.transaction_id) AS total_transactions,
    COUNT(*) AS total_lines,
    SUM(f.price) AS total_sales
FROM MiniProject.FactSales f
JOIN MiniProject.DimGeography g
    ON f.geography_key = g.geography_key
GROUP BY
    g.country,
    g.city,
    g.name
ORDER BY total_sales DESC;

-- Sales by item category and model
SELECT
    i.model_brand,
    i.model_name,
    i.category_name,
    COUNT(*) AS rental_lines,
    SUM(f.price) AS total_sales,
    AVG(f.price) AS avg_rental_price
FROM MiniProject.FactSales f
JOIN MiniProject.DimItem i
    ON f.item_key = i.item_key
GROUP BY
    i.model_brand,
    i.model_name,
    i.category_name
ORDER BY total_sales DESC;

-- Sales by month
SELECT
    d.year,
    d.month,
    COUNT(DISTINCT f.transaction_id) AS total_transactions,
    COUNT(*) AS total_lines,
    SUM(f.price) AS total_sales
FROM MiniProject.FactSales f
JOIN MiniProject.DimDate d
    ON f.startdate_key = d.date_key
GROUP BY
    d.year,
    d.month
ORDER BY
    d.year,
    d.month;

---- Rental duration summary
--SELECT
--    f.transaction_id,
--    f.transactionline_id,
--    AVG(DATEDIFF(HOUR, f.start_time, f.end_time)) AS avg_rental_hours,
--    MIN(DATEDIFF(HOUR, f.start_time, f.end_time)) AS min_rental_hours,
--    MAX(DATEDIFF(HOUR, f.start_time, f.end_time)) AS max_rental_hours
--FROM MiniProject.FactSales f
--GROUP BY f.transaction_id,f.transactionline_id
--ORDER BY min_rental_hours asc

--SELECT * FROM MiniProject.FactSales
--WHERE transaction_id = 41794

-- Item usability summary
SELECT
    is_usable,
    COUNT(*) AS item_count
FROM MiniProject.DimItem
GROUP BY is_usable;

-- Maintenance cost summary
SELECT
    category_name,
    model_brand,
    model_name,
    COUNT(*) AS item_count,
    SUM(maintenance_cost) AS total_maintenance_cost,
    AVG(maintenance_cost) AS avg_maintenance_cost,
    MIN(maintenance_cost) AS min_maintenance_cost,
    MAX(maintenance_cost) AS max_maintenance_cost
FROM MiniProject.DimItem
WHERE maintenance_cost IS NOT NULL
GROUP BY
    category_name,
    model_brand,
    model_name
ORDER BY total_maintenance_cost DESC;

-- Top 10 customers
SELECT TOP 10
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(DISTINCT f.transaction_id) AS total_transactions,
    SUM(f.price) AS total_spent
FROM MiniProject.FactSales f
JOIN MiniProject.DimCustomer c
    ON f.customer_key = c.customer_key
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY total_spent DESC;