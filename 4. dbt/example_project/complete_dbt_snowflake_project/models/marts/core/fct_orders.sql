{{
    config(
        contract={"enforced": true},
        access='public',
        cluster_by=["order_date"],
        tags=["daily"]
    )
}}

with orders as (
    select * from {{ ref('int_orders__enriched') }}
)

select
    order_id,
    customer_id,
    order_status,
    order_date,
    created_at,
    updated_at,
    line_count,
    item_quantity,
    gross_order_amount::number(18, 2) as gross_order_amount,
    paid_amount::number(18, 2) as paid_amount,
    refunded_amount::number(18, 2) as refunded_amount,
    net_paid_amount::number(18, 2) as net_paid_amount,
    last_paid_at,
    failed_payment_count,
    is_paid_order
from orders
