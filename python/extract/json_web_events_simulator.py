"""
-----------------------------------
   Synthetic Web Events Generator
-----------------------------------
"""

import uuid
import random
from datetime import timedelta
from faker import Faker
from sqlalchemy import text
from python.config.db_config import engine

fake = Faker()

# -----------------------------------
# FETCH REAL ORDERS (SOURCE SYSTEM)
# -----------------------------------
def get_real_orders():
    query = text("""
        SELECT
            order_id,
            customer_id,
            order_date
        FROM Staging.APIStgOrders
        WHERE order_date IS NOT NULL
    """)

    with engine.connect() as conn:
        result = conn.execute(query).fetchall()

    return [
        {
            "order_id": row[0],
            "customer_id": row[1],
            "order_date": row[2]
        }
        for row in result
    ]


# -----------------------------------
# ORDER-BASED JOURNEY EVENTS
# -----------------------------------
def generate_order_events(orders):
    events = []

    for order in orders:
        order_id = order["order_id"]
        customer_id = order["customer_id"]
        order_date = order["order_date"]

        # PAGE VIEWS
        n_page_views = random.choices(
            [1, 2, 3, 4, 5, 6, 7, 8],
            weights=[35, 25, 15, 10, 6, 5, 3, 1]
        )[0]

        for _ in range(n_page_views):
            events.append({
                "event_id": str(uuid.uuid4()),
                "order_id": order_id,
                "customer_id": customer_id,
                "event_type": "page_view",
                "event_timestamp": order_date - timedelta(
                    hours=random.randint(1, 72)
                )
            })

        # ADD TO CART
        if random.random() < 0.75:
            events.append({
                "event_id": str(uuid.uuid4()),
                "order_id": order_id,
                "customer_id": customer_id,
                "event_type": "add_to_cart",
                "event_timestamp": order_date - timedelta(
                    hours=random.randint(1, 6)
                )
            })

            # CHECKOUT
            if random.random() < 0.55:
                events.append({
                    "event_id": str(uuid.uuid4()),
                    "order_id": order_id,
                    "customer_id": customer_id,
                    "event_type": "checkout",
                    "event_timestamp": order_date
                })

    return events


# -----------------------------------
# ORPHAN EVENTS
# -----------------------------------
def generate_orphan_events(n=30000):
    events = []

    event_types = ["page_view", "add_to_cart"]

    for _ in range(n):
        events.append({
            "event_id": str(uuid.uuid4()),
            "order_id": None,
            "customer_id": random.randint(1, 3000),
            "event_type": random.choice(event_types),
            "event_timestamp": fake.date_time_between(
                start_date="-45d",
                end_date="now"
            )
        })

    return events


# -----------------------------------
# MAIN GENERATOR
# -----------------------------------
def generate_web_events():
    orders = get_real_orders()

    events = []
    events.extend(generate_order_events(orders))
    events.extend(generate_orphan_events())

    return events