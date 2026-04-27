/*
===================================================================
                  Data Quality & Fraud Signals
===================================================================

*/


-- Suspicious Orders


SELECT *
FROM DW.FactOrders
WHERE payment_gap > 100
   OR (has_failed_payment = 1 AND is_fully_paid = 0);


-- Unknown Customers Usage


SELECT
    COUNT(*) AS unknown_orders
FROM DW.FactOrders
WHERE customer_key = -1;


-- Late-arriving Data Impact (buffer validation)


SELECT
    COUNT(*) AS recent_orders
FROM DW.FactOrders f
JOIN DW.DimDate d ON f.date_key = d.date_key
WHERE d.full_date >= DATEADD(DAY, -3, GETDATE());