"""
-----------------------------------
Create Synthetic Payments Generator
-----------------------------------
"""

import random
import uuid
from datetime import datetime
from faker import Faker
from sqlalchemy import text
from config.db_config import engine

fake = Faker()


# -----------------------------------
# FETCH REAL ORDER IDS
# -----------------------------------

def get_real_orders(sample_size=50000):
    query = text(f"""
        SELECT TOP ({sample_size}) order_id, order_date
        FROM Staging.APIStgOrders
        ORDER BY NEWID()
    """)

    with engine.connect() as conn:
        result = conn.execute(query).fetchall()

    return [{"order_id": row[0], "order_date": row[1]} for row in result]


# -----------------------------------
# GENERATE PAYMENTS
# -----------------------------------

def generate_payments(n_payments=100000):
    payments = []

    real_orders = get_real_orders()

    payment_methods = ["credit_card", "paypal", "bank_transfer"]
    statuses = ["completed", "failed", "refunded"]

    start_date = datetime(2000, 1, 1)
    end_date = datetime(2025, 12, 31)

    for i in range(n_payments):

        if random.random() < 0.8 and real_orders:
            order = random.choice(real_orders)
            order_id = order["order_id"]

            # Ensure payment_date >= order_date
            payment_date = fake.date_time_between(
                start_date=order["order_date"],
                end_date=end_date
            )
        else:
            order_id = str(uuid.uuid4())
            payment_date = fake.date_time_between(start_date=start_date, end_date=end_date)

        amount = random.uniform(10, 500)

        # Inject bad data
        amount = random.choices(
            [
                round(amount, 2),                 # valid
                -round(random.uniform(1, 100), 2), # negative
                None                              # null
            ],
            weights=[0.90, 0.05, 0.05]
        )[0]

        payment = {
            "payment_id": str(uuid.uuid4()),
            "order_id": order_id,

            "payment_date": random.choices(
                [payment_date, None],
                weights=[0.95, 0.05]
            )[0],

            "amount": amount,

            "payment_method": random.choice(payment_methods),

            "status": random.choice(statuses)
        }

        payments.append(payment)

    return payments


# -----------------------------------
# SIMULATE API RESPONSE
# -----------------------------------

def get_payments_api():
    # 20% failure rate (same as orders)
    if random.random() < 0.2:
        return {"status": "error", "message": "Simulated API failure"}

    try:
        data = generate_payments()
        return {"status": "success", "data": data}
    except Exception as e:
        return {"status": "error", "message": str(e)}