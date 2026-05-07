/*
===================================================================
                      Marketing Campaigns
===================================================================

*/


-- Campaigns staging
CREATE TABLE Staging.CSVStgCampaigns (
    campaign_id INT,
    channel VARCHAR(50),
    start_date DATE,
    end_date DATE,
    budget DECIMAL(10,2)
);