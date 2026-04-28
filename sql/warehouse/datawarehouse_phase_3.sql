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
    campaign_id INT,
    channel VARCHAR(50),
    start_date DATE,
    end_date DATE,
    budget DECIMAL(10,2)
);


-- Create FactWebEvents
CREATE TABLE DW.FactWebEvents (
    event_id UNIQUEIDENTIFIER PRIMARY KEY,
    customer_key INT,
    date_key INT,
    event_type VARCHAR(50),
    event_count INT DEFAULT 1,
    FOREIGN KEY (customer_key) REFERENCES DW.DimCustomer(customer_key),
    FOREIGN KEY (date_key) REFERENCES DW.DimDate(date_key)
);