/*
===================================================================
                              Indexes
===================================================================

*/


-- Without index: Full table scan, Expensive window function
-- With index: Ordered access, Much faster partitioning


-- FactOrders Indexes


-- Customer analysis
CREATE NONCLUSTERED INDEX IXFactOrdersCustomer
ON DW.FactOrders(customer_key);

-- Time series analysis
CREATE NONCLUSTERED INDEX IXFactOrdersDate
ON DW.FactOrders(date_key);

-- Composite Index
CREATE NONCLUSTERED INDEX IXFactOrdersCustomerDate
ON DW.FactOrders(customer_key, date_key);

-- Payment analysis
CREATE NONCLUSTERED INDEX IXFactOrdersPaymentFlags
ON DW.FactOrders(is_fully_paid, has_failed_payment);

-- Dimension Index
CREATE NONCLUSTERED INDEX IXDimCustomerBusinessKey
ON DW.DimCustomer(customer_id, valid_from, valid_to);


-- Fact Web Events Indexes


CREATE NONCLUSTERED INDEX IXFactWebEventsCustomer
ON DW.FactWebEvents(customer_key);

CREATE NONCLUSTERED INDEX IXFactWebEventsDate
ON DW.FactWebEvents(date_key);

CREATE NONCLUSTERED INDEX IXFactWebEventsEventType
ON DW.FactWebEvents(event_type);