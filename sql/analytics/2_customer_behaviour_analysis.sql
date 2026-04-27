/*
===================================================================
                    Customer Behavior Analysis
===================================================================

*/


-- Customer Lifetime Value (CLV)


CREATE VIEW Analytics.VwCustomerLifetimeValue AS
SELECT
    customer_key,
    COUNT(*) AS total_orders,
    SUM(order_amount) AS lifetime_value,
    AVG(order_amount) AS avg_order_value
FROM DW.FactOrders
GROUP BY customer_key;


-- Repeat vs One-time Customers


WITH customer_orders AS (
    SELECT
        customer_key,
        COUNT(*) AS order_count
    FROM DW.FactOrders
    GROUP BY customer_key
)
SELECT
    CASE 
        WHEN order_count = 1 THEN 'One-time'
        ELSE 'Repeat'
    END AS customer_type,
    COUNT(*) AS customers
FROM customer_orders
GROUP BY
    CASE 
        WHEN order_count = 1 THEN 'One-time'
        ELSE 'Repeat'
    END;


-- Time Between Orders (Retention proxy)


WITH ordered AS (
    SELECT
        customer_key,
        d.full_date,
        LAG(d.full_date) OVER (
            PARTITION BY customer_key
            ORDER BY d.full_date
        ) AS prev_order_date
    FROM DW.FactOrders f
    JOIN DW.DimDate d ON f.date_key = d.date_key
)
SELECT
    customer_key,
    AVG(DATEDIFF(DAY, prev_order_date, full_date)) AS avg_days_between_orders
FROM ordered
WHERE prev_order_date IS NOT NULL
GROUP BY customer_key;