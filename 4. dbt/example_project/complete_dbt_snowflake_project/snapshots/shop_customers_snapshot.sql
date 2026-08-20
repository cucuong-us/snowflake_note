{% snapshot shop_customers_snapshot %}

{{
    config(
        target_schema='snapshots',
        unique_key='customer_id',
        strategy='timestamp',
        updated_at='updated_at',
        invalidate_hard_deletes=True
    )
}}

select
    customer_id,
    first_name,
    last_name,
    email,
    country_code,
    created_at,
    updated_at
from {{ source('shop', 'customers') }}

{% endsnapshot %}

