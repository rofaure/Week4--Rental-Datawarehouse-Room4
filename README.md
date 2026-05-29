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
