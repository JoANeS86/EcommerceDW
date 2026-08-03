/*
===================================================================
                      Conformed Dimension
===================================================================

*/


-- Create DW.DimCustomerUnified
CREATE TABLE DW.DimCustomerUnified (
    unified_customer_key INT IDENTITY PRIMARY KEY,
    api_customer_key INT NULL,
    aw_customer_key INT NULL,
    source_system VARCHAR(20),
    match_confidence DECIMAL(3,2),
    created_at DATETIME2 DEFAULT GETDATE()
);


-- Populate 1: DW.DimCustomerUnified (Matched customers - From mapping)
INSERT INTO DW.DimCustomerUnified (
    api_customer_key,
    aw_customer_key,
    source_system,
    match_confidence
)
SELECT
    m.api_customer_key,
    m.aw_customer_key,
    'MATCHED',
    m.match_confidence
FROM DW.CustomerMapping m;


-- Populate 2: DW.DimCustomerUnified (API)
INSERT INTO DW.DimCustomerUnified (
    api_customer_key,
    source_system,
    match_confidence
)
SELECT
    dc.customer_key,
    'API_ONLY',
    NULL
FROM DW.DimCustomer dc
WHERE NOT EXISTS (
    SELECT 1
    FROM DW.CustomerMapping m
    WHERE m.api_customer_key = dc.customer_key
);


-- Populate 3: DW.DimCustomerUnified (AW)
INSERT INTO DW.DimCustomerUnified (
    aw_customer_key,
    source_system,
    match_confidence
)
SELECT
    aw.customer_key_aw,
    'AW_ONLY',
    NULL
FROM DW.AWDimCustomer aw
WHERE NOT EXISTS (
    SELECT 1
    FROM DW.CustomerMapping m
    WHERE m.aw_customer_key = aw.customer_key_aw
);