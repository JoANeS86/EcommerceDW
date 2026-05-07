/*
===================================================================
                            Web Events
===================================================================

*/


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