/*
===================================================================
                       Adventure Works DW
===================================================================

*/


-- Create AWDimCustomer
CREATE TABLE DW.AWDimCustomer (
    customer_key_aw INT IDENTITY PRIMARY KEY,
    customer_id_aw INT,
    customer_name VARCHAR(100),
    source_system VARCHAR(20) DEFAULT 'AW'
);


-- Populate AWDimCustomer
INSERT INTO DW.AWDimCustomer (
    customer_id_aw,
    customer_name
)
SELECT DISTINCT
    CustomerID,
    FirstName + ' ' + LastName
FROM Staging.AWStgCustomers;


-- Create DimProduct
CREATE TABLE DW.DimProduct (
    product_key INT IDENTITY PRIMARY KEY,
    product_id INT,
    product_name VARCHAR(100),
    category VARCHAR(50)
);


-- Populate DimProduct
INSERT INTO DW.DimProduct (
    product_id,
    product_name,
    category
)
SELECT DISTINCT
    ProductID,
    Name,
    Color   -- simple proxy for category
FROM Staging.AWStgProducts;


-- Create DimGeography
CREATE TABLE DW.DimGeography (
    geography_key INT IDENTITY PRIMARY KEY,
    country VARCHAR(50),
    region VARCHAR(50)
);


-- Populate DimGeography
INSERT INTO DW.DimGeography (
    country,
    region
)
SELECT DISTINCT
    CountryRegionCode,
    GroupName
FROM Staging.AWStgTerritories;


-- Create AWFactSales
CREATE TABLE DW.AWFactSales (
    sales_id INT IDENTITY PRIMARY KEY,
    customer_key_aw INT,
    product_key INT,
    date_key INT,
    sales_amount DECIMAL(10,2),

    FOREIGN KEY (customer_key_aw) REFERENCES DW.AWDimCustomer(customer_key_aw),
    FOREIGN KEY (product_key) REFERENCES DW.AWDimProduct(product_key),
    FOREIGN KEY (date_key) REFERENCES DW.DimDate(date_key)
);


-- Populate AWFactSales
INSERT INTO DW.AWFactSales (
    customer_key_aw,
    product_key,
    date_key,
    sales_amount
)
SELECT
    dc.customer_key_aw,
    dp.product_key,
    dd.date_key,
    s.LineAmount   -- line-level amount

FROM Staging.AWStgSales s

LEFT JOIN DW.AWDimCustomer dc
    ON s.CustomerID = dc.customer_id_aw

LEFT JOIN DW.DimProduct dp
    ON s.ProductID = dp.product_id

LEFT JOIN DW.DimDate dd
    ON CAST(s.OrderDate AS DATE) = dd.full_date;


-- Validation


-- Row count check (should be similar)
SELECT COUNT(*) FROM DW.AWFactSales;
SELECT COUNT(*) FROM Staging.AWStgSales;


-- Null FK check (Ideally: 0 rows)
SELECT *
FROM DW.FactSales_AW
WHERE customer_key_aw IS NULL
   OR product_key IS NULL
   OR date_key IS NULL;