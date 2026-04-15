## EcommerceDW Project

EcommerceDW is a production-style data engineering project that simulates a real-world e-commerce platform.

It focuses on building scalable ETL pipelines, handling data quality issues, and designing a data warehouse for analytics.

---

### Business Model
- **Order**: customer buys product(s)
- **Payment**: transaction attempt
- **Sale**: successful payment

---

### Data Sources

#### 1. AdventureWorks (SQL Server)

* Customers
* Products
* Sales
* Territories

#### 2. Synthetic / API Data

* Orders (core entity)
* Payments (linked to orders)
* Web Events *(planned)*
* Campaigns *(planned)*

---

### Architecture

The platform is structured into multiple layers:

* **Staging Layer**

  Raw data ingestion from APIs and external sources

* **ETL Pipelines (Python)**

  Data extraction, validation, and incremental loading

* **Data Warehouse Layer (in progress)**
  
  Star schema design (Facts + Dimensions) for analytics

---

### Key Features

* **Incremental processing**

  * Watermark-based filtering
  * 3-day buffer for late-arriving data

* **Data quality validation**

  * Null handling
  * Duplicate removal
  * Invalid value filtering

* **Referential integrity**

  * Payments validated against existing orders

* **SQL MERGE loading strategy**

  * Staging → final tables
  * Insert-only incremental loads

* **Observability**

  * Logging of record counts and pipeline steps
  * API retry logic and error handling

* **Real-world simulation**

  * API failures
  * Bad data injection
  * Inconsistent relationships

---

### Project Structure

```
EcommerceDW/
│
├── data/          # Raw data files (CSV, JSON, backups)
├── logs/          # Pipeline logs
├── python/        # ETL pipelines
│   ├── extract/   # API simulators
│   ├── transform/ # Data validation & cleaning
│   ├── load/      # Load logic (MERGE, watermark)
│   ├── utils/     # Logging and helpers
│   └── config/    # Database configuration
│
├── sql/           # SQL scripts (staging, DW)
├── tests/         # Pipeline tests
├── docs/          # Documentation
└── README.md
```

---

### Tech Stack

* Python 3.14
* SQL Server (LocalDB)
* SQLAlchemy + pyodbc

---

### Current Status

    ✅ Orders pipeline (complete)
    ✅ Payments pipeline (complete)
    🚧 Data Warehouse layer (in progress)

---

### Documentation
- **Synthetic Data Scope:** [docs/data_scope.md](docs/data_scope.md)
- **Pipeline Scope:** [docs/pipelines.md](docs/pipelines.md)
- **Logging Strategy:** [docs/logging.md](docs/logging.md)

---

### Next Steps

* Build **FactOrders** table
* Design **dimension tables**
* Add **analytics use cases** (cohorts, fraud detection)
