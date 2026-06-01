-- ============================================================
--Data integrity checks
-- ============================================================

--Row counts
SELECT 'Employee' AS Row_count_check, COUNT(*) AS row_count 
FROM MiniProject.Employee
UNION ALL
SELECT 'RentalLocation', COUNT(*) FROM MiniProject.RentalLocation
UNION ALL
SELECT 'Customer', COUNT(*) FROM MiniProject.Customer
UNION ALL
SELECT 'EquipmentCategory', COUNT(*) FROM MiniProject.EquipmentCategory
UNION ALL
SELECT 'Model', COUNT(*) FROM MiniProject.Model
UNION ALL
SELECT 'Item', COUNT(*) FROM MiniProject.Item
UNION ALL
SELECT 'RentalTransaction', COUNT(*) FROM MiniProject.RentalTransaction
UNION ALL
SELECT 'RentalTransactionLines', COUNT(*) FROM MiniProject.RentalTransactionLines
UNION ALL
SELECT 'MaintenanceRecord', COUNT(*) FROM MiniProject.MaintenanceRecord;

--Transaction with no lines
SELECT t.transaction_id, t.rental_start, t.total_amount
FROM MiniProject.RentalTransaction t
LEFT JOIN MiniProject.RentalTransactionLines l ON t.transaction_id = l.transaction_id
WHERE l.transactionline_id IS NULL;

--total_amount vs sum of line_amount
SELECT 
	t.transaction_id,
	t.total_amount AS total_transaction_amount,
	SUM(l.line_amount) AS total_line_amount
FROM MiniProject.RentalTransaction t
JOIN MiniProject.RentalTransactionLines l
	ON t.transaction_id = l.transaction_id
WHERE t.total_amount IS NOT NULL
GROUP BY t.transaction_id, t.total_amount

--items rented but not in an active transaction line
SELECT i.item_id, i.serial_number, i.status
FROM MiniProject.Item i
LEFT JOIN MiniProject.RentalTransactionLines l ON i.item_id = l.item_id
WHERE i.status = 'rented'
AND l.transactionline_id IS NULL;

--items in maintenance but marked as available or rented
SELECT i.item_id, i.serial_number, i.status, m.maintenance_start
FROM MiniProject.Item i
JOIN MiniProject.MaintenanceRecord m ON i.item_id = m.item_id
WHERE m.maintenance_end IS NULL
AND i.status <> 'maintenance';

-- ============================================================
--Business reports
-- ============================================================
SELECT 
	rl.country,
	SUM(tl.line_amount) AS total_revenue
FROM MiniProject.RentalTransaction t
JOIN MiniProject.RentalLocation rl ON t.pickup_location_id = rl.rentallocation_id
JOIN MiniProject.RentalTransactionLines tl	ON t.transaction_id = tl.transaction_id
GROUP BY rl.country
ORDER BY total_revenue DESC;

--Revenue by equipment category
SELECT 
    ec.name AS category,
    COUNT(l.transactionline_id) AS items_rented,
    SUM(l.line_amount) AS total_revenue,
    AVG(l.line_amount) AS avg_line_amount
FROM MiniProject.RentalTransactionLines l
JOIN MiniProject.Item i 
	ON l.item_id = i.item_id
JOIN MiniProject.Model mo
	ON i.model_id = mo.model_id
JOIN MiniProject.EquipmentCategory ec ON mo.category_id = ec.category_id
WHERE l.line_amount IS NOT NULL
GROUP BY ec.name
ORDER BY total_revenue DESC;

--Store vs station rental split
SELECT 
    CASE WHEN rl.is_manned = 1 THEN 'Store' ELSE 'Station' END AS channel,
    COUNT(DISTINCT t.transaction_id) AS transactions,
    SUM(l.line_amount) AS total_revenue
FROM MiniProject.RentalTransaction t
JOIN MiniProject.RentalTransactionLines l
	ON t.transaction_id = l.transaction_id
JOIN MiniProject.RentalLocation rl
	ON t.pickup_location_id = rl.rentallocation_id
WHERE l.line_amount IS NOT NULL
GROUP BY rl.is_manned;

--Average rental duration by category
SELECT 
    ec.name AS category,
    AVG(DATEDIFF(MINUTE, t.rental_start, t.rental_end)) AS avg_duration_minutes,
    AVG(DATEDIFF(MINUTE, t.rental_start, t.rental_end)) / 60.0 AS avg_duration_hours
FROM MiniProject.RentalTransaction t
JOIN MiniProject.RentalTransactionLines l
	ON t.transaction_id = l.transaction_id
JOIN MiniProject.Item i 
	ON l.item_id = i.item_id
JOIN MiniProject.Model mo 
	ON i.model_id = mo.model_id
JOIN MiniProject.EquipmentCategory ec
	ON mo.category_id = ec.category_id
WHERE t.rental_end IS NOT NULL
GROUP BY ec.name
ORDER BY avg_duration_hours DESC;