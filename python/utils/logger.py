"""
-----------------------------------
             Logging
-----------------------------------
"""

import logging

def get_logger(name):
    logging.basicConfig(
        filename='logs/orders_pipeline.log',
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
    return logging.getLogger(name)