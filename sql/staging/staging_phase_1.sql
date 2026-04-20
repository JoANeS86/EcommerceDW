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


-- Create/Alter staging tables


-- Orders staging (simulated/API)
ALTER TABLE Staging.APIStgOrders
ALTER COLUMN order_id VARCHAR(50);


-- Watermark staging
CREATE TABLE Staging.ETLWatermark (
    pipeline_name VARCHAR(100) PRIMARY KEY,
    last_order_date DATETIME
);


-- Populate Watermark (initial value)
INSERT INTO Staging.ETLWatermark (pipeline_name, last_order_date)
VALUES ('orders_pipeline', '1900-01-01');


-- Orders load staging
CREATE TABLE Staging.APIStgOrdersLoad (
    order_id VARCHAR(50),
    customer_id INT,
    order_date DATETIME,
    amount FLOAT,
    status VARCHAR(50)
);


-- Payments staging
DROP TABLE IF EXISTS Staging.APIStgPayments;

CREATE TABLE Staging.APIStgPayments (
    payment_id UNIQUEIDENTIFIER PRIMARY KEY,
    order_id UNIQUEIDENTIFIER,
    payment_date DATETIME,
    amount DECIMAL(10,2),
    payment_method VARCHAR(50),
    status VARCHAR(50)
);


-- Payments load staging
CREATE TABLE Staging.APIStgPaymentsLoad (
    payment_id UNIQUEIDENTIFIER,
    order_id UNIQUEIDENTIFIER,
    payment_date DATETIME,
    amount DECIMAL(10,2),
    payment_method VARCHAR(50),
    status VARCHAR(50)
);


-- Update Watermark
INSERT INTO Staging.ETLWatermark (pipeline_name, last_order_date)
VALUES ('payments_pipeline', '1900-01-01');