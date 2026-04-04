/*
===================================================================
       Create database EcommerceDW: Staging Schema / Phase 1
===================================================================

-- We're utilizing AdventureWorks2022.bak to restore the database.
-- In this Phase 1, we're applying some updates and continuing to create new tables.

*/


/*
After some updates, Python code is now generating order_id = str(uuid.uuid4())  # string (varchar),
but SQL table expects order_id BIGINT
*/


-- Alter staging tables


-- Orders staging (simulated/API)
ALTER TABLE Staging.APIStgOrders
ALTER COLUMN order_id VARCHAR(50);


-- Create staging tables


-- Watermark staging
CREATE TABLE Staging.ETL_Watermark (
    pipeline_name VARCHAR(100) PRIMARY KEY,
    last_order_date DATETIME
);


-- Populate Watermark (initial value)
INSERT INTO Staging.ETL_Watermark (pipeline_name, last_order_date)
VALUES ('orders_pipeline', '1900-01-01');