{{
  config(
    materialized='table'
  )
}}

select * from {{ ref('int_sellers_enriched') }}
where seller_id is not null
