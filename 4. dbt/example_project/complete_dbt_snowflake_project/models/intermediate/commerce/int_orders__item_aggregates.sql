with order_items as (
    select * from {{ ref('stg_shop__order_items') }}
),

aggregated as (
    select
        order_id,
        count(*) as line_count,
        sum(quantity) as item_quantity,
        sum(line_amount) as gross_order_amount
    from order_items
    group by order_id
)

select * from aggregated

