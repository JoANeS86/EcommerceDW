/*
===================================================================
                  Cross System Analytics
===================================================================

*/


-- Total Revenue per Unified Customer
SELECT
    u.api_customer_id,

    SUM(f.order_amount) AS api_revenue,
    SUM(s.sales_amount) AS aw_revenue

FROM Analytics.vw_UnifiedCustomers u

LEFT JOIN DW.FactOrders f
    ON u.customer_key = f.customer_key

LEFT JOIN DW.AWFactSales s
    ON u.aw_customer_id = s.customer_key_aw

GROUP BY u.api_customer_id;