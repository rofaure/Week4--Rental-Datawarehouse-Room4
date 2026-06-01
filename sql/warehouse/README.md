# Data Warehouse Star Schema Documentation

Week 4 mini-project: rental operations database and data warehouse for a light transport equipment rental company. This document describes the dimensional data warehouse model shown in `docs/star_schema.png`.

## Star Schema Overview

The data warehouse uses a star schema centered on the rental sales fact table:

```text
                 DimDate
                   |
DimCustomer -- FactSales -- DimItem
                   |
              DimGeography
```

`FactSales` contains the measurable rental activity. The dimension tables provide descriptive context used for grouping, filtering, and slicing reports.

The schema in the diagram contains the following tables:

| Table | Type | Purpose |
| --- | --- | --- |
| `FactSales` | Fact table | Stores one row per rented physical item on a rental transaction line. Contains rental revenue, transaction identifiers, dates, times, and foreign keys to dimensions. |
| `DimCustomer` | Dimension | Stores customer attributes copied from the operational customer table. |
| `DimDate` | Dimension | Stores calendar attributes used by rental start date and rental end date. |
| `DimGeography` | Dimension | Stores rental location attributes such as name, address, city, country, and whether the location is manned. |
| `DimItem` | Dimension | Stores denormalized equipment information, including item, model, category, status, usability, hourly rate, and maintenance attributes. |

The diagram uses the schema name `Miniproject`. The operational database documentation used `MiniProject`. The SQL scripts should choose one spelling and use it consistently across all tables, foreign keys, ETL scripts, and Power BI connections.

## Business Process Modeled

The fact table models the rental sales process.

A customer starts a rental at a location. The rental can include one or more physical equipment items. Each physical item is represented by one transaction line in the operational database. The warehouse preserves this transaction-line detail so that reports can analyze rentals at item level.

## Fact Grain

The fact grain is:

```text
One row in FactSales = one rental transaction line = one physical item rented in one rental transaction.
```

This grain matches the operational table `RentalTransactionLines`.

Implications of this grain:

- A transaction with one rented item produces one fact row.
- A transaction with three rented items produces three fact rows.
- `transaction_id` can repeat in `FactSales` when a transaction contains multiple items.
- `transactionline_id` identifies the individual rented item line.
- Rented item quantity is not stored as a separate column. It is calculated by counting fact rows.
- Line-level rental revenue is calculated from `FactSales.price`.
- Transaction-level totals must be handled carefully because `total_amount` is repeated on every line of a multi-item transaction.

## Fact Table Details

### `Miniproject.FactSales`

Stores the measurable rental activity at transaction-line grain.

| Column | Type | Key | Description |
| --- | --- | --- | --- |
| `transaction_id` | `int identity` | PK | Operational rental transaction identifier. Used for drill-through and distinct transaction counts. In dimensional modeling this also acts as a degenerate dimension. |
| `transactionline_id` | `int identity` | PK | Operational transaction line identifier. Identifies one rented physical item within a rental transaction. |
| `customer_key` | `int` | FK | Surrogate key to `DimCustomer`. Identifies the customer who made the rental. |
| `startdate_key` | `int` | FK | Surrogate/date key to `DimDate`. Represents the rental start date. |
| `enddate_key` | `int` | Nullable FK | Surrogate/date key to `DimDate`. Represents the rental end date. Nullable while the rental is still active. |
| `geography_key` | `int` | FK | Surrogate key to `DimGeography`. Represents the rental location role currently modeled in the star schema. Based on the operational model, this should be defined explicitly, preferably as the pickup location. |
| `item_key` | `int` | FK | Surrogate key to `DimItem`. Identifies the rented physical item and its equipment attributes. |
| `total_amount` | `decimal(18,2)` | Nullable | Transaction-level total amount from the operational rental transaction. Nullable for active rentals or before final calculation. Not fully additive at fact-line grain. |
| `price` | `decimal(18,2)` |  | Line-level price charged for this rented item. This is the main additive revenue measure. |
| `start_time` | `time` |  | Time part of the rental start timestamp. |
| `end_time` | `time` | Nullable | Time part of the rental end timestamp. Nullable while the rental is still active. |

Design notes:

- `FactSales` is named as a sales fact because it stores rental revenue. A business-specific alternative name could be `FactRental` or `FactRentalSales`, but the documentation follows the diagram name.
- `transaction_id` and `transactionline_id` are source identifiers from the operational database. If they are intended to preserve the operational IDs, the ETL should load them from the source instead of generating new identity values in the warehouse.
- A clean implementation can either use `(transaction_id, transactionline_id)` as a composite primary key or create a separate warehouse surrogate key such as `fact_sales_key` and enforce a unique constraint on `(transaction_id, transactionline_id)`.
- `price` is additive and can be summed across rows.
- `total_amount` is a transaction header value. Because it repeats for every line in the same transaction, summing `total_amount` directly can overstate revenue for multi-item rentals.
- `enddate_key` and `end_time` are nullable to support active rentals that have not yet been returned.

## Dimension Table Details

### `Miniproject.DimCustomer`

Stores customer attributes for reporting.

| Column | Type | Key | Description |
| --- | --- | --- | --- |
| `customer_key` | `int` | PK | Warehouse surrogate key for the customer dimension. |
| `customer_id` | `int` |  | Source customer identifier from the operational database. |
| `first_name` | `nvarchar(50)` |  | Customer first name. |
| `last_name` | `nvarchar(50)` |  | Customer last name. |
| `address` | `nvarchar(200)` |  | Customer address. |
| `city` | `nvarchar(50)` |  | Customer city. |
| `country` | `nvarchar(50)` |  | Customer country. |
| `email` | `nvarchar(200)` |  | Customer email address. |
| `phone` | `nvarchar(50)` |  | Customer phone number. |

Design notes:

- `customer_key` is the warehouse key used by facts.
- `customer_id` is retained for traceability back to the operational database.
- For this mini-project, the dimension can be loaded as a Type 1 dimension, where changed customer attributes overwrite previous values.
- If historical customer attribute changes become important later, this dimension can be extended to Type 2 with effective dates and a current-row flag.

### `Miniproject.DimDate`

Stores calendar attributes. The same date dimension is used twice by `FactSales`: once for the rental start date and once for the rental end date.

| Column | Type | Key | Description |
| --- | --- | --- | --- |
| `date_key` | `int` | PK | Date key used by fact rows. Usually implemented as `YYYYMMDD`, for example `20260131`. |
| `date` | `date` |  | Actual calendar date. |
| `year` | `int` |  | Calendar year. |
| `quarter` | `tinyint` |  | Calendar quarter, usually 1 to 4. |
| `month` | `tinyint` |  | Calendar month number, 1 to 12. |
| `week` | `tinyint` |  | Week number. Define whether this follows ISO week rules or SQL Server default week rules. |
| `day` | `tinyint` |  | Day of month, 1 to 31. |

Design notes:

- `DimDate` should be populated before loading the fact table.
- `startdate_key` is mandatory because every rental has a start date.
- `enddate_key` is nullable because active rentals may not yet have an end date.
- In Power BI, one relationship from `DimDate` to `FactSales` is typically active, usually the start-date relationship. The end-date relationship can be inactive and used in DAX measures with `USERELATIONSHIP` when analyzing returns by end date.
- The ETL should derive `startdate_key` from the date part of `RentalTransaction.rental_start`.
- The ETL should derive `enddate_key` from the date part of `RentalTransaction.rental_end` when `rental_end` is not null.

### `Miniproject.DimGeography`

Stores rental location and geography attributes.

| Column | Type | Key | Description |
| --- | --- | --- | --- |
| `geography_key` | `int` | PK | Warehouse surrogate key for the geography/location dimension. |
| `rentallocation_id` | `int` |  | Source rental location identifier from the operational database. |
| `name` | `nvarchar(50)` |  | Rental location name. |
| `address` | `nvarchar(200)` |  | Rental location address. |
| `city` | `nvarchar(50)` |  | City where the rental location is located. |
| `country` | `nvarchar(50)` |  | Country where the rental location is located. |
| `is_manned` | `bit` |  | Indicates whether the location is staffed. |

Design notes:

- Although the table is named `DimGeography`, it contains rental location attributes as well as geography. A clearer business name could be `DimLocation`, but the documentation follows the diagram name.
- The current star schema has one `geography_key` in `FactSales`. This means the model supports one location role directly.
- Based on the operational model, the single `geography_key` should be documented as the pickup location unless the team decides otherwise.
- If reporting needs to compare pickup and return locations, add a second foreign key to the same dimension, for example `pickup_geography_key` and `return_geography_key`. This is called a role-playing dimension.
- `rentallocation_id` is retained for source traceability and ETL lookup.

### `Miniproject.DimItem`

Stores denormalized equipment information. It combines data from operational equipment category, model, item, and maintenance records.

| Column | Type | Key | Description |
| --- | --- | --- | --- |
| `item_key` | `int` | PK | Warehouse surrogate key for the item dimension. |
| `item_id` | `int` |  | Source item identifier from the operational database. |
| `model_id` | `int` |  | Source model identifier. |
| `category_id` | `int` |  | Source equipment category identifier. |
| `maintenance_id` | `int` |  | Source maintenance record identifier. Should be nullable if an item has no maintenance record. |
| `category_name` | `nvarchar(50)` |  | Equipment category name, for example e-bike, scooter, or kickboard. |
| `model_brand` | `nvarchar(50)` |  | Equipment model brand. |
| `model_name` | `nvarchar(50)` |  | Equipment model name. |
| `status` | `nvarchar(50)` |  | Current item status, for example available, rented, maintenance, or retired. |
| `serial_number` | `nvarchar(50)` |  | Physical item serial number. |
| `hourly_rate` | `decimal(18,2)` |  | Standard hourly rental rate for the model. |
| `is_usable` | `bit` |  | Indicates whether the physical item is currently usable for rentals. |
| `maintenance_start` | `date` |  | Maintenance start date for the maintenance record stored in this row. |
| `maintenance_end` | `date` | Nullable | Maintenance end date. Nullable for active maintenance. |
| `maintenance_type` | `nvarchar(50)` |  | Type of maintenance, for example repair, inspection, battery replacement, or cleaning. |
| `maintenance_cost` | `decimal(18,2)` |  | Cost of the maintenance record stored in this row. |

Design notes:

- `DimItem` denormalizes the operational hierarchy `EquipmentCategory -> Model -> Item` into one dimension table. This is appropriate for a star schema because reports can filter by category, brand, model, or physical item without joining multiple normalized tables.
- `item_id`, `model_id`, and `category_id` are retained as source identifiers for traceability.
- `hourly_rate` is stored as a descriptive attribute of the model. Historical rental revenue should still come from `FactSales.price`, because rates may change over time.
- Maintenance data is included in the diagram as item attributes. This requires a clear grain decision:
  - If `DimItem` has one row per physical item, the maintenance columns should represent a selected maintenance record, such as the latest maintenance record.
  - If `DimItem` has one row per item per maintenance record, `item_id` can appear multiple times and fact rows must be mapped carefully to the correct item-maintenance row.
- For this mini-project, the simplest design is to load one `DimItem` row per physical item and store the latest maintenance record as descriptive context.
- If detailed maintenance analytics are required, a separate `FactMaintenance` table is a better long-term design than storing all maintenance events inside `DimItem`.

## Relationships and Cardinality

| Relationship | Cardinality | Description |
| --- | --- | --- |
| `DimCustomer.customer_key` -> `FactSales.customer_key` | One-to-many | One customer dimension row can be associated with many rental fact rows. Each fact row belongs to one customer. |
| `DimDate.date_key` -> `FactSales.startdate_key` | One-to-many | One date can be the start date for many rental fact rows. Each fact row has one start date. |
| `DimDate.date_key` -> `FactSales.enddate_key` | One-to-many, optional on fact | One date can be the end date for many rental fact rows. End date is nullable for active rentals. |
| `DimGeography.geography_key` -> `FactSales.geography_key` | One-to-many | One geography/location row can be associated with many rental fact rows. Each fact row references one modeled location role. |
| `DimItem.item_key` -> `FactSales.item_key` | One-to-many | One item dimension row can be associated with many rental fact rows over time. Each fact row references one rented physical item. |

## Source-to-Target Mapping

The warehouse is loaded from the operational database described in the ERD.

### Dimension Loads

| Warehouse table | Main operational source table(s) | Mapping logic |
| --- | --- | --- |
| `DimCustomer` | `Customer` | One row per operational customer. Load customer identity and contact attributes. |
| `DimDate` | Calendar generated table | Generate one row per calendar date for the reporting period. Also include future dates if future-dated rentals may be analyzed. |
| `DimGeography` | `RentalLocation` | One row per operational rental location. Load location name, address, city, country, and `is_manned`. |
| `DimItem` | `Item`, `Model`, `EquipmentCategory`, `MaintenanceRecord` | Join item to model and category. Left join maintenance data. Decide whether to load latest maintenance only or item-maintenance rows. |

### Fact Load

`FactSales` should be loaded from the operational rental header and line tables:

```text
RentalTransaction
  join RentalTransactionLines
  join DimCustomer by customer_id
  join DimDate by rental_start date -> startdate_key
  left join DimDate by rental_end date -> enddate_key
  join DimGeography by pickup_location_id -> rentallocation_id
  join DimItem by item_id
```

The fact load should populate:

| Fact column | Operational source / derivation |
| --- | --- |
| `transaction_id` | `RentalTransaction.transaction_id` |
| `transactionline_id` | `RentalTransactionLines.transactionline_id` |
| `customer_key` | Lookup in `DimCustomer` using `RentalTransaction.customer_id` |
| `startdate_key` | Lookup in `DimDate` using `CAST(RentalTransaction.rental_start AS date)` |
| `enddate_key` | Lookup in `DimDate` using `CAST(RentalTransaction.rental_end AS date)`, null if `rental_end` is null |
| `geography_key` | Lookup in `DimGeography` using `RentalTransaction.pickup_location_id`, if the single geography role is defined as pickup location |
| `item_key` | Lookup in `DimItem` using `RentalTransactionLines.item_id` |
| `total_amount` | `RentalTransaction.total_amount` |
| `price` | `RentalTransactionLines.price` |
| `start_time` | `CAST(RentalTransaction.rental_start AS time)` |
| `end_time` | `CAST(RentalTransaction.rental_end AS time)`, null if `rental_end` is null |

## Measures and Aggregation Rules

Because the fact table grain is one transaction line, measures should be defined with the correct level of detail.

| Measure | Recommended calculation | Notes |
| --- | --- | --- |
| Rental revenue | `SUM(FactSales.price)` | Main additive revenue measure. Safe to aggregate by date, customer, item, category, and location. |
| Rented item count | `COUNTROWS(FactSales)` | Counts rented physical items because each fact row represents one item line. |
| Rental transaction count | `DISTINCTCOUNT(FactSales.transaction_id)` | Counts rental transactions without double-counting multi-item transactions. |
| Average line price | `SUM(FactSales.price) / COUNTROWS(FactSales)` | Average revenue per rented item line. |
| Average items per transaction | `COUNTROWS(FactSales) / DISTINCTCOUNT(FactSales.transaction_id)` | Shows how many items are rented per transaction on average. |
| Active rental count | Count rows where `enddate_key IS NULL` or `end_time IS NULL` | Useful if active rentals are loaded into the warehouse. |
| Transaction total | Aggregate once per `transaction_id` | Do not use `SUM(total_amount)` directly across fact rows if transactions can contain multiple lines. |

Example DAX-style measure ideas for Power BI:

```text
Rental Revenue = SUM(FactSales[price])

Rented Items = COUNTROWS(FactSales)

Rental Transactions = DISTINCTCOUNT(FactSales[transaction_id])

Average Items Per Transaction = DIVIDE([Rented Items], [Rental Transactions])
```

For transaction-level total amount, use a calculation that counts each `transaction_id` once. The exact DAX depends on the final Power BI model, but the important rule is to avoid summing repeated header totals at line grain.

## Main Business Rules in the Star Schema

- Each fact row represents one rented physical item on one transaction line.
- Each fact row must reference one customer.
- Each fact row must reference one rental start date.
- Each fact row may have no rental end date when the rental is still active.
- Each fact row must reference one item.
- Each fact row must reference one geography/location role as currently modeled.
- Line-level revenue is stored in `price`.
- Transaction-level total amount is stored in `total_amount`, but it is not fully additive at the current fact grain.
- Customer, geography, and item dimensions use surrogate keys in the warehouse and retain operational source IDs for traceability.
- The item dimension flattens category, model, item, and selected maintenance data into one reporting table.

## Recommended Constraints and Data Quality Rules

The diagram defines the main primary keys and foreign keys. The implementation should also consider the following constraints.

### Primary keys

- `DimCustomer.customer_key`
- `DimDate.date_key`
- `DimGeography.geography_key`
- `DimItem.item_key`
- `FactSales.transaction_id, FactSales.transactionline_id` as a composite key, or a separate `fact_sales_key` with a unique constraint on `(transaction_id, transactionline_id)`

### Foreign keys

- `FactSales.customer_key` -> `DimCustomer.customer_key`
- `FactSales.startdate_key` -> `DimDate.date_key`
- `FactSales.enddate_key` -> `DimDate.date_key`
- `FactSales.geography_key` -> `DimGeography.geography_key`
- `FactSales.item_key` -> `DimItem.item_key`

### Suggested unique constraints

- `DimDate.date`, to avoid duplicate calendar dates.
- `DimCustomer.customer_id`, if the dimension is loaded as one row per current customer.
- `DimGeography.rentallocation_id`, if the dimension is loaded as one row per current rental location.
- `DimItem.item_id`, if the dimension is loaded as one row per physical item.
- `DimItem.item_id, DimItem.maintenance_id`, if the dimension is loaded at item-maintenance grain.
- `FactSales.transaction_id, FactSales.transactionline_id`, to avoid duplicate fact rows.

### Suggested check constraints

- `FactSales.price >= 0`
- `FactSales.total_amount IS NULL OR FactSales.total_amount >= 0`
- `DimItem.hourly_rate >= 0`
- `DimItem.maintenance_cost IS NULL OR DimItem.maintenance_cost >= 0`
- `DimDate.quarter BETWEEN 1 AND 4`
- `DimDate.month BETWEEN 1 AND 12`
- `DimDate.day BETWEEN 1 AND 31`
- `DimGeography.is_manned IN (0, 1)`
- `DimItem.is_usable IN (0, 1)`

### Handling unknown or missing dimension values

For a robust warehouse, consider adding unknown dimension rows:

| Dimension | Suggested unknown key | Purpose |
| --- | --- | --- |
| `DimCustomer` | `-1` | Used if a fact row has no matching customer during ETL. |
| `DimGeography` | `-1` | Used if a fact row has no matching location during ETL. |
| `DimItem` | `-1` | Used if a fact row has no matching item during ETL. |
| `DimDate` | Optional | Dates are usually known for starts. End dates can stay null for active rentals. |

Unknown rows help the fact load succeed while making data quality issues visible in validation reports.

## SQL Server Implementation Notes

- Use surrogate keys for dimensions: `customer_key`, `geography_key`, and `item_key`.
- `date_key` is usually not an identity column. A common pattern is an integer key in `YYYYMMDD` format.
- Foreign key columns in `FactSales` should be plain `INT` columns, not `IDENTITY` columns.
- If `transaction_id` and `transactionline_id` represent source operational identifiers, they should be loaded from the source instead of generated by `IDENTITY` in the warehouse.
- Add indexes on all fact foreign key columns to improve joins and Power BI refresh performance.
- Add a unique index on `(transaction_id, transactionline_id)` to prevent duplicate fact rows.
- Load dimension tables before loading the fact table.
- Load `DimDate` before all other fact loads because fact tables depend on date lookups.
- Use `LEFT JOIN` when loading nullable end-date and maintenance attributes.

## Power BI Modeling Notes

- Configure one-to-many relationships from each dimension to `FactSales`.
- Use single-direction filtering from dimensions to fact unless a specific report requires otherwise.
- Use `DimCustomer` for customer filters and customer-level reporting.
- Use `DimItem` for equipment category, brand, model, serial number, item status, and usability filters.
- Use `DimGeography` for city, country, location, and manned/unmanned location filters.
- Use `DimDate` for calendar reporting.
- Because `DimDate` connects to both start date and end date, keep the start-date relationship active by default and use an inactive end-date relationship for return-date measures if needed.
- Hide source identifiers such as `customer_id`, `item_id`, `model_id`, and `category_id` from report users unless they are needed for drill-through or debugging.
- Hide technical surrogate keys such as `customer_key`, `item_key`, `geography_key`, `startdate_key`, and `enddate_key` from report users.

## Example Reporting Questions

This star schema can support questions such as:

- How much rental revenue did we generate by month?
- Which equipment categories generate the most revenue?
- Which brands and models are rented most often?
- Which customers rent most frequently?
- How many items are rented from each location?
- Are staffed locations or unmanned stations generating more rental activity?
- How many rentals are still active?
- Which items are unavailable or not usable?
- Which equipment items have recent or active maintenance records?
- What is the average number of items per transaction?

## Validation Ideas

Useful validation queries include:

- Compare row count of operational `RentalTransactionLines` with row count of `FactSales`.
- Compare distinct operational `RentalTransaction.transaction_id` values with distinct `FactSales.transaction_id` values.
- Compare `SUM(RentalTransactionLines.price)` with `SUM(FactSales.price)`.
- Compare operational transaction totals with warehouse transaction totals by grouping `FactSales` at `transaction_id` level.
- Check that every non-null `FactSales.customer_key` exists in `DimCustomer`.
- Check that every non-null `FactSales.startdate_key` exists in `DimDate`.
- Check that every non-null `FactSales.enddate_key` exists in `DimDate`.
- Check that every non-null `FactSales.geography_key` exists in `DimGeography`.
- Check that every non-null `FactSales.item_key` exists in `DimItem`.
- Check for duplicate fact rows using `(transaction_id, transactionline_id)`.
- Check for null required keys in `FactSales`.
- Check that `FactSales.enddate_key` is null when operational `rental_end` is null.
- Check that `FactSales.end_time` is null when operational `rental_end` is null.
- Check that `DimItem` row count matches the intended item grain.
- Check that the date range in `DimDate` covers all rental start and end dates in the operational database.

## Open Design Decisions and Recommended Improvements

The current star schema is a good starting point for the mini-project. The following points should be agreed by the team before implementation.

### 1. Clarify the role of `geography_key`

The operational database has both pickup and return locations:

```text
RentalTransaction.pickup_location_id
RentalTransaction.return_location_id
```

The star schema currently has only one `geography_key`. The team should decide what it means.

Recommended decision for the current model:

```text
FactSales.geography_key = pickup location
```

Recommended future improvement:

```text
FactSales.pickup_geography_key
FactSales.return_geography_key
```

Both columns can reference `DimGeography`. This would allow reports comparing where rentals start versus where they are returned.

### 2. Clarify maintenance grain in `DimItem`

The operational database allows one item to have many maintenance records. The current star schema places maintenance columns inside `DimItem`.

Recommended decision for the current model:

```text
One row in DimItem = one physical item, with latest maintenance information included.
```

Recommended future improvement:

```text
FactMaintenance
```

A separate maintenance fact would support detailed maintenance analysis such as maintenance cost over time, number of maintenance events, average maintenance duration, and maintenance frequency by model or item.

### 3. Clarify fact table keys

The diagram marks both `transaction_id` and `transactionline_id` as identity primary key columns in `FactSales`. In the warehouse, these values should usually come from the operational source system.

Recommended implementation:

```text
Primary key or unique key: transaction_id + transactionline_id
```

Alternative implementation:

```text
fact_sales_key int identity primary key
transaction_id int
transactionline_id int
unique(transaction_id, transactionline_id)
```

The second option separates the warehouse technical key from the operational source identifiers.

### 4. Decide Type 1 versus Type 2 dimensions

For the mini-project, Type 1 dimensions are sufficient:

```text
When dimension attributes change, overwrite the old value.
```

This is simple and appropriate for a first implementation.

If historical attribute changes are important later, dimensions such as `DimCustomer`, `DimGeography`, and `DimItem` can be extended to Type 2 by adding:

```text
effective_start_date
effective_end_date
is_current
```

## Design Summary

The star schema converts the normalized rental operations database into an analytics-friendly model. The main design choices are:

- `FactSales` stores rental activity at transaction-line grain.
- `DimCustomer` provides customer reporting attributes.
- `DimDate` is a role-playing date dimension for rental start date and rental end date.
- `DimGeography` provides rental location and geography context.
- `DimItem` flattens equipment category, model, item, status, usability, hourly rate, and selected maintenance information.
- Rental revenue should be calculated from `FactSales.price`.
- Transaction counts should use distinct `transaction_id`.
- Rented item quantity should be calculated by counting fact rows.
- `total_amount` should not be summed directly across fact rows because it is a transaction-level value repeated at line grain.

The result is a simple star model that supports Power BI reporting while preserving item-level rental detail from the operational database.
