/*
===================================================================
                      Unified Fact Views
===================================================================

*/


-- Create Unified Orders
CREATE VIEW Analytics.VwOrders AS
SELECT
    f.*,
    u.unified_customer_key
FROM DW.FactOrders f
JOIN DW.DimCustomer dc
    ON f.customer_key = dc.customer_key
JOIN DW.DimCustomerUnified u
    ON dc.customer_id = u.api_customer_id;


-- Create Unified Fact Web Events
CREATE VIEW Analytics.VwWebEvents AS
SELECT
    we.*,
    u.unified_customer_key
FROM DW.FactWebEvents we
JOIN DW.DimCustomer dc
    ON we.customer_key = dc.customer_key
JOIN DW.DimCustomerUnified u
    ON dc.customer_id = u.api_customer_id;


-- Create Unified AW Sales
CREATE VIEW Analytics.VwAWSales AS
SELECT
    s.*,
    u.unified_customer_key
FROM DW.AWFactSales s
JOIN DW.AWDimCustomer aw
    ON s.customer_key_aw = aw.customer_key_aw
JOIN DW.DimCustomerUnified u
    ON aw.customer_id_aw = u.aw_customer_id;