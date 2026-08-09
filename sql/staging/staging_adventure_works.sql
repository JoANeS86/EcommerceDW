/*
===================================================================
       Create database EcommerceDW: Staging Schema / Phase 0
===================================================================

-- We're utilizing AdventureWorks2022.bak to restore the database.
-- Once restored, we're adding the staging tables described below.

*/


CREATE SCHEMA Staging;
GO


-- Create staging tables

  
-- Customers staging
CREATE TABLE Staging.AWStgCustomers (
    CustomerID INT PRIMARY KEY,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    EmailAddress NVARCHAR(100),
    Phone NVARCHAR(25),
    ModifiedDate DATETIME
);
GO

  
-- Products staging
IF OBJECT_ID('Staging.AWStgProducts', 'U') IS NOT NULL
    DROP TABLE Staging.AWStgProducts;
GO

CREATE TABLE Staging.AWStgProducts
(
    ProductID              INT,
    Name                    NVARCHAR(50),
    ProductNumber           NVARCHAR(25),
    ProductSubcategoryID    INT NULL,
    Color                   NVARCHAR(15) NULL,
    StandardCost            MONEY,
    ListPrice               MONEY,
    MakeFlag                BIT,
    FinishedGoodsFlag       BIT,
    SafetyStockLevel        SMALLINT,
    ReorderPoint            SMALLINT,
    DaysToManufacture       INT,
    SellStartDate           DATETIME,
    SellEndDate             DATETIME NULL,
    DiscontinuedDate         DATETIME NULL,
    ModifiedDate             DATETIME
);
GO


-- Territories staging
IF OBJECT_ID('Staging.AWStgTerritories', 'U') IS NOT NULL
    DROP TABLE Staging.AWStgTerritories;
GO

CREATE TABLE Staging.AWStgTerritories
(
    TerritoryID         INT PRIMARY KEY,
    Name                 NVARCHAR(50),
    CountryRegionCode    NVARCHAR(3),
    GroupName            NVARCHAR(50),
    ModifiedDate         DATETIME
);
GO


-- Sales staging
IF OBJECT_ID('Staging.AWStgSales', 'U') IS NOT NULL
    DROP TABLE Staging.AWStgSales;
GO

CREATE TABLE Staging.AWStgSales
(
    SalesOrderID    INT NOT NULL,
    ProductID       INT NOT NULL,
    CustomerID      INT NULL,
    TerritoryID     INT NULL,
    OrderDate       DATETIME,
    Quantity        INT,
    LineAmount      MONEY,

    CONSTRAINT PK_StgSales
        PRIMARY KEY (SalesOrderID, ProductID)
);
GO


-- Populate staging tables


INSERT INTO Staging.AWStgCustomers
(
	CustomerID,
	FirstName,
	LastName,
	EmailAddress,
	Phone,
	ModifiedDate
)
SELECT
	c.CustomerID,
    p.FirstName,
    p.LastName,
    e.EmailAddress,
    ph.PhoneNumber,
    c.ModifiedDate
FROM Sales.Customer AS c
JOIN Person.Person AS p ON c.PersonID = p.BusinessEntityID
LEFT JOIN Person.EmailAddress AS e ON p.BusinessEntityID = e.BusinessEntityID
LEFT JOIN Person.PersonPhone AS ph ON p.BusinessEntityID = ph.BusinessEntityID;


INSERT INTO Staging.AWStgProducts
(
    ProductID,
    Name,
    ProductNumber,
    ProductSubcategoryID,
    Color,
    StandardCost,
    ListPrice,
    MakeFlag,
    FinishedGoodsFlag,
    SafetyStockLevel,
    ReorderPoint,
    DaysToManufacture,
    SellStartDate,
    SellEndDate,
    DiscontinuedDate,
    ModifiedDate
)
SELECT
    ProductID,
    Name,
    ProductNumber,
    ProductSubcategoryID,
    Color,
    StandardCost,
    ListPrice,
    MakeFlag,
    FinishedGoodsFlag,
    SafetyStockLevel,
    ReorderPoint,
    DaysToManufacture,
    SellStartDate,
    SellEndDate,
    DiscontinuedDate,
    ModifiedDate
FROM Production.Product;
GO


INSERT INTO Staging.AWStgTerritories
(
    TerritoryID,
    Name,
    CountryRegionCode,
    GroupName,
    ModifiedDate
)
SELECT
    TerritoryID,
    Name,
    CountryRegionCode,
    [Group],
    ModifiedDate
FROM Sales.SalesTerritory;
GO


-- Sales (flattened per line item)
INSERT INTO Staging.AWStgSales
(
    SalesOrderID,
    ProductID,
    CustomerID,
    TerritoryID,
    OrderDate,
    Quantity,
    LineAmount
)
SELECT
    d.SalesOrderID,
    d.ProductID,
    h.CustomerID,
    h.TerritoryID,
    h.OrderDate,
    d.OrderQty,
    d.LineTotal
FROM Sales.SalesOrderDetail AS d
INNER JOIN Sales.SalesOrderHeader AS h
    ON d.SalesOrderID = h.SalesOrderID;
GO


-- Verify


SELECT COUNT(*) FROM Staging.AWStgCustomers;
SELECT COUNT(*) FROM Staging.AWStgProducts;
SELECT COUNT(*) FROM Staging.AWStgTerritories;
SELECT COUNT(*) FROM Staging.AWStgSales;


SELECT TOP 10 * FROM Staging.AWStgCustomers;
SELECT TOP 10 * FROM Staging.AWStgProducts;
SELECT TOP 10 * FROM Staging.AWStgTerritories;
SELECT TOP 10 * FROM Staging.AWStgSales;


-- We're also adding some Placeholder Tables for the rest of the data sources.


-- Orders staging (simulated/API)
CREATE TABLE Staging.APIStgOrders (ID INT);
GO

	
-- Payments staging (simulated/API)
CREATE TABLE Staging.APIStgPayments (ID INT);
GO
	

-- Web events staging (JSON)
CREATE TABLE Staging.JSONStgWebEvents (ID INT);
GO
	

-- Campaigns staging (CSV)
CREATE TABLE Staging.CSVStgCampaigns (ID INT);
GO