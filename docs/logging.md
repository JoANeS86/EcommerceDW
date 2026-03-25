# Logging Strategy

All pipelines will write logs to the `/logs` folder:

- `logs/orders_pipeline.log` → Orders ingestion
- `logs/payments_pipeline.log` → Payments ingestion (future)
- `logs/web_events_pipeline.log` → Web Events ingestion (future)

Logging will capture:
- Start and end times
- Number of records processed
- Any errors or warnings

## Optional Python Logger Template
```python
# python/utils/logger.py
import logging
import os

LOG_DIR = os.path.join(os.path.dirname(__file__), "../../logs")
os.makedirs(LOG_DIR, exist_ok=True)

def get_logger(name, log_file):
    logger = logging.getLogger(name)
    logger.setLevel(logging.INFO)

    file_handler = logging.FileHandler(os.path.join(LOG_DIR, log_file))
    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    file_handler.setFormatter(formatter)

    if not logger.handlers:
        logger.addHandler(file_handler)

    return logger

# Usage in a pipeline:
# logger = get_logger("orders_pipeline", "orders_pipeline.log")
# logger.info("Pipeline started")