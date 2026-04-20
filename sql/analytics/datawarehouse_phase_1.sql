/*
===================================================================
                         SCD Type 2
===================================================================

*/


-- Alter DimCustomer


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


-- Data Validation (not just SQL, also Business Logic)


-- No duplicates (critical)
SELECT order_id, COUNT(*)
FROM DW.FactOrders
GROUP BY order_id
HAVING COUNT(*) > 1;


-- Payments consistency
SELECT *
FROM DW.FactOrders
WHERE total_paid_amount < 0;


-- Business sanity
SELECT *
FROM DW.FactOrders
WHERE payment_count = 0 AND total_paid_amount > 0;


--  Onlye one current record per customer
SELECT customer_id, COUNT(*)
FROM DW.DimCustomer
WHERE is_current = 1
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- Validity ranges makes sense
SELECT *
FROM DW.DimCustomer
WHERE valid_to IS NOT NULL AND valid_to < valid_from;


-- Customer integrity
SELECT *
FROM DW.FactOrders f
LEFT JOIN DW.DimCustomer dc
    ON f.customer_key = dc.customer_key
WHERE dc.customer_key IS NULL;


-- Date integrity
SELECT *
FROM DW.FactOrders f
LEFT JOIN DW.DimDate d
    ON f.date_key = d.date_key
WHERE d.date_key IS NULL;


/*
Addition of Optional Metrics

    - Make your Fact table analytically powerful
    - Show business thinking, not just engineering

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