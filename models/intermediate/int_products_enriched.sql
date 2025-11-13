{{
  config(
    materialized='view'
  )
}}

with products as (
    select * from {{ ref('stg_products') }}
),

category_translation as (
    select * from {{ ref('stg_product_category_translation') }}
),

order_items as (
    select * from {{ ref('stg_order_items') }}
),

reviews as (
    select * from {{ ref('stg_order_reviews') }}
),

-- Aggregate sales metrics per product
product_sales as (
    select
        product_id,
        count(distinct order_id) as total_orders,
        sum(price) as total_revenue,
        avg(price) as avg_price,
        sum(freight_value) as total_freight,
        avg(freight_value) as avg_freight
    from order_items
    group by product_id
),

-- Aggregate reviews per product
product_reviews as (
    select
        oi.product_id,
        count(distinct r.review_id) as review_count,
        avg(r.review_score) as avg_review_score,
        sum(case when r.review_score = 5 then 1 else 0 end) as five_star_count,
        sum(case when r.review_score = 1 then 1 else 0 end) as one_star_count
    from order_items oi
    inner join reviews r on oi.order_id = r.order_id
    group by oi.product_id
),

final as (
    select
        p.product_id,
        p.product_category_name,
        ct.product_category_name_english,
        p.product_name_length,
        p.product_description_length,
        p.product_photos_quantity,
        p.product_weight_grams,
        p.product_length_cm,
        p.product_height_cm,
        p.product_width_cm,
        
        -- Calculate product volume
        (p.product_length_cm * p.product_height_cm * p.product_width_cm) as product_volume_cm3,
        
        -- Sales metrics
        coalesce(ps.total_orders, 0) as total_orders,
        coalesce(ps.total_revenue, 0) as total_revenue,
        coalesce(ps.avg_price, 0) as avg_price,
        coalesce(ps.total_freight, 0) as total_freight,
        coalesce(ps.avg_freight, 0) as avg_freight,
        
        -- Review metrics
        coalesce(pr.review_count, 0) as review_count,
        coalesce(pr.avg_review_score, 0) as avg_review_score,
        coalesce(pr.five_star_count, 0) as five_star_count,
        coalesce(pr.one_star_count, 0) as one_star_count,
        
        -- Product quality score
        case 
            when pr.review_count >= 10 then pr.avg_review_score
            else null
        end as quality_score
        
    from products p
    left join category_translation ct on p.product_category_name = ct.product_category_name
    left join product_sales ps on p.product_id = ps.product_id
    left join product_reviews pr on p.product_id = pr.product_id
)

select * from final
