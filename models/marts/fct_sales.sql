{{
  config(
    materialized='table'
  )
}}

with orders as (
    select * from {{ ref('int_orders_enriched') }}
),

order_items as (
    select * from {{ ref('stg_order_items') }}
),

products as (
    select * from {{ ref('int_products_enriched') }}
),

sellers as (
    select * from {{ ref('stg_sellers') }}
),

final as (
    select
        oi.order_id,
        oi.order_item_id,
        o.order_purchase_timestamp,
        date_trunc('day', o.order_purchase_timestamp) as order_date,
        date_trunc('month', o.order_purchase_timestamp) as order_month,
        extract(year from o.order_purchase_timestamp) as order_year,
        extract(quarter from o.order_purchase_timestamp) as order_quarter,
        extract(month from o.order_purchase_timestamp) as order_month_num,
        extract(dow from o.order_purchase_timestamp) as order_day_of_week,
        
        -- Order information
        o.customer_id,
        o.customer_city,
        o.customer_state,
        o.order_status,
        
        -- Product information
        oi.product_id,
        p.product_category_name,
        p.product_category_name_english,
        
        -- Seller information
        oi.seller_id,
        s.seller_city,
        s.seller_state,
        
        -- Metrics
        oi.price as item_price,
        oi.freight_value,
        oi.price + oi.freight_value as total_item_value,
        
        -- Delivery metrics
        o.delivery_status,
        o.total_delivery_days,
        o.days_early_late,
        
        -- Payment information
        o.has_credit_card,
        o.has_boleto,
        o.has_voucher,
        o.has_debit_card,
        
        -- Product metrics
        p.avg_review_score as product_avg_rating,
        p.review_count as product_review_count
        
    from order_items oi
    inner join orders o on oi.order_id = o.order_id
    left join products p on oi.product_id = p.product_id
    left join sellers s on oi.seller_id = s.seller_id
    where o.order_status not in ('canceled', 'unavailable')
)

select * from final
