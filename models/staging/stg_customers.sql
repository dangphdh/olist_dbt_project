with source as (
    select * from {{ source('olist_raw', 'customers') }}
),

renamed as (
    select
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        current_timestamp as _loaded_at
    from source
)

select * from renamed
