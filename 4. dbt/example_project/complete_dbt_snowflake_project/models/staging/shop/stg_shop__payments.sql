with source as (
    select * from {{ source('shop', 'payments') }}
),

renamed as (
    select
        payment_id::number as payment_id,
        order_id::number as order_id,
        lower(trim(payment_method))::varchar as payment_method,
        lower(trim(payment_status))::varchar as payment_status,
        {{ cents_to_dollars('amount_cents') }}::number(18, 2) as payment_amount,
        paid_at::timestamp_ntz as paid_at,
        _loaded_at::timestamp_ntz as _loaded_at
    from source
)

select * from renamed

