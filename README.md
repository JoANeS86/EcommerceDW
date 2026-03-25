# EcommerceDW Project

## Business Model
- **Order**: customer buys product(s)
- **Payment**: transaction attempt
- **Sale**: successful payment

## Data Sources
- AdventureWorks database for core tables (Customers, Products, Sales, Territories)
- Synthetic/API data for Orders, Payments, Web Events, Campaigns

## Project Structure
    EcommerceDW
        data/          # Raw data files, CSVs, JSONs, backups
        logs/          # Pipeline logs
        python/        # Python scripts for ETL
            extract/ → code to extract data from APIs or simulators
            transform/` → data cleaning and transformation
            load/ → load data into SQL Server
            utils/ → reusable functions, logging
            config/ → configuration files
        sql/           # SQL scripts (staging tables, DW tables, etc.)
        tests/         # Unit tests and pipeline tests
        docs/          # Project documentation (data scope, pipeline scope, logging)
        README.md      # Project documentation

## Tech Stack
- Python 3.14
- SQL Server LocalDB
- SQLAlchemy + pyodbc

## Documentation
- **Synthetic Data Scope:** [docs/data_scope.md](docs/data_scope.md)
- **Pipeline Scope:** [docs/pipelines.md](docs/pipelines.md)
- **Logging Strategy:** [docs/logging.md](docs/logging.md)