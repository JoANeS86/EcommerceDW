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
CREATE TABLE DW.DimProduct (
    product_key INT IDENTITY PRIMARY KEY,
    product_id INT,
    product_name VARCHAR(100),
    category VARCHAR(50)
);


-- Populate DimProduct
INSERT INTO DW.DimProduct (
    product_id,
    product_name,
    category
)
SELECT DISTINCT
    ProductID,
    Name,
    Color   -- simple proxy for category
FROM Staging.AWStgProducts;


-- Create DimGeography
CREATE TABLE DW.DimGeography (
    geography_key INT IDENTITY PRIMARY KEY,
    country VARCHAR(50),
    region VARCHAR(50)
);


-- Populate DimGeography
INSERT INTO DW.DimGeography (
    country,
    region
)
SELECT DISTINCT
    CountryRegionCode,
    GroupName
FROM Staging.AWStgTerritories;