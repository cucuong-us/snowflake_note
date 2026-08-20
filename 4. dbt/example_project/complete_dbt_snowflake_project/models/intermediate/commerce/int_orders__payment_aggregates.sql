with payments as (
    select * from {{ ref('stg_shop__payments') }}
),

aggregated as (
    select
        order_id,
        sum(case when payment_status = 'succeeded' then payment_amount else 0 end) as paid_amount,
        sum(case when payment_status = 'refunded' then payment_amount else 0 end) as refunded_amount,
        max(case when payment_status = 'succeeded' then paid_at end) as last_paid_at,
        count_if(payment_status = 'failed') as failed_payment_count
    from payments
    group by order_id
)

select * from aggregated

