"""
-----------------------------------
   Synthetic Web Events Generator
-----------------------------------
"""

import uuid
import random
from datetime import datetime
from faker import Faker

fake = Faker()

def generate_web_events(n=100000):
    events = []
    real_orders = get_real_orders()

    for order in real_orders:
        customer_id = order["customer_id"]
        order_date = order["order_date"]

        # Pre-order events
        events.append({
            "event_id": str(uuid.uuid4()),
            "customer_id": customer_id,
            "event_type": "page_view",
            "event_timestamp": order_date - timedelta(days=random.randint(1,5))
        })

        events.append({
            "event_id": str(uuid.uuid4()),
            "customer_id": customer_id,
            "event_type": "add_to_cart",
            "event_timestamp": order_date - timedelta(hours=2)
        })

        # Conversion event
        events.append({
            "event_id": str(uuid.uuid4()),
            "customer_id": customer_id,
            "event_type": "checkout",
            "event_timestamp": order_date
        })