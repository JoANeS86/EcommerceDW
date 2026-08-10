"""
Create Synthetic Payments Generator
"""

import random
import uuid
from datetime import datetime, timedelta

from faker import Faker
from sqlalchemy import text

from config.db_config import engine

fake = Faker()

# ============================================================

# CONFIGURATION

# ============================================================

START_DATE = datetime(2021, 1, 1)
END_DATE = datetime(2025, 12, 31)

# Percentage of generated payments linked to real orders

REAL_ORDER_RATE = 0.80

# Payment/order relationship

SINGLE_PAYMENT_RATE = 0.75
MULTIPLE_PAYMENT_RATE = 0.20
MULTI_ORDER_PAYMENT_RATE = 0.05

# Bad-data injection

NULL_PAYMENT_DATE_RATE = 0.05
NEGATIVE_AMOUNT_RATE = 0.05
NULL_AMOUNT_RATE = 0.05

# ============================================================

# FETCH REAL ORDERS

# ============================================================

def get_real_orders(sample_size=100000):


    query = text(f"""
        SELECT TOP ({sample_size})
            order_id,
            order_date,
            amount
        FROM Staging.APIStgOrders
        WHERE order_id IS NOT NULL
        ORDER BY NEWID()
    """)

    with engine.connect() as conn:
        result = conn.execute(query).fetchall()

    return [
        {
            "order_id": row[0],
            "order_date": row[1],
            "amount": row[2]
        }
        for row in result
    ]


# ============================================================

# PAYMENT METHOD

# ============================================================

def choose_payment_method(order_amount):


    methods = [
        "credit_card",
        "paypal",
        "bank_transfer",
        "debit_card",
        "apple_pay"
    ]

    # High-value orders:
    # bank transfer becomes more likely.
    if order_amount is not None and order_amount > 250:

        weights = [
            0.40,  # credit_card
            0.10,  # paypal
            0.40,  # bank_transfer
            0.07,  # debit_card
            0.03   # apple_pay
        ]

    # Low-value orders:
    # digital/card payments dominate.
    elif order_amount is not None and order_amount < 50:

        weights = [
            0.55,  # credit_card
            0.30,  # paypal
            0.03,  # bank_transfer
            0.10,  # debit_card
            0.02   # apple_pay
        ]

    # Normal orders
    else:

        weights = [
            0.55,  # credit_card
            0.25,  # paypal
            0.10,  # bank_transfer
            0.07,  # debit_card
            0.03   # apple_pay
        ]

    return random.choices(
        methods,
        weights=weights,
        k=1
    )[0]


# ============================================================

# PAYMENT STATUS

# ============================================================

def choose_payment_status(is_retry=False):


    # Retries are more likely to succeed.
    if is_retry:

        return random.choices(
            [
                "completed",
                "failed",
                "pending",
                "refunded"
            ],
            weights=[
                0.92,
                0.05,
                0.02,
                0.01
            ],
            k=1
        )[0]

    return random.choices(
        [
            "completed",
            "failed",
            "pending",
            "refunded"
        ],
        weights=[
            0.88,
            0.08,
            0.01,
            0.03
        ],
        k=1
    )[0]


# ============================================================

# PAYMENT DATE

# ============================================================

def generate_payment_date(order_date):


    if order_date is None:

        return fake.date_time_between(
            start_date=START_DATE,
            end_date=END_DATE
        )

    # Most payments happen close to the order date.
    delay_days = random.choices(
        [
            random.randint(0, 1),
            random.randint(2, 3),
            random.randint(4, 14),
            random.randint(15, 60)
        ],
        weights=[
            0.60,
            0.25,
            0.10,
            0.05
        ],
        k=1
    )[0]

    payment_date = order_date + timedelta(
        days=delay_days
    )

    if payment_date > END_DATE:
        payment_date = END_DATE

    return payment_date


# ============================================================

# PAYMENT AMOUNT

# ============================================================

def generate_single_payment_amount(order_amount):


    # No order amount available.
    if order_amount is None:

        return round(
            random.uniform(10, 500),
            2
        )

    scenario = random.choices(
        [
            "exact",
            "underpayment",
            "overpayment"
        ],
        weights=[
            0.80,
            0.10,
            0.10
        ],
        k=1
    )[0]

    if scenario == "exact":

        # Small natural variation around the order value.
        variation = random.uniform(
            0.98,
            1.02
        )

        return round(
            order_amount * variation,
            2
        )

    if scenario == "underpayment":

        variation = random.uniform(
            0.50,
            0.95
        )

        return round(
            order_amount * variation,
            2
        )

    # overpayment

    variation = random.uniform(
        1.05,
        1.30
    )

    return round(
        order_amount * variation,
        2
    )


# ============================================================

# SPLIT ORDER AMOUNT INTO MULTIPLE PAYMENTS

# ============================================================

def generate_multiple_payment_amounts(
order_amount,
number_of_payments
):


    if order_amount is None:

        return [
            round(
                random.uniform(10, 500),
                2
            )
            for _ in range(number_of_payments)
        ]

    # Randomly split the order amount.
    weights = [
        random.uniform(0.5, 1.5)
        for _ in range(number_of_payments)
    ]

    total_weight = sum(weights)

    amounts = [
        round(
            order_amount * weight / total_weight,
            2
        )
        for weight in weights
    ]

    # Correct rounding difference on final payment.
    difference = round(
        order_amount - sum(amounts),
        2
    )

    amounts[-1] = round(
        amounts[-1] + difference,
        2
    )

    return amounts


# ============================================================

# BAD DATA INJECTION

# ============================================================

def inject_bad_amount(amount):


    return random.choices(
        [
            amount,
            -round(random.uniform(1, 100), 2),
            None
        ],
        weights=[
            0.90,
            NEGATIVE_AMOUNT_RATE,
            NULL_AMOUNT_RATE
        ],
        k=1
    )[0]


# ============================================================

# CREATE PAYMENT

# ============================================================

def create_payment(
order_id,
order_date,
order_amount,
payment_amount,
payment_reference=None,
is_retry=False
):


    payment_date = generate_payment_date(
        order_date
    )

    payment_method = choose_payment_method(
        order_amount
    )

    status = choose_payment_status(
        is_retry=is_retry
    )

    # Inject intentionally bad amount data.
    payment_amount = inject_bad_amount(
        payment_amount
    )

    # Inject intentionally missing payment dates.
    payment_date = random.choices(
        [
            payment_date,
            None
        ],
        weights=[
            1 - NULL_PAYMENT_DATE_RATE,
            NULL_PAYMENT_DATE_RATE
        ],
        k=1
    )[0]

    return {
        "payment_id": str(uuid.uuid4()),
        "payment_reference": payment_reference,
        "order_id": order_id,
        "payment_date": payment_date,
        "amount": payment_amount,
        "payment_method": payment_method,
        "status": status
    }


# ============================================================

# GENERATE PAYMENTS

# ============================================================

def generate_payments(n_payments=200000):


    payments = []

    real_orders = get_real_orders()

    if not real_orders:
        raise ValueError(
            "No real orders were retrieved."
        )

    # --------------------------------------------------------
    # Keep track of orders already selected for multiple
    # payment scenarios.
    # --------------------------------------------------------

    shuffled_orders = real_orders.copy()
    random.shuffle(shuffled_orders)

    order_index = 0

    while len(payments) < n_payments:

        # ====================================================
        # MULTI-ORDER PAYMENT
        # ====================================================

        if (
            random.random() < MULTI_ORDER_PAYMENT_RATE
            and order_index + 2 < len(shuffled_orders)
        ):

            number_of_orders = random.randint(2, 3)

            selected_orders = shuffled_orders[
                order_index:
                order_index + number_of_orders
            ]

            order_index += number_of_orders

            payment_reference = (
                "TX-" + str(uuid.uuid4())
            )

            # One real-world transaction covering
            # several orders.
            total_amount = sum(
                order["amount"]
                for order in selected_orders
                if order["amount"] is not None
                and order["amount"] > 0
            )

            if total_amount <= 0:
                total_amount = round(
                    random.uniform(50, 500),
                    2
                )

            for order in selected_orders:

                if len(payments) >= n_payments:
                    break

                order_amount = order["amount"]

                if (
                    order_amount is not None
                    and order_amount > 0
                ):
                    allocated_amount = round(
                        total_amount
                        * order_amount
                        / sum(
                            o["amount"]
                            for o in selected_orders
                            if o["amount"] is not None
                            and o["amount"] > 0
                        ),
                        2
                    )
                else:
                    allocated_amount = round(
                        random.uniform(10, 100),
                        2
                    )

                payment = create_payment(
                    order_id=order["order_id"],
                    order_date=order["order_date"],
                    order_amount=order_amount,
                    payment_amount=allocated_amount,
                    payment_reference=payment_reference
                )

                payments.append(payment)

            continue

        # ====================================================
        # SELECT AN ORDER
        # ====================================================

        if (
            random.random() < REAL_ORDER_RATE
            and order_index < len(shuffled_orders)
        ):

            order = random.choice(real_orders)

            order_id = order["order_id"]
            order_date = order["order_date"]
            order_amount = order["amount"]

        else:

            # Payment without a corresponding real order.
            order_id = str(uuid.uuid4())

            order_date = fake.date_time_between(
                start_date=START_DATE,
                end_date=END_DATE
            )

            order_amount = round(
                random.uniform(10, 500),
                2
            )

        # ====================================================
        # SINGLE VS MULTIPLE PAYMENTS
        # ====================================================

        relationship = random.choices(
            [
                "single",
                "multiple"
            ],
            weights=[
                SINGLE_PAYMENT_RATE,
                MULTIPLE_PAYMENT_RATE
            ],
            k=1
        )[0]

        # ====================================================
        # SINGLE PAYMENT
        # ====================================================

        if relationship == "single":

            payment_amount = (
                generate_single_payment_amount(
                    order_amount
                )
            )

            payment = create_payment(
                order_id=order_id,
                order_date=order_date,
                order_amount=order_amount,
                payment_amount=payment_amount
            )

            payments.append(payment)

        # ====================================================
        # MULTIPLE PAYMENTS
        # ====================================================

        else:

            number_of_payments = random.randint(
                2,
                4
            )

            payment_amounts = (
                generate_multiple_payment_amounts(
                    order_amount,
                    number_of_payments
                )
            )

            payment_reference = (
                "TX-" + str(uuid.uuid4())
            )

            for index, payment_amount in enumerate(
                payment_amounts
            ):

                if len(payments) >= n_payments:
                    break

                payment = create_payment(
                    order_id=order_id,
                    order_date=order_date,
                    order_amount=order_amount,
                    payment_amount=payment_amount,
                    payment_reference=payment_reference,
                    is_retry=(index > 0)
                )

                payments.append(payment)

    return payments[:n_payments]


# ============================================================

# SIMULATE API RESPONSE

# ============================================================

def get_payments_api():


    # 20% simulated API failure.
    if random.random() < 0.20:

        return {
            "status": "error",
            "message": "Simulated API failure"
        }

    try:

        data = generate_payments()

        return {
            "status": "success",
            "data": data
        }

    except Exception as e:

        return {
            "status": "error",
            "message": str(e)
        }