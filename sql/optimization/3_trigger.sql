/*
===================================================================
                             Trigger
===================================================================

*/


-- Audit table


CREATE TABLE DW.FactOrdersAudit (
    audit_id INT IDENTITY PRIMARY KEY,
    order_id UNIQUEIDENTIFIER,
    inserted_at DATETIME DEFAULT GETDATE()
);


-- Trigger


CREATE TRIGGER TRGFactOrdersInsert
ON DW.FactOrders
AFTER INSERT
AS
BEGIN
    INSERT INTO DW.FactOrdersAudit (order_id)
    SELECT order_id
    FROM inserted;
END;