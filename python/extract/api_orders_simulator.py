"""
-----------------------------------
 Create Synthetic Orders Generator
-----------------------------------
"""

import random
from datetime import datetime
from faker import Faker
import uuid

fake = Faker()

# -----------------------------------
# CUSTOMER COHORT SETUP (NEW)
# -----------------------------------

NUM_CUSTOMERS = 2000

start_date = datetime(2021, 1, 1)
end_date = datetime(2025, 12, 31)

# Create customer "signup dates" spread across time
customer_signup = {}

for cid in range(1, NUM_CUSTOMERS + 1):

    # Skew slightly toward earlier customers (more realistic adoption curve)
    signup_date = fake.date_time_between(
        start_date=start_date,
        end_date=end_date
    )

    customer_signup[cid] = signup_date


def generate_orders(n_orders=200000):
    orders = []

    duplicate_id = str(uuid.uuid4())  # fixed duplicate

    customer_ids = list(customer_signup.keys())

    for i in range(n_orders):

        # pick customer
        customer_id = random.choice(customer_ids)

        # enforce lifecycle constraint (IMPORTANT FIX)
        signup_date = customer_signup[customer_id]

        # order must happen AFTER signup date
        order_date = fake.date_time_between(
            start_date=signup_date,
            end_date=end_date
        )

        order = {
            "order_id": duplicate_id if i % 5000 == 0 else str(uuid.uuid4()),

            "customer_id": customer_id,

            "order_date": random.choices(
                [order_date, None],
                weights=[0.97, 0.03]
            )[0],

            "amount": random.choices([
                round(random.uniform(10, 500), 2),
                -round(random.uniform(1, 100), 2),
                None
            ],
            weights=[0.90, 0.07, 0.03])[0],

            "status": random.choices(
                ["completed", "pending", "cancelled", None],
                weights=[0.70, 0.15, 0.10, 0.05]
            )[0]
        }

        orders.append(order)

    return orders


"""
-----------------------------------
       Simulate API Response
-----------------------------------
"""

def get_orders_api():
    # Simulate API failure (20% chance)
    if random.random() < 0.2:
        return {"status": "error", "message": "Simulated API failure"}

    try:
        data = generate_orders()
        return {"status": "success", "data": data}
    except Exception as e:
        return {"status": "error", "message": str(e)}