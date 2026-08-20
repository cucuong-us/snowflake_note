{{ config(severity='warn') }}

with expected as (
    select
        order_id,
        sum(line_amount) as expected_amount
    from {{ ref('fct_order_items') }}
    group by order_id
),

actual as (
    select
        order_id,
        gross_order_amount
    from {{ ref('fct_orders') }}
)

select
    actual.order_id,
    actual.gross_order_amount,
    expected.expected_amount
from actual
inner join expected using (order_id)
where abs(actual.gross_order_amount - expected.expected_amount) > 0.01

