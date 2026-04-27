/*
===================================================================
            Indexed View (SQL Server "Materialized View")
===================================================================

*/


-- Monthly Revenue


CREATE VIEW Analytics.VwMonthlyRevenue
WITH SCHEMABINDING
AS
SELECT
    d.year,
    d.month,
    COUNT_BIG(*) AS order_count,
    SUM(ISNULL(f.order_amount, 0)) AS total_revenue  -- Use ISNULL to handle nullable values
FROM DW.FactOrders f
JOIN DW.DimDate d ON f.date_key = d.date_key
GROUP BY d.year, d.month;


/*
SSMS will physically store the data for the view once you create a unique clustered index on it.
This transforms your view into an indexed view (similar to a materialized view), and SQL Server will
store the aggregated results in the database.

Without the unique clustered index, it would remain just a regular view (which does not store data).

Also, SQL Server doesn't allow creating an indexed view (materialized view) on a SUM aggregate
when the column being summed is nullable. This is because nullable columns can result in NULL values,
which complicates the calculation for the index (that's why we've used "SUM(ISNULL())").
*/


CREATE UNIQUE CLUSTERED INDEX IXVwMonthlyRevenue
ON Analytics.VwMonthlyRevenue(year, month);