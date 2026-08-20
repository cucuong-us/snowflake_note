with source as (
    select * from {{ source('shop', 'customers') }}
),

renamed as (
    select
        customer_id::number as customer_id,
        trim(first_name)::varchar as first_name,
        trim(last_name)::varchar as last_name,
        lower(trim(email))::varchar as email,
        upper(trim(country_code))::varchar(2) as country_code,
        created_at::timestamp_ntz as created_at,
        updated_at::timestamp_ntz as updated_at,
        _loaded_at::timestamp_ntz as _loaded_at
    from source
)

select * from renamed

