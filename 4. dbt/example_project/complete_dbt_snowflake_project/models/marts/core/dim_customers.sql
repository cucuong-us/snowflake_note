with customers as (
    select * from {{ ref('stg_shop__customers') }}
),

orders as (
    select * from {{ ref('int_orders__enriched') }}
),

customer_order_metrics as (
    select
        customer_id,
        min(order_date) as first_order_date,
        max(order_date) as most_recent_order_date,
        count(*) as lifetime_order_count,
        sum(net_paid_amount) as lifetime_value
    from orders
    where order_status != 'cancelled'
    group by customer_id
),

final as (
    select
        customers.customer_id,
        customers.first_name,
        customers.last_name,
        customers.first_name || ' ' || customers.last_name as customer_name,
        customers.email,
        customers.country_code,
        customers.created_at,
        customer_order_metrics.first_order_date,
        customer_order_metrics.most_recent_order_date,
        coalesce(customer_order_metrics.lifetime_order_count, 0) as lifetime_order_count,
        coalesce(customer_order_metrics.lifetime_value, 0)::number(18, 2) as lifetime_value,
        case
            when coalesce(customer_order_metrics.lifetime_value, 0) >= 200 then 'high_value'
            when coalesce(customer_order_metrics.lifetime_value, 0) > 0 then 'active'
            else 'prospect'
        end as customer_segment
    from customers
    left join customer_order_metrics using (customer_id)
)

select * from final

