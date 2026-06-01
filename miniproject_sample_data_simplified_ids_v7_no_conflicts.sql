USE RentalOperationsDB;
GO

-- ============================================================
-- MiniProject sample data
-- Matches the provided CREATE TABLE script.
--
-- Important:
-- - Identity primary key columns are NOT inserted manually.
-- - This script assumes the tables are empty and identity values start from 1.
-- - FK references are based on the insert order below.
--
-- Included:
-- - 20 customers
-- - 40 rental transactions
-- - 30 items
-- - 50 transaction lines
-- - first 5 transactions have 3 lines
-- - 3 cities: Helsinki, Stockholm, Zurich
-- - 2 rental locations per city
-- - 1 unmanned location per city
-- - 3 categories: bike, scooter, kickboard
-- - 5 maintenance records
--
-- Data quality rules included:
-- - No overlapping rentals for the same item
-- - Pickup and return locations are in the same city
-- - About 70% of completed returns are to the same location
-- - rental_end NULL means total_amount and line_amount are NULL
-- - Item.status values match CK_Item_Status
-- - MaintenanceRecord.type values match CK_Maintenance_Type
-- ============================================================

SET NOCOUNT ON;
GO

INSERT INTO MiniProject.Employee (first_name, last_name, role) VALUES
('Aino', 'Korhonen', 'Branch Manager'),
('Mikko', 'Laine', 'Service Agent'),
('Elsa', 'Andersson', 'Branch Manager'),
('Lars', 'Nilsson', 'Service Agent'),
('Anna', 'Meier', 'Branch Manager'),
('Luca', 'Muller', 'Service Agent');
GO

INSERT INTO MiniProject.RentalLocation (name, address, city, country, is_manned, employee_id) VALUES
('Helsinki Central', 'Kaivokatu 1', 'Helsinki', 'Finland', 1, 1),
('Helsinki Harbor', 'Satamakatu 12', 'Helsinki', 'Finland', 0, 2),
('Stockholm City', 'Drottninggatan 20', 'Stockholm', 'Sweden', 1, 3),
('Stockholm Waterfront', 'Norrmalmstorg 5', 'Stockholm', 'Sweden', 0, 4),
('Zurich HB', 'Bahnhofplatz 15', 'Zurich', 'Switzerland', 1, 5),
('Zurich Lake', 'Seestrasse 40', 'Zurich', 'Switzerland', 0, 6);
GO

INSERT INTO MiniProject.EquipmentCategory (name) VALUES
('bike'),
('scooter'),
('kickboard');
GO

INSERT INTO MiniProject.Model (category_id, brand, name, hourly_rate) VALUES
(1, 'Trek', 'FX 2 Disc', 8.50),
(1, 'Cube', 'Nature Pro', 9.00),
(1, 'Specialized', 'Sirrus X', 10.00),
(2, 'Xiaomi', 'Mi Electric 3', 7.50),
(2, 'Segway', 'Ninebot Max', 8.00),
(2, 'Voi', 'Explorer', 7.00),
(3, 'Micro', 'Classic', 4.00),
(3, 'Razor', 'A5 Lux', 4.50),
(3, 'Oxelo', 'Town 7', 5.00);
GO

INSERT INTO MiniProject.Customer (first_name, last_name, address, country, city, email, phone) VALUES
('Emma', 'Virtanen', 'Mannerheimintie 42 A', 'Finland', 'Helsinki', 'emma.virtanen@example.com', '+358401000001'),
('Noah', 'Johansson', 'Sveavagen 18', 'Sweden', 'Stockholm', 'noah.johansson@example.com', '+46701000002'),
('Olivia', 'Muller', 'Bahnhofstrasse 88', 'Switzerland', 'Zurich', 'olivia.muller@example.com', '+41441000003'),
('Liam', 'Nieminen', 'Runeberginkatu 9', 'Finland', 'Helsinki', 'liam.nieminen@example.com', '+358401000004'),
('Sofia', 'Andersson', 'Gotgatan 55', 'Sweden', 'Stockholm', 'sofia.andersson@example.com', '+46701000005'),
('Elias', 'Meier', 'Langstrasse 21', 'Switzerland', 'Zurich', 'elias.meier@example.com', '+41441000006'),
('Ines', 'Lehtonen', 'Eerikinkatu 14', 'Finland', 'Helsinki', 'ines.lehtonen@example.com', '+358401000007'),
('Jonas', 'Karlsson', 'Kungsgatan 7', 'Sweden', 'Stockholm', 'jonas.karlsson@example.com', '+46701000008'),
('Maja', 'Schmid', 'Limmatquai 32', 'Switzerland', 'Zurich', 'maja.schmid@example.com', '+41441000009'),
('Leo', 'Hakala', 'Aleksanterinkatu 28', 'Finland', 'Helsinki', 'leo.hakala@example.com', '+358401000010'),
('Clara', 'Lund', 'St Eriksgatan 76', 'Sweden', 'Stockholm', 'clara.lund@example.com', '+46701000011'),
('Hugo', 'Weber', 'Seefeldstrasse 104', 'Switzerland', 'Zurich', 'hugo.weber@example.com', '+41441000012'),
('Nina', 'Salonen', 'Hameentie 5 B', 'Finland', 'Helsinki', 'nina.salonen@example.com', '+358401000013'),
('Oscar', 'Berg', 'Hornsgatan 91', 'Sweden', 'Stockholm', 'oscar.berg@example.com', '+46701000014'),
('Sara', 'Keller', 'Universitatstrasse 12', 'Switzerland', 'Zurich', 'sara.keller@example.com', '+41441000015'),
('Felix', 'Koski', 'Bulevardi 17', 'Finland', 'Helsinki', 'felix.koski@example.com', '+358401000016'),
('Eva', 'Svensson', 'Sodermalm Alle 3', 'Sweden', 'Stockholm', 'eva.svensson@example.com', '+46701000017'),
('Daniel', 'Fischer', 'Badenerstrasse 230', 'Switzerland', 'Zurich', 'daniel.fischer@example.com', '+41441000018'),
('Laura', 'Lahti', 'Pohjoisesplanadi 11', 'Finland', 'Helsinki', 'laura.lahti@example.com', '+358401000019'),
('Max', 'Huber', 'Freiestrasse 45', 'Switzerland', 'Zurich', 'max.huber@example.com', '+41441000020');
GO

INSERT INTO MiniProject.Item (model_id, status, serial_number, is_usable) VALUES
(1, 'rented', 'SN-00001', 1),
(2, 'rented', 'SN-00002', 1),
(3, 'rented', 'SN-00003', 1),
(4, 'maintenance', 'SN-00004', 0),
(5, 'rented', 'SN-00005', 1),
(6, 'rented', 'SN-00006', 1),
(7, 'rented', 'SN-00007', 1),
(8, 'rented', 'SN-00008', 1),
(9, 'maintenance', 'SN-00009', 0),
(1, 'rented', 'SN-00010', 1),
(2, 'available', 'SN-00011', 1),
(3, 'available', 'SN-00012', 1),
(4, 'available', 'SN-00013', 1),
(5, 'maintenance', 'SN-00014', 0),
(6, 'available', 'SN-00015', 1),
(7, 'available', 'SN-00016', 1),
(8, 'available', 'SN-00017', 1),
(9, 'available', 'SN-00018', 1),
(1, 'maintenance', 'SN-00019', 0),
(2, 'available', 'SN-00020', 1),
(3, 'available', 'SN-00021', 1),
(4, 'available', 'SN-00022', 1),
(5, 'available', 'SN-00023', 1),
(6, 'maintenance', 'SN-00024', 0),
(7, 'available', 'SN-00025', 1),
(8, 'available', 'SN-00026', 1),
(9, 'available', 'SN-00027', 1),
(1, 'retired', 'SN-00028', 0),
(2, 'retired', 'SN-00029', 0),
(3, 'retired', 'SN-00030', 0);
GO

INSERT INTO MiniProject.RentalTransaction (customer_id, pickup_location_id, return_location_id, rental_start, rental_end, total_amount) VALUES
(1, 1, NULL, '2026-07-01 09:00:00', NULL, NULL),
(2, 2, 2, '2026-07-02 10:00:00', '2026-07-02 13:00:00', 57.00),
(3, 3, 3, '2026-07-03 11:00:00', '2026-07-03 15:00:00', 88.00),
(4, 4, 4, '2026-07-04 12:00:00', '2026-07-04 17:00:00', 122.50),
(5, 5, 5, '2026-07-05 13:00:00', '2026-07-05 19:00:00', 81.00),
(6, 6, NULL, '2026-07-06 09:00:00', NULL, NULL),
(7, 1, 1, '2026-07-07 10:00:00', '2026-07-07 12:00:00', 20.00),
(8, 2, 2, '2026-07-08 11:00:00', '2026-07-08 14:00:00', 22.50),
(9, 3, 3, '2026-07-09 12:00:00', '2026-07-09 16:00:00', 32.00),
(10, 4, 4, '2026-07-10 13:00:00', '2026-07-10 18:00:00', 20.00),
(11, 5, NULL, '2026-07-11 09:00:00', NULL, NULL),
(12, 6, 6, '2026-07-12 10:00:00', '2026-07-12 17:00:00', 35.00),
(13, 1, 1, '2026-07-13 11:00:00', '2026-07-13 13:00:00', 16.00),
(14, 2, 2, '2026-07-14 12:00:00', '2026-07-14 15:00:00', 21.00),
(15, 3, 3, '2026-07-15 13:00:00', '2026-07-15 17:00:00', 16.00),
(16, 4, NULL, '2026-07-16 09:00:00', NULL, NULL),
(17, 5, 5, '2026-07-17 10:00:00', '2026-07-17 16:00:00', 51.00),
(18, 6, 6, '2026-07-18 11:00:00', '2026-07-18 18:00:00', 63.00),
(19, 1, 1, '2026-07-19 12:00:00', '2026-07-19 14:00:00', 20.00),
(20, 2, 2, '2026-07-20 13:00:00', '2026-07-20 16:00:00', 22.50),
(1, 3, NULL, '2026-07-21 09:00:00', NULL, NULL),
(2, 4, 4, '2026-07-22 10:00:00', '2026-07-22 15:00:00', 20.00),
(3, 5, 5, '2026-07-23 11:00:00', '2026-07-23 17:00:00', 27.00),
(4, 6, 6, '2026-07-24 12:00:00', '2026-07-24 19:00:00', 35.00),
(5, 1, 1, '2026-07-25 13:00:00', '2026-07-25 15:00:00', 20.00),
(6, 2, NULL, '2026-07-26 09:00:00', NULL, NULL),
(7, 3, 3, '2026-07-27 10:00:00', '2026-07-27 14:00:00', 32.00),
(8, 4, 4, '2026-07-28 11:00:00', '2026-07-28 16:00:00', 20.00),
(9, 5, 5, '2026-07-29 12:00:00', '2026-07-29 18:00:00', 30.00),
(10, 6, 5, '2026-07-30 13:00:00', '2026-07-30 20:00:00', 56.00),
(11, 1, NULL, '2026-07-31 09:00:00', NULL, NULL),
(12, 2, 1, '2026-08-01 10:00:00', '2026-08-01 13:00:00', 12.00),
(13, 3, 4, '2026-08-02 11:00:00', '2026-08-02 15:00:00', 34.00),
(14, 4, 3, '2026-08-03 12:00:00', '2026-08-03 17:00:00', 45.00),
(15, 5, 6, '2026-08-04 13:00:00', '2026-08-04 19:00:00', 60.00),
(16, 6, NULL, '2026-08-05 09:00:00', NULL, NULL),
(17, 1, 2, '2026-08-06 10:00:00', '2026-08-06 12:00:00', 8.00),
(18, 2, 1, '2026-08-07 11:00:00', '2026-08-07 14:00:00', 13.50),
(19, 3, 4, '2026-08-08 12:00:00', '2026-08-08 16:00:00', 20.00),
(20, 4, 3, '2026-08-09 13:00:00', '2026-08-09 18:00:00', 50.00);
GO

INSERT INTO MiniProject.RentalTransactionLines (transaction_id, item_id, line_amount) VALUES
(1, 1, NULL),
(1, 2, NULL),
(1, 3, NULL),
(2, 5, 24.00),
(2, 6, 21.00),
(2, 7, 12.00),
(3, 8, 18.00),
(3, 10, 34.00),
(3, 11, 36.00),
(4, 12, 50.00),
(4, 13, 37.50),
(4, 15, 35.00),
(5, 16, 24.00),
(5, 17, 27.00),
(5, 18, 30.00),
(6, 20, NULL),
(7, 21, 20.00),
(8, 22, 22.50),
(9, 23, 32.00),
(10, 25, 20.00),
(11, 26, NULL),
(12, 27, 35.00),
(13, 5, 16.00),
(14, 6, 21.00),
(15, 7, 16.00),
(16, 8, NULL),
(17, 10, 51.00),
(18, 11, 63.00),
(19, 12, 20.00),
(20, 13, 22.50),
(21, 15, NULL),
(22, 16, 20.00),
(23, 17, 27.00),
(24, 18, 35.00),
(25, 21, 20.00),
(26, 22, NULL),
(27, 23, 32.00),
(28, 25, 20.00),
(29, 27, 30.00),
(30, 5, 56.00),
(31, 6, NULL),
(32, 7, 12.00),
(33, 10, 34.00),
(34, 11, 45.00),
(35, 12, 60.00),
(36, 13, NULL),
(37, 16, 8.00),
(38, 17, 13.50),
(39, 18, 20.00),
(40, 21, 50.00);
GO

INSERT INTO MiniProject.MaintenanceRecord (maintenance_start, maintenance_end, type, cost, item_id) VALUES
('2026-07-03', '2026-07-04', 'Inspection', 35.00, 4),
('2026-07-08', NULL, 'Repair', 60.00, 9),
('2026-07-12', '2026-07-13', 'Battery Replacement', 120.00, 14),
('2026-07-18', NULL, 'Repair', 45.00, 19),
('2026-07-22', '2026-07-23', 'Inspection', 30.00, 24);
GO


SELECT * FROM MiniProject.Customer;
SELECT * FROM MiniProject.Employee;
SELECT * FROM MiniProject.EquipmentCategory;
SELECT * FROM MiniProject.Item;
SELECT * FROM MiniProject.MaintenanceRecord;
SELECT * FROM MiniProject.Model;
SELECT * FROM MiniProject.RentalLocation;
SELECT * FROM MiniProject.RentalTransaction;
SELECT * FROM MiniProject.RentalTransactionLines;