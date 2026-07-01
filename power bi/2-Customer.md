### <ins>Measures</ins>

    Total Customers = DISTINCTCOUNT(Customers[unified_customer_key])

    Repeat Customers = 
CALCULATE(
    DISTINCTCOUNT(Orders[unified_customer_key]),
    FILTER(
        VALUES(Orders[unified_customer_key]),
        CALCULATE(COUNT(Orders[order_id])) > 1
    )
)

    Repeat Rate = DIVIDE([Repeat Customers], [Total Customers])
