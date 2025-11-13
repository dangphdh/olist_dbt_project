with source as (
    select * from {{ source('olist_raw', 'product_category_translation') }}
),

renamed as (
    select
        product_category_name,
        product_category_name_english,
        current_timestamp as _loaded_at
    from source
)

select * from renamed
