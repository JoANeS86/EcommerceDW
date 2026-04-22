/*
===================================================================
                       Core Business KPIs
===================================================================

*/


-- Revenue, Orders, Customers


SELECT
    COUNT(*) AS total_orders,
    SUM(order_amount) AS total_revenue,
    AVG(order_amount) AS avg_order_value,
    COUNT(DISTINCT customer_key) AS total_customers
FROM DW.FactOrders;


-- Daily Business Trend


SELECT
    d.full_date,
    COUNT(*) AS orders,
    SUM(f.order_amount) AS revenue
FROM DW.FactOrders f
JOIN DW.DimDate d ON f.date_key = d.date_key
GROUP BY d.full_date
ORDER BY d.full_date;


-- Monthly Growth


SELECT
    d.year,
    d.month,
    SUM(f.order_amount) AS revenue,
    LAG(SUM(f.order_amount)) OVER (ORDER BY d.year, d.month) AS prev_month,
    SUM(f.order_amount) - LAG(SUM(f.order_amount)) OVER (ORDER BY d.year, d.month) AS growth
FROM DW.FactOrders f
JOIN DW.DimDate d ON f.date_key = d.date_key
GROUP BY d.year, d.month
ORDER BY d.year, d.month;