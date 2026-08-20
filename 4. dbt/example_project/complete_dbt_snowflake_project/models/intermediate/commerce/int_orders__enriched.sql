with orders as (
    select * from {{ ref('stg_shop__orders') }}
),

item_aggregates as (
    select * from {{ ref('int_orders__item_aggregates') }}
),

payment_aggregates as (
    select * from {{ ref('int_orders__payment_aggregates') }}
),

enriched as (
    select
        orders.order_id,
        orders.customer_id,
        orders.order_status,
        orders.order_date,
        orders.created_at,
        orders.updated_at,
        coalesce(item_aggregates.line_count, 0) as line_count,
        coalesce(item_aggregates.item_quantity, 0) as item_quantity,
        coalesce(item_aggregates.gross_order_amount, 0) as gross_order_amount,
        coalesce(payment_aggregates.paid_amount, 0) as paid_amount,
        coalesce(payment_aggregates.refunded_amount, 0) as refunded_amount,
        coalesce(payment_aggregates.paid_amount, 0)
            - coalesce(payment_aggregates.refunded_amount, 0) as net_paid_amount,
        payment_aggregates.last_paid_at,
        coalesce(payment_aggregates.failed_payment_count, 0) as failed_payment_count,
        orders.order_status in ('paid', 'shipped', 'completed') as is_paid_order
    from orders
    left join item_aggregates using (order_id)
    left join payment_aggregates using (order_id)
)

select * from enriched

