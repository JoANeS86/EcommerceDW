/*
===================================================================
                      Unified Fact Views
===================================================================

*/


-- Create Unified Orders
CREATE VIEW Analytics.VwOrders AS
SELECT
    f.order_key,
	f.order_id,
	u.unified_customer_key,
	f.customer_key,
	f.date_key,
    f.order_amount,
	f.total_paid_amount,
	f.payment_count,
	f.has_failed_payment,
	f.order_count,
	f.is_fully_paid,
	f.payment_gap
FROM DW.FactOrders f
JOIN DW.DimCustomer dc
    ON f.customer_key = dc.customer_key
JOIN DW.DimCustomerUnified u
    ON dc.customer_key = u.api_customer_key;


-- Create Orders Dim View
CREATE VIEW Analytics.VwOrdersDim AS
SELECT DISTINCT
    order_key,
    order_id
FROM DW.FactOrders;


-- Create Payments View
CREATE OR ALTER VIEW Analytics.VwPayments AS
SELECT
    payment_id,
    payment_reference,
    order_key,
    order_id,
    date_key,
    payment_amount,
    payment_method,
    payment_status
FROM DW.FactPayments;


-- Create Unified Fact Web Events
CREATE VIEW Analytics.VwWebEvents AS
SELECT
    we.*,
    u.unified_customer_key
FROM DW.FactWebEvents we
JOIN DW.DimCustomer dc
    ON we.customer_key = dc.customer_key
JOIN DW.DimCustomerUnified u
    ON dc.customer_key = u.api_customer_key;


-- Create Unified AW Sales
CREATE OR ALTER VIEW Analytics.VwAWSales
AS
SELECT
    s.*,
    u.unified_customer_key

FROM DW.AWFactSales AS s

LEFT JOIN DW.AWDimCustomer AS aw
    ON s.customer_key_aw = aw.customer_key_aw

LEFT JOIN DW.DimCustomerUnified AS u
    ON aw.customer_key_aw = u.aw_customer_key;
GO