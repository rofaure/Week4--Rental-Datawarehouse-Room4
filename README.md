# Week4--Rental-Datawarehouse-Room4

Week 4 mini-project: rental operations database and data warehouse for a light transport equipment rental company. The project includes an SQL Server operational database, a star schema data warehouse, ETL scripts, validation queries, and Power BI reporting.

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

- Microsoft SQL Server, SQL Server Management Studio
- T-SQL stored procedures
- Operational source database: `RentalOperationsDB`
- Data warehouse target database: `RentalDW`
- Power BI as the reporting layer
- GitHub, Git

## Folder structure

```text
/docs
  erd.png            Entity-relationship diagram (ERD) of the operational database
  star_schema.png    Star schema diagram of the data warehouse
/etl                 ETL scripts for loading dimension tables and FactSales table
  /validation        Queries comparing operational database totals with warehouse totals
  README.md          Readme file for the ETL scripts
/powerbi
  report.pbix        Power BI report file
/sql
  /operational       CREATE TABLE and INSERT scripts for the operational database
    README.md        Readme file for the operational database
  /warehouse         CREATE TABLE scripts for the data warehouse dimensions and facts
    README.md        Readme file for the data warehouse
README.md            The main readme file
```
