{{
  config(
    materialized='table'
  )
}}

select * from {{ ref('int_customers_enriched') }}
where customer_id is not null
