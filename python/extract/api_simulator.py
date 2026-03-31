"""
-----------------------------------
 Create Synthetic Orders Generator
-----------------------------------
"""

import random
from datetime import datetime, timedelta
from faker import Faker

fake = Faker()

def generate_orders(n_orders=1000):
    orders = []

    start_date = datetime(2021, 1, 1)
    end_date = datetime(2025, 12, 31)

    for i in range(n_orders):
        order_date = fake.date_time_between(start_date=start_date, end_date=end_date)

        order = {
            "order_id": i + 1,
            "customer_id": random.randint(1, 1000),
            "order_date": order_date,
            "amount": round(random.uniform(10, 500), 2),
            "status": random.choice(["completed", "pending", "cancelled"])
        }

        orders.append(order)

    return orders

"""
-----------------------------------
       Simulate API Response
-----------------------------------
"""

def get_orders_api():
    try:
        data = generate_orders(100000)
        return {"status": "success", "data": data}
    except Exception as e:
        return {"status": "error", "message": str(e)}