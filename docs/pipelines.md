# First Pipeline: Orders Ingestion

## Objective
Generate synthetic orders data, simulate API responses, validate it, and load into the staging table `APIStgOrders`.

## Steps
1. Generate synthetic orders in Python
2. Simulate API response
3. Validate the data (check required fields, date ranges, volumes)
4. Load the data into `Staging.APIStgOrders` in SQL Server

## Notes
- Pipeline will log progress and errors into `logs/orders_pipeline.log`
- Designed for reuse with other synthetic datasets (Payments, Web Events, Campaigns)