/*
===================================================================
                          Dimension Date
===================================================================

*/


-- Create DimDate
CREATE TABLE DW.DimDate (
	date_key INT,
	full_date DATE,
	year INT,
	month INT,
	day INT,
);


--Populate DimDate
WITH DateSeries AS (
    SELECT CAST('2010-01-01' AS DATE) AS full_date
    UNION ALL
    SELECT DATEADD(DAY, 1, full_date)
    FROM DateSeries
    WHERE full_date < '2030-12-31'
)
INSERT INTO DW.DimDate (
    date_key,
    full_date,
    year,
    month,
    day
)
SELECT
    CONVERT(INT, FORMAT(full_date, 'yyyyMMdd')),
    full_date,
    YEAR(full_date),
    MONTH(full_date),
    DAY(full_date)
FROM DateSeries
OPTION (MAXRECURSION 0);


/*
===================================================================
                        Dimension Customer
===================================================================

*/


-- Create DimCustomer
CREATE TABLE DW.DimCustomer (
    customer_key INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT,
    customer_name NVARCHAR(100), -- optional (for now fake it)
    source_system NVARCHAR(50),
    created_at DATETIME DEFAULT GETDATE()
);


-- Populate DimCustomer
INSERT INTO DW.DimCustomer
(
    customer_id,
    customer_name,
    source_system
)
SELECT DISTINCT
    o.customer_id,
    'Unknown', -- placeholder
    'API'
FROM Staging.APIStgOrders o
WHERE o.customer_id IS NOT NULL;


/*
-------------------------------------------------------------------
Alter Dim Customer: SCD Type 2
-------------------------------------------------------------------

*/


-- Upgrade DimCustomer
ALTER TABLE DW.DimCustomer
ADD
    valid_from DATETIME,
    valid_to DATETIME,
    is_current BIT;


-- Initialize existing data
UPDATE DW.DimCustomer
SET
    valid_from = GETDATE(),
    valid_to = NULL,
    is_current = 1;


-- SCD Load Procedure
CREATE OR ALTER PROCEDURE DW.SPLoadDimCustomer
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        PRINT 'Loading DimCustomer (SCD Type 2)...';

        -- Insert NEW customers only
        INSERT INTO DW.DimCustomer (
            customer_id,
            customer_name,
            source_system,
            valid_from,
            valid_to,
            is_current
        )
        SELECT DISTINCT
            o.customer_id,
            'Unknown',
            'API',
            '1900-01-01',
            NULL,
            1
        FROM Staging.APIStgOrders o
        LEFT JOIN DW.DimCustomer dc
            ON o.customer_id = dc.customer_id
            AND dc.is_current = 1
        WHERE dc.customer_id IS NULL;

        PRINT 'DimCustomer load completed';

    END TRY
    BEGIN CATCH
        PRINT 'Error loading DimCustomer';
        THROW;
    END CATCH
END;


-- Simulate changes to understand SCD



UPDATE DW.DimCustomer
SET
    valid_to = GETDATE(),
    is_current = 0
WHERE customer_id = 1
  AND is_current = 1;

INSERT INTO DW.DimCustomer (
    customer_id,
    customer_name,
    source_system,
    valid_from,
    valid_to,
    is_current
)
VALUES (1, 'Updated Name', 'API', GETDATE(), NULL, 1);


-- Addition of Unknown Member (to avoid broken joins in real systems)


SET IDENTITY_INSERT DW.DimCustomer ON;

INSERT INTO DW.DimCustomer (
    customer_key,
    customer_id,
    customer_name,
    source_system,
    valid_from,
    valid_to,
    is_current
)
VALUES (-1, -1, 'Unknown', 'System', '1900-01-01', NULL, 1);

SET IDENTITY_INSERT DW.DimCustomer OFF;


/*
===================================================================
                        Dimension Order
===================================================================

*/


-- Create DimOrder
CREATE TABLE DW.DimOrder (
    order_key INT IDENTITY(1,1) PRIMARY KEY,
    order_id VARCHAR(40) NOT NULL
);


INSERT INTO DW.DimOrder (order_id)
SELECT DISTINCT order_id
FROM DW.FactOrders;


ALTER TABLE DW.FactOrders
ADD order_key INT;

ALTER TABLE DW.FactPayments
ADD order_key INT;


UPDATE f
SET f.order_key = d.order_key
FROM DW.FactOrders f
JOIN DW.DimOrder d
    ON f.order_id = d.order_id;


UPDATE f
SET f.order_key = d.order_key
FROM DW.FactPayments f
JOIN DW.DimOrder d
    ON f.order_id = d.order_id;


/*
===================================================================
                  Dimension Marketing Campaign
===================================================================

*/


-- Create DimCampaigns
CREATE TABLE DW.DimCampaign (
    campaign_key INT IDENTITY PRIMARY KEY,
    campaign_id INT NOT NULL,
    channel VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    budget DECIMAL(10,2) NOT NULL
);


-- Populate DimCampaigns
INSERT INTO DW.DimCampaign (campaign_id, channel, start_date, end_date, budget)
SELECT DISTINCT
    campaign_id,
    channel,
    start_date,
    end_date,
    budget
FROM Staging.CSVStgCampaigns sc
WHERE NOT EXISTS (
    SELECT 1
    FROM DW.DimCampaign dc
    WHERE dc.campaign_id = sc.campaign_id
);


/*
===================================================================
                       Adventure Works DW
===================================================================

*/


-- Create AWDimCustomer
CREATE TABLE DW.AWDimCustomer (
    customer_key_aw INT IDENTITY PRIMARY KEY,
    customer_id_aw INT,
    customer_name VARCHAR(100),
    source_system VARCHAR(20) DEFAULT 'AW'
);


-- Populate AWDimCustomer
INSERT INTO DW.AWDimCustomer (
    customer_id_aw,
    customer_name
)
SELECT DISTINCT
    CustomerID,
    FirstName + ' ' + LastName
FROM Staging.AWStgCustomers;


-- Create DimProduct
IF OBJECT_ID('DW.DimProduct', 'U') IS NOT NULL
    DROP TABLE DW.DimProduct;
GO

CREATE TABLE DW.DimProduct
(
    product_key             INT IDENTITY(1,1) PRIMARY KEY,

    product_id              INT NOT NULL,
    product_number          VARCHAR(25),
    product_name            VARCHAR(100),

    category                VARCHAR(50),
    subcategory             VARCHAR(50),

    color                   VARCHAR(30),

    standard_cost           DECIMAL(18,2),
    list_price              DECIMAL(18,2),

    make_flag               BIT,
    finished_goods_flag     BIT,

    days_to_manufacture     INT,

    sell_start_date         DATE,
    sell_end_date           DATE NULL,
    discontinued_date       DATE NULL
);
GO


-- Populate DimProduct
INSERT INTO DW.DimProduct
(
    product_id,
    product_number,
    product_name,
    category,
    subcategory,
    color,
    standard_cost,
    list_price,
    make_flag,
    finished_goods_flag,
    days_to_manufacture,
    sell_start_date,
    sell_end_date,
    discontinued_date
)
SELECT
    p.ProductID,
    p.ProductNumber,
    p.Name,

    pc.Name AS category,
    ps.Name AS subcategory,

    p.Color,

    CAST(p.StandardCost AS DECIMAL(18,2)),
    CAST(p.ListPrice AS DECIMAL(18,2)),

    p.MakeFlag,
    p.FinishedGoodsFlag,

    p.DaysToManufacture,

    CAST(p.SellStartDate AS DATE),
    CAST(p.SellEndDate AS DATE),
    CAST(p.DiscontinuedDate AS DATE)

FROM Staging.AWStgProducts p

LEFT JOIN Production.ProductSubcategory ps
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID

LEFT JOIN Production.ProductCategory pc
    ON ps.ProductCategoryID = pc.ProductCategoryID;
GO


-- Create DimGeography
IF OBJECT_ID('DW.DimGeography', 'U') IS NOT NULL
    DROP TABLE DW.DimGeography;
GO

CREATE TABLE DW.DimGeography
(
    geography_key       INT IDENTITY(1,1) PRIMARY KEY,

    territory_id        INT NOT NULL,
    territory_name      VARCHAR(50),

    country_code        VARCHAR(3),
    region              VARCHAR(50)
);
GO


-- Populate DimGeography
INSERT INTO DW.DimGeography
(
    territory_id,
    territory_name,
    country_code,
    region
)
SELECT
    TerritoryID,
    Name,
    CountryRegionCode,
    GroupName
FROM Staging.AWStgTerritories;
GO