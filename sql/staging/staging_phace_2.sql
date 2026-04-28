/*
===================================================================
                Marketing Campaigns and Web Events
===================================================================

*/


-- CSV: Marketing Campaigns
-- JSON: Web Events (clickstream)


-- Campaigns staging
CREATE TABLE Staging.CSVStgCampaigns (
    campaign_id INT,
    channel VARCHAR(50),
    start_date DATE,
    end_date DATE,
    budget DECIMAL(10,2)
);


-- Web Events staging
CREATE TABLE Staging.JSONStgWebEvents (
    event_id UNIQUEIDENTIFIER,
    customer_id INT,
    event_type VARCHAR(50),
    event_timestamp DATETIME
);