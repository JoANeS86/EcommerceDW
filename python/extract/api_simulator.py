"""
-----------------------------------
 Create Synthetic Orders Generator
-----------------------------------
"""

import random
from datetime import datetime
from faker import Faker

fake = Faker()

def generate_orders(n_orders=100000):
    orders = []

    start_date = datetime(2021, 1, 1)
    end_date = datetime(2025, 12, 31)

    for i in range(n_orders):
        order_date = fake.date_time_between(start_date=start_date, end_date=end_date)

        order = {
            "order_id": i + 1,
            "customer_id": random.randint(1, 1000),

            # Inject bad data
            "order_date": random.choices(
                [order_date, None],
                weights=[0.97, 0.03]
            )[0],

            "amount": random.choices([
                round(random.uniform(10, 500), 2),
                -round(random.uniform(1, 100), 2),
                None
                ],
                weights=[0.90, 0.07, 0.03]
            )[0],

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