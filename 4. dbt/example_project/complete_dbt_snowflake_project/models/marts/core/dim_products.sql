with products as (
    select * from {{ ref('stg_shop__products') }}
)

select
    product_id,
    product_name,
    product_category,
    unit_cost,
    created_at,
    updated_at
from products

