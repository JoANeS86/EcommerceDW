/*
===================================================================
            Create database EcommerceDW: DW Schema
===================================================================

-- We're utilizing AdventureWorks2022.bak to restore the database.
-- Once restored, we're adding the staging tables described below.

*/


-- 1/ Create the Data Warehouse Schema


CREATE SCHEMA DW;
GO

	
-- 2/ Create DimDate


-- Schema: DW
-- Table: DimDate
CREATE TABLE DW.DimDate (
    DateKey INT PRIMARY KEY,         -- YYYYMMDD format
    FullDate DATE NOT NULL,
    Year INT NOT NULL,
    Quarter INT NOT NULL,
    Month INT NOT NULL,
    Day INT NOT NULL,
    WeekOfYear INT NOT NULL,
    DayOfWeek INT NOT NULL,
    IsWeekend BIT NOT NULL
);
GO