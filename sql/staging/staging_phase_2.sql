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
    order_id UNIQUEIDENTIFIER NULL,
    customer_id INT,
    event_type VARCHAR(50),
    event_timestamp DATETIME
);


-- Web Events load staging
CREATE TABLE Staging.JSONStgWebEventsLoad (
    event_id UNIQUEIDENTIFIER,
    order_id UNIQUEIDENTIFIER NULL,
    customer_id INT NOT NULL,
    event_type NVARCHAR(50),
    event_timestamp DATETIME
);