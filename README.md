# Week4--Rental-Datawarehouse-Room4
Week 4 mini-project: Rental operations database and data warehouse. SQL Server operational DB, star schema DW, ETL scripts, and Power BI reports.

## Project
Design and implement an operational database and data warehouse for a light 
transport equipment rental company (e-bikes, scooters, kickboards).

## Stack
- SQL Server (SSMS)
- Power BI Desktop
- Git

## Folder structure
/sql
  /operational       ← CREATE TABLE + INSERT scripts for the ODB
  /warehouse         ← CREATE TABLE scripts for DW (Dim + Fact)
/etl
  /dimensions        ← One script per Dim table load
  /facts             ← FactRental load script
  /validation        ← Queries comparing ODB vs DW totals
/docs
  erd.png            ← ERD screenshot or export
  star_schema.png    ← Star schema diagram
  fact_grain.md      ← One sentence defining the fact grain
/powerbi
  report.pbix        ← Power BI file


## Operational Database Design
The ODB was designed iteratively through four review cycles.

The core modeling decision was the equipment hierarchy: rather than a flat 
Equipment table, we split it into EquipmentCategory → Model → Item, where 
Item represents a single physical rentable device with its own serial number 
and status. Rental price (hourly_rate) lives on Model, not on the physical item.

RentalStore and RentalStation were consolidated into a single RentalLocation 
table with an is_manned bit flag, keeping the schema clean without losing the 
store vs station distinction needed for reporting.

RentalTransaction was split into a header/lines pattern: RentalTransaction holds 
the context (customer, location, employee), and RentalTransactionLine holds one 
row per physical item rented. This gives full per-item traceability and makes 
quantity implicit — derived by counting lines per transaction.

MaintenanceRecord was added as a separate table linked to Item, enabling 
equipment lifecycle tracking without polluting the rental transaction model.

Fact grain for the data warehouse: one row = one transaction line.
