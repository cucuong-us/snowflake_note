{{ config(severity='error') }}

select
    order_id,
    order_status,
    paid_amount
from {{ ref('fct_orders') }}
where is_paid_order
  and paid_amount <= 0

