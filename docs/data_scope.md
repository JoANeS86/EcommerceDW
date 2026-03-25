# Synthetic Data Scope

For testing and analytics purposes, the synthetic datasets will have the following characteristics:

- **Time range:** 2021-01-01 to 2025-12-31
- **Orders volume:** 100,000 to 500,000 orders
- **Payments:** 1 per order attempt
- **Fraud rate:** 2–5% of payments
- **Web events:** Multiple events per order, stored in JSON
- **Campaigns:** CSV files with marketing campaign metadata

## Python Config (optional)
```python
# config/data_scope.py
START_DATE = "2021-01-01"
END_DATE = "2025-12-31"
ORDERS_VOLUME = 500000
FRAUD_RATE = 0.03  # 3%