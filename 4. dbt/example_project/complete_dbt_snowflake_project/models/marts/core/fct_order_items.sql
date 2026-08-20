with order_items as (
    select * from {{ ref('stg_shop__order_items') }}
),

orders as (
    select order_id, customer_id, order_date, order_status
    from {{ ref('stg_shop__orders') }}
),

products as (
    select product_id, unit_cost
    from {{ ref('stg_shop__products') }}
)

select
    order_items.order_item_id,
    order_items.order_id,
    orders.customer_id,
    order_items.product_id,
    orders.order_date,
    orders.order_status,
    order_items.quantity,
    order_items.unit_price,
    products.unit_cost,
    order_items.line_amount,
    (order_items.quantity * products.unit_cost)::number(18, 2) as line_cost,
    (order_items.line_amount - order_items.quantity * products.unit_cost)::number(18, 2) as gross_margin
from order_items
inner join orders using (order_id)
inner join products using (product_id)

