{{
  config(
    materialized='table'
  )
}}

select * from {{ ref('int_products_enriched') }}
where product_id is not null
