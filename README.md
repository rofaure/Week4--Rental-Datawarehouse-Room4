# Week4--Rental-Datawarehouse-Room4

Week 4 mini-project: rental operations database and data warehouse for a light transport equipment rental company. The project includes a SQL Server operational database, a star schema data warehouse, ETL scripts, validation queries, and Power BI reporting.

## Project

Design and implement an operational database and a data warehouse for a company that rents light transport equipment such as e-bikes, scooters, and kickboards.

The operational database supports the core rental process:

1. Customers rent one or more physical equipment items.
2. Rentals start at a pickup location and may end at the same or a different return location.
3. A rental transaction can contain multiple rented items.
4. Each physical item belongs to a model, and each model belongs to an equipment category.
5. Items can be tracked through maintenance records.
6. Rental locations can represent both staffed stores and unmanned stations.

## Stack

- SQL Server / SSMS
- Power BI Desktop
- Git

## Folder structure

```text
/sql
  /operational       CREATE TABLE and INSERT scripts for the operational database
  /warehouse         CREATE TABLE scripts for the data warehouse dimensions and facts
/etl
  /dimensions        One script per dimension table load
  /facts             FactRental load script
  /validation        Queries comparing operational database totals with warehouse totals
/docs
  erd.png            ERD screenshot or export
  star_schema.png    Star schema diagram
  fact_grain.md      One sentence defining the fact grain
/powerbi
  report.pbix        Power BI report file
```

## Operational Database Design

The operational database is designed around rental transactions, rentable equipment, customers, locations, employees, and maintenance records. The schema is implemented in the `MiniProject` schema.

The core modeling decision is the equipment hierarchy:

```text
EquipmentCategory -> Model -> Item
```

This avoids a flat equipment table and separates business concepts clearly:

- `EquipmentCategory` stores broad equipment types, for example e-bike, scooter, or kickboard.
- `Model` stores brand, model name, and the standard hourly rate.
- `Item` stores one physical rentable unit with its own serial number, status, and usability flag.

Rental locations are modeled in a single `RentalLocation` table. The `is_manned` flag distinguishes staffed rental stores from unmanned stations without creating separate store and station tables.

Rental activity is modeled using a header/lines pattern:

```text
RentalTransaction -> RentalTransactionLines
```

`RentalTransaction` stores the rental header: customer, pickup location, return location, rental start/end time, and total amount. `RentalTransactionLines` stores one row per physical item rented in the transaction. This makes quantity implicit: the number of rented items in a transaction is the count of its transaction lines.

Maintenance is modeled separately in `MaintenanceRecord`, which links directly to `Item`. This allows equipment lifecycle tracking without mixing maintenance data into the rental transaction model.

## Entity Overview

| Table | Purpose |
| --- | --- |
| `Employee` | Stores employees who operate or are responsible for rental locations. |
| `RentalLocation` | Stores pickup and return locations, including both staffed stores and unmanned stations. |
| `Customer` | Stores customer identity and contact information. |
| `RentalTransaction` | Stores the rental header: who rented, where the rental started/ended, when it occurred, and the total amount. |
| `RentalTransactionLines` | Stores the physical items included in a rental transaction, one row per rented item. |
| `EquipmentCategory` | Stores high-level equipment categories such as e-bike, scooter, and kickboard. |
| `Model` | Stores equipment model information and the standard hourly rental rate. |
| `Item` | Stores individual rentable physical items, including serial number and operational status. |
| `MaintenanceRecord` | Stores maintenance periods, type of maintenance, and maintenance cost for individual items. |

## Table Details

### `MiniProject.Employee`

Stores employee information.

| Column | Type | Key | Description |
| --- | --- | --- | --- |
| `employee_id` | `int identity` | PK | Surrogate key for an employee. |
| `first_name` | `nvarchar(50)` |  | Employee first name. |
| `last_name` | `nvarchar(50)` |  | Employee last name. |
| `role` | `nvarchar(50)` |  | Employee role, for example store manager or staff member. |

### `MiniProject.RentalLocation`

Stores both staffed rental stores and unmanned rental stations.

| Column | Type | Key | Description |
| --- | --- | --- | --- |
| `rentallocation_id` | `int identity` | PK | Surrogate key for a rental location. |
| `name` | `nvarchar(50)` |  | Location name. |
| `address` | `nvarchar(200)` |  | Street address or location description. |
| `city` | `nvarchar(50)` |  | City where the location is located. |
| `country` | `nvarchar(50)` |  | Country where the location is located. |
| `is_manned` | `bit` |  | Indicates whether the location is staffed. |
| `employee_id` | `int` | FK | Employee responsible for the location. References `Employee.employee_id`. |

Design notes:

- `is_manned = 1` represents a staffed rental store.
- `is_manned = 0` represents an unmanned station.
- If unmanned stations do not have an assigned employee, `employee_id` should be nullable. If every location must have an owner or responsible staff member, keep it mandatory.

### `MiniProject.Customer`

Stores customer identity and contact details.

| Column | Type | Key | Description |
| --- | --- | --- | --- |
| `customer_id` | `int identity` | PK | Surrogate key for a customer. |
| `first_name` | `nvarchar(50)` |  | Customer first name. |
| `last_name` | `nvarchar(50)` |  | Customer last name. |
| `address` | `nvarchar(200)` |  | Customer address. |
| `country` | `nvarchar(50)` |  | Customer country. |
| `city` | `nvarchar(50)` |  | Customer city. |
| `email` | `nvarchar(200)` |  | Customer email address. |
| `phone` | `nvarchar(50)` |  | Customer phone number. |

### `MiniProject.EquipmentCategory`

Stores high-level categories of rentable equipment.

| Column | Type | Key | Description |
| --- | --- | --- | --- |
| `category_id` | `int identity` | PK | Surrogate key for an equipment category. |
| `name` | `nvarchar(50)` |  | Category name, for example e-bike, scooter, or kickboard. |

### `MiniProject.Model`

Stores equipment models and their standard rental prices.

| Column | Type | Key | Description |
| --- | --- | --- | --- |
| `model_id` | `int identity` | PK | Surrogate key for an equipment model. |
| `category_id` | `int` | FK | Equipment category. References `EquipmentCategory.category_id`. |
| `brand` | `nvarchar(50)` |  | Equipment brand. |
| `name` | `nvarchar(50)` |  | Model name. |
| `hourly_rate` | `decimal(18,2)` |  | Standard hourly rental rate for this model. |

Design notes:

- Pricing is stored at model level because items of the same model normally share the same standard rate.
- Historical rental revenue should be read from `RentalTransactionLines.price`, not recalculated only from the current `Model.hourly_rate`, because model rates may change over time.

### `MiniProject.Item`

Stores individual physical rentable devices.

| Column | Type | Key | Description |
| --- | --- | --- | --- |
| `item_id` | `int identity` | PK | Surrogate key for a physical equipment item. |
| `model_id` | `int` | FK | Model of the item. References `Model.model_id`. |
| `status` | `nvarchar(50)` |  | Current operational state, for example available, rented, maintenance, or retired. |
| `serial_number` | `nvarchar(50)` |  | Physical serial number of the item. |
| `is_usable` | `bit` |  | Indicates whether the item is currently usable for rentals. |

Design notes:

- `Item` is the lowest level of the equipment hierarchy and represents one real-world rentable unit.
- `serial_number` should be unique if each physical device has one official serial number.
- `status` and `is_usable` should be kept consistent. For example, an item in maintenance should normally have `is_usable = 0`.

### `MiniProject.RentalTransaction`

Stores the rental transaction header.

| Column | Type | Key | Description |
| --- | --- | --- | --- |
| `transaction_id` | `int identity` | PK | Surrogate key for a rental transaction. |
| `customer_id` | `int` | FK | Customer who made the rental. References `Customer.customer_id`. |
| `pickup_location_id` | `int` | FK | Location where the rental started. References `RentalLocation.rentallocation_id`. |
| `return_location_id` | `int` | Nullable FK | Location where the rental ended. References `RentalLocation.rentallocation_id`. |
| `rental_start` | `datetime` |  | Start timestamp of the rental. |
| `rental_end` | `datetime` | Nullable | End timestamp of the rental. Nullable while the rental is still active. |
| `total_amount` | `decimal(18,2)` | Nullable | Total rental amount. Nullable while the rental is active or before final calculation. |

Design notes:

- `return_location_id` is nullable to support active rentals that have not yet been returned.
- `rental_end` is nullable for the same reason.
- `total_amount` can be derived as the sum of transaction line prices. If stored, it should match the sum of `RentalTransactionLines.price` for the transaction.

### `MiniProject.RentalTransactionLines`

Stores the physical items included in each rental transaction.

| Column | Type | Key | Description |
| --- | --- | --- | --- |
| `transactionline_id` | `int identity` | PK | Surrogate key for a transaction line. |
| `transaction_id` | `int` | FK | Parent rental transaction. References `RentalTransaction.transaction_id`. |
| `item_id` | `int` | FK | Rented physical item. References `Item.item_id`. |
| `price` | `decimal(18,2)` |  | Final price charged for this item in this rental transaction. |

Design notes:

- Each row represents exactly one rented physical item.
- A rental with three items has one `RentalTransaction` row and three `RentalTransactionLines` rows.
- The `price` column preserves the actual historical charge for the item in that transaction.
- The ERD shows both `transactionline_id` and `transaction_id` as part of the key. If `transactionline_id` is a globally unique identity column, a single-column primary key on `transactionline_id` is usually enough, with `transaction_id` kept as a foreign key and indexed for query performance.

### `MiniProject.MaintenanceRecord`

Stores maintenance activity for individual items.

| Column | Type | Key | Description |
| --- | --- | --- | --- |
| `maintenance_id` | `int identity` | PK | Surrogate key for a maintenance record. |
| `maintenance_start` | `date` |  | Date when maintenance started. |
| `maintenance_end` | `date` | Nullable | Date when maintenance ended. Nullable while maintenance is still active. |
| `type` | `nvarchar(50)` |  | Maintenance type, for example repair, inspection, battery replacement, or cleaning. |
| `cost` | `decimal(18,2)` |  | Maintenance cost. |
| `item_id` | `int` | FK | Maintained physical item. References `Item.item_id`. |

Design notes:

- Maintenance is linked to `Item`, not `Model`, because maintenance happens to a specific physical device.
- `maintenance_end` is nullable to support currently open maintenance work.

## Relationships and Cardinality

| Relationship | Cardinality | Description |
| --- | --- | --- |
| `Employee` -> `RentalLocation` | One-to-many | One employee can be responsible for multiple rental locations. Each location references one employee, unless the implementation allows unmanned locations without an employee. |
| `Customer` -> `RentalTransaction` | One-to-many | One customer can have many rental transactions. Each transaction belongs to one customer. |
| `RentalLocation` -> `RentalTransaction.pickup_location_id` | One-to-many | One location can be used as the pickup location for many transactions. Each transaction has one pickup location. |
| `RentalLocation` -> `RentalTransaction.return_location_id` | One-to-many, optional on transaction | One location can be used as the return location for many transactions. Return location is nullable for active rentals. |
| `RentalTransaction` -> `RentalTransactionLines` | One-to-many | One transaction can contain many rented items. Each transaction line belongs to one transaction. |
| `Item` -> `RentalTransactionLines` | One-to-many over time | One item can appear in many transaction lines across its lifecycle, but should not be rented in overlapping active rentals. |
| `EquipmentCategory` -> `Model` | One-to-many | One category can contain many equipment models. Each model belongs to one category. |
| `Model` -> `Item` | One-to-many | One model can have many physical items. Each item belongs to one model. |
| `Item` -> `MaintenanceRecord` | One-to-many | One item can have many maintenance records. Each maintenance record belongs to one item. |

## Main Business Rules

- A customer can make zero, one, or many rental transactions.
- A rental transaction must have one customer and one pickup location.
- A rental transaction may have no return location until the equipment is returned.
- A rental transaction must have at least one transaction line to represent the rented item or items.
- Each transaction line represents one physical item.
- Quantity is not stored directly. It is calculated by counting transaction lines.
- An item belongs to exactly one model.
- A model belongs to exactly one equipment category.
- The standard rental rate is stored on the model.
- The actual historical rental charge is stored on the transaction line.
- An item can have many maintenance records over time.
- An item should not be rented while it is in active maintenance or marked as not usable.
- An item should not be included in two overlapping active rentals.

## Recommended Constraints and Data Quality Rules

The ERD defines the main primary keys and foreign keys. The implementation should also consider the following constraints.

### Primary keys

- `Employee.employee_id`
- `RentalLocation.rentallocation_id`
- `Customer.customer_id`
- `EquipmentCategory.category_id`
- `Model.model_id`
- `Item.item_id`
- `RentalTransaction.transaction_id`
- `RentalTransactionLines.transactionline_id`
- `MaintenanceRecord.maintenance_id`

### Foreign keys

- `RentalLocation.employee_id` -> `Employee.employee_id`
- `Model.category_id` -> `EquipmentCategory.category_id`
- `Item.model_id` -> `Model.model_id`
- `RentalTransaction.customer_id` -> `Customer.customer_id`
- `RentalTransaction.pickup_location_id` -> `RentalLocation.rentallocation_id`
- `RentalTransaction.return_location_id` -> `RentalLocation.rentallocation_id`
- `RentalTransactionLines.transaction_id` -> `RentalTransaction.transaction_id`
- `RentalTransactionLines.item_id` -> `Item.item_id`
- `MaintenanceRecord.item_id` -> `Item.item_id`

### Suggested unique constraints

- `Customer.email`, if every customer must have a unique email address.
- `Item.serial_number`, if every physical device has a unique serial number.
- `EquipmentCategory.name`, to avoid duplicate category names.
- `Model.category_id, Model.brand, Model.name`, to avoid duplicate model definitions inside the same category.

### Suggested check constraints

- `Model.hourly_rate > 0`
- `RentalTransactionLines.price >= 0`
- `RentalTransaction.total_amount >= 0`
- `RentalTransaction.rental_end IS NULL OR RentalTransaction.rental_end >= RentalTransaction.rental_start`
- `MaintenanceRecord.maintenance_end IS NULL OR MaintenanceRecord.maintenance_end >= MaintenanceRecord.maintenance_start`
- `Item.is_usable IN (0, 1)`
- `RentalLocation.is_manned IN (0, 1)`

### Implementation notes for SQL Server

- Use `IDENTITY` on surrogate primary key columns only.
- Foreign key columns should normally be plain `INT`, not `INT IDENTITY`, because they reference identity values generated in parent tables.
- Consider using lookup tables for controlled values such as item status, employee role, and maintenance type if the project requires stricter data quality.
- Add indexes on all foreign key columns to improve join and ETL performance.

## Operational Process Supported by the Schema

### 1. Register equipment categories and models

Categories such as e-bike, scooter, and kickboard are inserted into `EquipmentCategory`. Each rentable product model is inserted into `Model` with a brand, model name, category, and hourly rate.

### 2. Register physical items

Each real rentable device is inserted into `Item` with its model, serial number, status, and usability flag. This allows the company to track individual devices instead of only tracking equipment types.

### 3. Register customers and locations

Customers are stored in `Customer`. Rental points are stored in `RentalLocation`, with `is_manned` indicating whether the location is a staffed store or an unmanned station.

### 4. Start a rental

A new row is inserted into `RentalTransaction` with the customer, pickup location, and rental start timestamp. One or more rows are inserted into `RentalTransactionLines`, one for each physical item rented.

### 5. End a rental

When the rental is returned, `return_location_id`, `rental_end`, and `total_amount` are updated in `RentalTransaction`. The item status and usability information in `Item` should also be updated as needed.

### 6. Record maintenance

When an item needs inspection or repair, a row is inserted into `MaintenanceRecord`. Open maintenance can be represented with a null `maintenance_end` value.

## Data Warehouse Design Notes

The operational database is normalized for transaction processing. The data warehouse should be modeled for analytics and reporting.

Fact grain for the data warehouse:

```text
One row in FactRental = one row in RentalTransactionLines.
```

This grain is useful because it preserves item-level rental detail. It supports analysis by:

- Customer
- Rental start date and time
- Rental end date and time
- Pickup location
- Return location
- Equipment category
- Model
- Physical item
- Employee or responsible location staff
- Rental price and revenue

Because the fact grain is one transaction line, transaction-level metrics must be aggregated carefully. For example:

- Number of rented items = count of fact rows.
- Number of rental transactions = count distinct `transaction_id`.
- Rental revenue = sum of line price.
- Transaction total can be validated by comparing `RentalTransaction.total_amount` with the sum of line prices.

## Validation Ideas

Useful validation queries include:

- Compare operational transaction totals with the sum of line prices.
- Compare total operational revenue with warehouse fact revenue.
- Count transactions in the operational database and compare with distinct transaction count in the warehouse.
- Count transaction lines in the operational database and compare with fact row count in the warehouse.
- Check for items assigned to overlapping active rentals.
- Check for rentals containing items with `is_usable = 0`.
- Check for active maintenance records on items that are also active rentals.
- Check for orphan records, although foreign keys should prevent them.

## Design Summary

This design separates stable reference data, physical equipment inventory, rental events, and maintenance history. The most important design choices are:

- A three-level equipment hierarchy: `EquipmentCategory -> Model -> Item`.
- A unified `RentalLocation` table for both stores and stations.
- A transaction header/lines structure for rentals.
- Item-level rental traceability through `RentalTransactionLines`.
- Separate maintenance tracking through `MaintenanceRecord`.
- A data warehouse fact grain at transaction-line level.

The result is an operational schema that supports day-to-day rental operations while also providing a clean source for dimensional modeling, ETL, and Power BI reporting.
