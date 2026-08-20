{{
    config(
        materialized='incremental',
        unique_key='revenue_date',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        cluster_by=['revenue_date']
    )
}}

with orders as (
    select *
    from {{ ref('fct_orders') }}

    {% if is_incremental() %}
        where order_date >= dateadd(
            day,
            -{{ var('order_lookback_days') }},
            (select coalesce(max(revenue_date), '1900-01-01'::date) from {{ this }})
        )
    {% endif %}
),

daily as (
    select
        order_date as revenue_date,
        count(*) as order_count,
        count_if(is_paid_order) as paid_order_count,
        sum(gross_order_amount)::number(18, 2) as gross_order_amount,
        sum(net_paid_amount)::number(18, 2) as net_revenue,
        {{ safe_divide('sum(net_paid_amount)', 'count_if(is_paid_order)') }}::number(18, 2) as average_paid_order_value,
        current_timestamp()::timestamp_ntz as dbt_updated_at
    from orders
    where order_status != 'cancelled'
    group by order_date
)

select * from daily

