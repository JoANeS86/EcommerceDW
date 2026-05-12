/*
===================================================================
                         SCD Type 2
===================================================================

*/


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


--  Only one current record per customer
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