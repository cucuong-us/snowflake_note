with source as (
    select * from {{ source('shop', 'order_items') }}
),

renamed as (
    select
        order_item_id::number as order_item_id,
        order_id::number as order_id,
        product_id::number as product_id,
        quantity::number as quantity,
        unit_price_cents::number as unit_price_cents,
        {{ cents_to_dollars('unit_price_cents') }}::number(18, 2) as unit_price,
        (quantity * {{ cents_to_dollars('unit_price_cents') }})::number(18, 2) as line_amount,
        _loaded_at::timestamp_ntz as _loaded_at
    from source
)

select * from renamed

