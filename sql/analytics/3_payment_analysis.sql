/*
===================================================================
                        Payment Analysis
===================================================================

*/


-- Payment Success Rate


SELECT
    COUNT(*) AS total_orders,
    SUM(CASE WHEN is_fully_paid = 1 THEN 1 ELSE 0 END) AS fully_paid_orders,
    CAST(SUM(CASE WHEN is_fully_paid = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS success_rate_pct
FROM DW.FactOrders;


-- Failed Payment Impact


SELECT
    has_failed_payment,
    COUNT(*) AS orders,
    AVG(order_amount) AS avg_order_value
FROM DW.FactOrders
GROUP BY has_failed_payment;


-- Payment Gap Analysis


SELECT
    COUNT(*) AS affected_orders,
    AVG(payment_gap) AS avg_gap,
    SUM(payment_gap) AS total_gap
FROM DW.FactOrders
WHERE payment_gap > 0;


-- Multi-payment Behavior


SELECT
    payment_count,
    COUNT(*) AS orders
FROM DW.FactOrders
GROUP BY payment_count
ORDER BY payment_count;