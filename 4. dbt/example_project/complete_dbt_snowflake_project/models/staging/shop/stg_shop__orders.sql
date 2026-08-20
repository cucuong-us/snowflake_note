with source as (
    select * from {{ source('shop', 'orders') }}
),

renamed as (
    select
        order_id::number as order_id,
        customer_id::number as customer_id,
        lower(trim(status))::varchar as order_status,
        order_date::date as order_date,
        created_at::timestamp_ntz as created_at,
        updated_at::timestamp_ntz as updated_at,
        _loaded_at::timestamp_ntz as _loaded_at
    from source
    where order_date >= to_date('{{ var("minimum_order_date") }}')
)

select * from renamed

