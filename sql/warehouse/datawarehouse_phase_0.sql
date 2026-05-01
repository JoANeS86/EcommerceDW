/*
===================================================================
                        Data Warehouse
===================================================================

*/


CREATE SCHEMA DW;
GO


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


-- Create Fact Table
CREATE TABLE DW.FactOrders (
    order_id UNIQUEIDENTIFIER PRIMARY KEY,
    customer_id INT,
    order_date DATETIME,
    order_amount DECIMAL(10,2),
    total_paid_amount DECIMAL(10,2),
    payment_count INT,
    has_failed_payment BIT
);


-- Create Fact Orders Store Procedure
CREATE PROCEDURE DW.SPLoadFactOrders
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        PRINT 'Starting FactOrders load...';

        TRUNCATE TABLE DW.FactOrders;

        INSERT INTO DW.FactOrders (
            order_id,
            customer_id,
            order_date,
            order_amount,
            total_paid_amount,
            payment_count,
            has_failed_payment
        )
        SELECT
            o.order_id,
            o.customer_id,
            o.order_date,
            o.amount,

            ISNULL(p.total_paid_amount, 0),
            ISNULL(p.payment_count, 0),
            ISNULL(p.has_failed_payment, 0)

        FROM Staging.APIStgOrders o

        LEFT JOIN (
            SELECT
                order_id,
                SUM(amount) AS total_paid_amount,
                COUNT(*) AS payment_count,
                MAX(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) AS has_failed_payment
            FROM Staging.APIStgPayments
            GROUP BY order_id
        ) p
            ON o.order_id = p.order_id;

        PRINT 'FactOrders load completed';

    END TRY
    BEGIN CATCH
        PRINT 'Error loading FactOrders';
        THROW;
    END CATCH
END;


-- Execute Store Procedure
EXEC DW.SPLoadFactOrders;


-- Check Store Procedure Result
SELECT TOP 100 * FROM DW.FactOrders;


-- Sanity Checks


-- Should match number of orders
SELECT COUNT(*) FROM DW.FactOrders;
SELECT COUNT(*) FROM Staging.APIStgOrders;


-- Payments logic
SELECT *
FROM DW.FactOrders
WHERE payment_count > 1;


-- Failed payments flag
SELECT *
FROM DW.FactOrders
WHERE has_failed_payment = 1;


/*
-------------------------------------------------------------------
Current FactOrders table problems:

    - customer_id = operational key (not stable in real systems)
    - order_date = raw datetime (not reusable)
    - No historical tracking possible
    - Not optimized for analytics
-------------------------------------------------------------------

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


-- Redesign Fact Table
DROP TABLE IF EXISTS DW.FactOrders;

CREATE TABLE DW.FactOrders (
    order_id UNIQUEIDENTIFIER PRIMARY KEY,
    customer_key INT,
    date_key INT,
    order_amount DECIMAL(10,2),
    total_paid_amount DECIMAL(10,2),
    payment_count INT,
    has_failed_payment BIT
);


-- Create Fact Orders Store Procedure (v2)
CREATE OR ALTER PROCEDURE DW.SPLoadFactOrders
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        PRINT 'Starting FactOrders load...';

        TRUNCATE TABLE DW.FactOrders;

        INSERT INTO DW.FactOrders (
            order_id,
            customer_key,
            date_key,
            order_amount,
            total_paid_amount,
            payment_count,
            has_failed_payment
        )
        SELECT
            o.order_id,
            ISNULL(dc.customer_key, -1),
            dd.date_key,
            o.amount,
            ISNULL(p.total_paid_amount, 0),
            ISNULL(p.payment_count, 0),
            ISNULL(p.has_failed_payment, 0)

        FROM Staging.APIStgOrders o

        -- Customer dimension
        LEFT JOIN DW.DimCustomer dc
            ON o.customer_id = dc.customer_id
            AND o.order_date >= dc.valid_from
            AND (
                dc.valid_to IS NULL
                OR o.order_date < dc.valid_to
            )

        -- Date dimension
        INNER JOIN DW.DimDate dd
            ON CAST(o.order_date AS DATE) = dd.full_date

        -- Payments aggregation
        LEFT JOIN (
            SELECT
                order_id,
                SUM(amount) AS total_paid_amount,
                COUNT(*) AS payment_count,
                MAX(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) AS has_failed_payment
            FROM Staging.APIStgPayments
            GROUP BY order_id
        ) p
            ON o.order_id = p.order_id;

        PRINT 'FactOrders load completed';

    END TRY
    BEGIN CATCH
        PRINT 'Error loading FactOrders';
        THROW;
    END CATCH
END;


-- Execute Store Procedure
EXEC DW.SPLoadFactOrders;


-- Validation


SELECT TOP 100 * FROM DW.FactOrders;


-- No Null Keys
SELECT *
FROM DW.FactOrders
WHERE customer_key IS NULL OR date_key IS NULL;


-- Join Sanity
SELECT COUNT(*) FROM DW.FactOrders;
SELECT COUNT(*) FROM Staging.APIStgOrders;