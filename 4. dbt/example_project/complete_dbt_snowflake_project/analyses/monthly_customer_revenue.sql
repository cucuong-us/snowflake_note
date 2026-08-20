-- Analysis files compile but are not materialized by `dbt run` or `dbt build`.
-- Use this for exploratory queries that still need ref(), Git and compilation.

select
    date_trunc('month', order_date)::date as revenue_month,
    customer_id,
    count(*) as order_count,
    sum(net_paid_amount) as net_revenue
from {{ ref('fct_orders') }}
where is_paid_order
group by 1, 2
order by 1, 2

