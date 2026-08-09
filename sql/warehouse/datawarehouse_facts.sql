/*
===================================================================
                            Fact Orders
===================================================================

*/


CREATE SCHEMA DW;
GO


-- Create Fact Orders Table
CREATE TABLE DW.FactOrders (
    order_id UNIQUEIDENTIFIER PRIMARY KEY,
    customer_id INT,
    order_date DATETIME,
    order_amount DECIMAL(10,2),
    total_paid_amount DECIMAL(10,2),
    payment_count INT,
    has_failed_payment BIT
);


-- Create Fact Orders Stored Procedure
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


-- Execute Stored Procedure
EXEC DW.SPLoadFactOrders;


-- Check Stored Procedure Result
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


-- Create Fact Orders Stored Procedure (v2)
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


-- Execute Stored Procedure
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


/*
-------------------------------------------------------------------
Addition of Optional Metrics

    - Make your Fact table analytically powerful
    - Show business thinking, not just engineering
-------------------------------------------------------------------

*/


ALTER TABLE DW.FactOrders
ADD 
    order_count AS (1) PERSISTED,
    is_fully_paid AS (
        CASE 
            WHEN total_paid_amount >= order_amount THEN 1
            ELSE 0
        END
    ) PERSISTED,
    payment_gap AS (
        order_amount - total_paid_amount
    ) PERSISTED;


/*
-------------------------------------------------------------------
Right now the Fact load is TRUNCATE + INSERT:

    - That’s fine for development
    - But completely unrealistic in production

New Stored Procedure updates the Fact table incrementally,
just like the pipelines.
-------------------------------------------------------------------

*/


-- Reuse Staging.ETLWatermark (add new row)


INSERT INTO Staging.ETLWatermark (pipeline_name, last_processed_datetime)
VALUES ('fact_orders_load', '1900-01-01');


-- Update Fact Orders Stored Procedure (Incremental)


CREATE OR ALTER PROCEDURE DW.SPLoadFactOrdersIncremental
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @watermark DATETIME;
        DECLARE @adjusted_watermark DATETIME;
        DECLARE @buffer_days INT = 3;

        -- Get watermark
        SELECT @watermark = last_processed_datetime
        FROM Staging.ETLWatermark
        WHERE pipeline_name = 'fact_orders_load';

        SET @adjusted_watermark = DATEADD(DAY, -@buffer_days, @watermark);

        PRINT 'Watermark: ' + CAST(@watermark AS VARCHAR);
        PRINT 'Adjusted watermark: ' + CAST(@adjusted_watermark AS VARCHAR);

        -- Build incremental dataset
        WITH OrdersIncremental AS (
            SELECT
                order_id,
                customer_id,
                order_date,
                amount,
                status
            FROM Staging.APIStgOrders
            WHERE order_date > @adjusted_watermark
        ),

        PaymentsAgg AS (
            SELECT
                order_id,
                SUM(amount) AS total_paid_amount,
                COUNT(*) AS payment_count,
                MAX(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) AS has_failed_payment
            FROM Staging.APIStgPayments
            GROUP BY order_id
        )

        MERGE DW.FactOrders AS target
        USING (
            SELECT
                o.order_id,
                ISNULL(dc.customer_key, -1) AS customer_key,
                dd.date_key,
                o.amount AS order_amount,

                ISNULL(p.total_paid_amount, 0) AS total_paid_amount,
                ISNULL(p.payment_count, 0) AS payment_count,
                ISNULL(p.has_failed_payment, 0) AS has_failed_payment

            FROM OrdersIncremental o

            LEFT JOIN DW.DimCustomer dc
                ON o.customer_id = dc.customer_id
                AND o.order_date >= dc.valid_from
                AND (
                    dc.valid_to IS NULL
                    OR o.order_date < dc.valid_to
                )

            INNER JOIN DW.DimDate dd
                ON CAST(o.order_date AS DATE) = dd.full_date

            LEFT JOIN PaymentsAgg p
                ON o.order_id = p.order_id
        ) AS source

        ON target.order_id = source.order_id

        WHEN MATCHED THEN
            UPDATE SET
                customer_key = source.customer_key,
                date_key = source.date_key,
                order_amount = source.order_amount,
                total_paid_amount = source.total_paid_amount,
                payment_count = source.payment_count,
                has_failed_payment = source.has_failed_payment

        WHEN NOT MATCHED THEN
            INSERT (
                order_id,
                customer_key,
                date_key,
                order_amount,
                total_paid_amount,
                payment_count,
                has_failed_payment
            )
            VALUES (
                source.order_id,
                source.customer_key,
                source.date_key,
                source.order_amount,
                source.total_paid_amount,
                source.payment_count,
                source.has_failed_payment
            );

        -- Update watermark
        UPDATE Staging.ETLWatermark
        SET last_processed_datetime = (
            SELECT MAX(order_date)
            FROM Staging.APIStgOrders
        )
        WHERE pipeline_name = 'fact_orders_load';

        PRINT 'Incremental FactOrders load completed';

    END TRY
    BEGIN CATCH
        PRINT 'Error in incremental FactOrders load';
        THROW;
    END CATCH
END;


-- Execute Fact Orders Stored Procedure (Incremental)


EXEC DW.SPLoadFactOrdersIncremental;


/*
===================================================================
                            Fact Payments
===================================================================

*/


-- Create Fact Orders Table
CREATE TABLE DW.FactPayments (
    payment_id UNIQUEIDENTIFIER PRIMARY KEY,
    order_id UNIQUEIDENTIFIER,
    date_key INT,
    payment_amount DECIMAL(10,2),
    payment_method VARCHAR(50),
    payment_status VARCHAR(50)
);


-- Reuse Staging.ETLWatermark (add new row)


INSERT INTO Staging.ETLWatermark (pipeline_name, last_processed_datetime)
VALUES ('fact_payments_load', '1900-01-01');


-- Update Fact Payments Stored Procedure (Incremental)


CREATE OR ALTER PROCEDURE DW.SPLoadFactPaymentsIncremental
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        DECLARE @watermark DATETIME;
        DECLARE @adjusted_watermark DATETIME;
        DECLARE @buffer_days INT = 3;

        -- Get watermark
        SELECT @watermark = last_processed_datetime
        FROM Staging.ETLWatermark
        WHERE pipeline_name = 'fact_payments_load';

        SET @adjusted_watermark = DATEADD(DAY, -@buffer_days, @watermark);

        PRINT 'Watermark: ' + CAST(@watermark AS VARCHAR);
        PRINT 'Adjusted watermark: ' + CAST(@adjusted_watermark AS VARCHAR);

        -- Build incremental dataset
        WITH PaymentsIncremental AS (
            SELECT
                payment_id,
                order_id,
                payment_date,
                amount,
                payment_method,
                status
            FROM Staging.APIStgPayments
            WHERE payment_date > @adjusted_watermark
        )

        MERGE DW.FactPayments AS target
        USING (
            SELECT
                p.payment_id,
                p.order_id,
                dd.date_key,
                p.amount AS payment_amount,
		        p.payment_method,
		        p.status AS payment_status

            FROM PaymentsIncremental p

            INNER JOIN DW.DimDate dd
                ON CAST(p.payment_date AS DATE) = dd.full_date

        ) AS source

        ON target.payment_id = source.payment_id

        WHEN MATCHED THEN
            UPDATE SET
                order_id = source.order_id,
                date_key = source.date_key,
                payment_amount = source.payment_amount,
                payment_method = source.payment_method,
                payment_status = source.payment_status

        WHEN NOT MATCHED THEN
            INSERT (
                payment_id,
                order_id,
                date_key,
                payment_amount,
                payment_method,
                payment_status
            )
            VALUES (
                source.payment_id,
                source.order_id,
                source.date_key,
                source.payment_amount,
                source.payment_method,
                source.payment_status
            );

        -- Update watermark
        UPDATE Staging.ETLWatermark
        SET last_processed_datetime = (
            SELECT MAX(payment_date)
            FROM Staging.APIStgPayments
        )
        WHERE pipeline_name = 'fact_payments_load';

        PRINT 'Incremental FactPayments load completed';

    END TRY
    BEGIN CATCH
        PRINT 'Error in incremental FactPayments load';
        THROW;
    END CATCH
END;


-- Execute Fact Payments Stored Procedure (Incremental)


EXEC DW.SPLoadFactPaymentsIncremental;


/*
===================================================================
                          Fact Web Events
===================================================================

*/


-- Create FactWebEvents
CREATE TABLE DW.FactWebEvents (
    event_id UNIQUEIDENTIFIER PRIMARY KEY,
    customer_key INT NOT NULL,
    order_id UNIQUEIDENTIFIER NULL,
    event_type VARCHAR(50) NOT NULL,
    event_timestamp DATETIME2 NOT NULL,
    date_key INT NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (customer_key) REFERENCES DW.DimCustomer(customer_key),
    FOREIGN KEY (date_key) REFERENCES DW.DimDate(date_key)
);


-- Populate FactWebEvents
INSERT INTO DW.FactWebEvents (
    event_id,
    customer_key,
    order_id,
    event_type,
    event_timestamp,
    date_key
)
SELECT
    we.event_id,
    ISNULL(dc.customer_key, -1),
    we.order_id,
    we.event_type,
    we.event_timestamp,
    dd.date_key
FROM Staging.JSONStgWebEvents we
LEFT JOIN DW.DimCustomer dc
    ON we.customer_id = dc.customer_id
    AND we.event_timestamp >= dc.valid_from
    AND we.event_timestamp < ISNULL(dc.valid_to, '9999-12-31')
LEFT JOIN DW.DimDate dd
    ON CAST(we.event_timestamp AS DATE) = dd.full_date
WHERE NOT EXISTS (
    SELECT 1
    FROM DW.FactWebEvents f
    WHERE f.event_id = we.event_id
);


/*
===================================================================
                          AW Fact Sales
===================================================================

*/


-- Create AWFactSales
IF OBJECT_ID('DW.AWFactSales', 'U') IS NOT NULL
    DROP TABLE DW.AWFactSales;
GO

CREATE TABLE DW.AWFactSales
(
    sales_id            INT IDENTITY(1,1) PRIMARY KEY,

    sales_order_id      INT NOT NULL,

    customer_key_aw     INT,
    product_key         INT,
    date_key            INT,
    geography_key       INT,

    quantity            INT,
    sales_amount        DECIMAL(12,2),

    CONSTRAINT FK_AWFactSales_Customer
        FOREIGN KEY (customer_key_aw)
        REFERENCES DW.AWDimCustomer(customer_key_aw),

    CONSTRAINT FK_AWFactSales_Product
        FOREIGN KEY (product_key)
        REFERENCES DW.DimProduct(product_key),

    CONSTRAINT FK_AWFactSales_Date
        FOREIGN KEY (date_key)
        REFERENCES DW.DimDate(date_key),

    CONSTRAINT FK_AWFactSales_Geography
        FOREIGN KEY (geography_key)
        REFERENCES DW.DimGeography(geography_key)
);
GO


-- Populate AWFactSales
INSERT INTO DW.AWFactSales
(
    sales_order_id,
    customer_key_aw,
    product_key,
    date_key,
    geography_key,
    quantity,
    sales_amount
)
SELECT
    s.SalesOrderID,

    dc.customer_key_aw,

    dp.product_key,

    dd.date_key,

    dg.geography_key,

    s.Quantity,

    CAST(s.LineAmount AS DECIMAL(12,2))

FROM Staging.AWStgSales AS s

LEFT JOIN DW.AWDimCustomer AS dc
    ON s.CustomerID = dc.customer_id_aw

LEFT JOIN DW.DimProduct AS dp
    ON s.ProductID = dp.product_id

LEFT JOIN DW.DimDate AS dd
    ON CAST(s.OrderDate AS DATE) = dd.full_date

LEFT JOIN DW.DimGeography AS dg
    ON s.TerritoryID = dg.territory_id;
GO


-- Validation


-- Row count check (should be similar)
SELECT COUNT(*) FROM DW.AWFactSales;
SELECT COUNT(*) FROM Staging.AWStgSales;


-- Null FK check (Ideally: 0 rows)
SELECT *
FROM DW.FactSalesAW
WHERE customer_key_aw IS NULL
   OR product_key IS NULL
   OR date_key IS NULL;