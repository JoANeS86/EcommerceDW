/*
===================================================================
                Marketing Campaigns and Web Events
===================================================================

*/


-- CSV: Marketing Campaigns
-- JSON: Web Events (clickstream)


-- Create DimCampaigns
CREATE TABLE DW.DimCampaign (
    campaign_key INT IDENTITY PRIMARY KEY,
    campaign_id INT NOT NULL,
    channel VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    budget DECIMAL(10,2) NOT NULL
);


-- Populate DimCampaigns
INSERT INTO DW.DimCampaign (campaign_id, channel, start_date, end_date, budget)
SELECT DISTINCT
    campaign_id,
    channel,
    start_date,
    end_date,
    budget
FROM Staging.CSVStgCampaigns sc
WHERE NOT EXISTS (
    SELECT 1
    FROM DW.DimCampaign dc
    WHERE dc.campaign_id = sc.campaign_id
);


-- Create FactWebEvents
CREATE TABLE DW.FactWebEvents (
    event_id UNIQUEIDENTIFIER PRIMARY KEY,
    customer_key INT NOT NULL,
    order_id UNIQUEIDENTIFIER NULL,
    event_type VARCHAR(50) NOT NULL,
    event_timestamp DATETIME2 NOT NULL,
    date_key INT NOT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (customer_key) REFERENCES DW.DimCustomer(customer_key),
    FOREIGN KEY (date_key) REFERENCES DW.DimDate(date_key)
);


-- Populate FactWebEvents
INSERT INTO DW.FactWebEvents (
    event_id,
    customer_key,
    order_id,
    event_type,
    event_timestamp,
    date_key
)
SELECT
    we.event_id,
    ISNULL(dc.customer_key, -1),
    we.order_id,
    we.event_type,
    we.event_timestamp,
    dd.date_key
FROM Staging.JSONStgWebEvents we
LEFT JOIN DW.DimCustomer dc
    ON we.customer_id = dc.customer_id
    AND we.event_timestamp >= dc.valid_from
    AND we.event_timestamp < ISNULL(dc.valid_to, '9999-12-31')
LEFT JOIN DW.DimDate dd
    ON CAST(we.event_timestamp AS DATE) = dd.full_date
WHERE NOT EXISTS (
    SELECT 1
    FROM DW.FactWebEvents f
    WHERE f.event_id = we.event_id
);