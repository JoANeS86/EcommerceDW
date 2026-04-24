/*
===================================================================
                        Cohort Analysis
===================================================================

*/


-- Assign Cohort (first order month)


WITH first_order AS (
    SELECT
        customer_key,
        MIN(d.full_date) AS first_order_date
    FROM DW.FactOrders f
    JOIN DW.DimDate d ON f.date_key = d.date_key
    GROUP BY customer_key
)
SELECT * FROM first_order;


-- Cohort table


WITH first_order AS (
    SELECT
        customer_key,
        MIN(d.full_date) AS first_order_date
    FROM DW.FactOrders f
    JOIN DW.DimDate d ON f.date_key = d.date_key
    GROUP BY customer_key
),
cohort_data AS (
    SELECT
        f.customer_key,
        d.full_date AS order_date,
        fo.first_order_date,
        DATEDIFF(MONTH, fo.first_order_date, d.full_date) AS cohort_month
    FROM DW.FactOrders f
    JOIN DW.DimDate d ON f.date_key = d.date_key
    JOIN first_order fo ON f.customer_key = fo.customer_key
)
SELECT
    FORMAT(first_order_date, 'yyyy-MM') AS cohort,
    cohort_month,
    COUNT(DISTINCT customer_key) AS active_customers
FROM cohort_data
GROUP BY FORMAT(first_order_date, 'yyyy-MM'), cohort_month
ORDER BY cohort, cohort_month;


-- Retention %


WITH cohort_size AS (
    SELECT
        FORMAT(first_order_date, 'yyyy-MM') AS cohort,
        COUNT(DISTINCT customer_key) AS cohort_size
    FROM (
        SELECT
            f.customer_key,
            MIN(d.full_date) AS first_order_date
        FROM DW.FactOrders f
        JOIN DW.DimDate d ON f.date_key = d.date_key
        GROUP BY f.customer_key
    ) x
    GROUP BY FORMAT(first_order_date, 'yyyy-MM')
),
cohort_retention AS (
    -- reuse previous cohort_data logic
    SELECT
        FORMAT(first_order_date, 'yyyy-MM') AS cohort,
        cohort_month,
        COUNT(DISTINCT customer_key) AS active_customers
    FROM (
        SELECT
            f.customer_key,
            d.full_date,
            MIN(d.full_date) OVER (PARTITION BY f.customer_key) AS first_order_date,
            DATEDIFF(MONTH,
                MIN(d.full_date) OVER (PARTITION BY f.customer_key),
                d.full_date
            ) AS cohort_month
        FROM DW.FactOrders f
        JOIN DW.DimDate d ON f.date_key = d.date_key
    ) x
    GROUP BY FORMAT(first_order_date, 'yyyy-MM'), cohort_month
)
SELECT
    r.cohort,
    r.cohort_month,
    r.active_customers,
    CAST(r.active_customers * 100.0 / c.cohort_size AS DECIMAL(5,2)) AS retention_pct
FROM cohort_retention r
JOIN cohort_size c ON r.cohort = c.cohort
ORDER BY r.cohort, r.cohort_month;