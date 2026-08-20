with source as (
    select * from {{ source('shop', 'products') }}
),

renamed as (
    select
        product_id::number as product_id,
        trim(product_name)::varchar as product_name,
        lower(trim(category))::varchar as product_category,
        {{ cents_to_dollars('unit_cost_cents') }}::number(18, 2) as unit_cost,
        created_at::timestamp_ntz as created_at,
        updated_at::timestamp_ntz as updated_at,
        _loaded_at::timestamp_ntz as _loaded_at
    from source
)

select * from renamed

