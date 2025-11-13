{{
  config(
    materialized='view'
  )
}}

with sellers as (
    select * from {{ ref('stg_sellers') }}
),

order_items as (
    select * from {{ ref('stg_order_items') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

reviews as (
    select * from {{ ref('stg_order_reviews') }}
),

-- Aggregate sales metrics per seller
seller_sales as (
    select
        seller_id,
        count(distinct order_id) as total_orders,
        count(*) as total_items_sold,
        sum(price) as total_revenue,
        avg(price) as avg_item_price,
        sum(freight_value) as total_freight,
        avg(freight_value) as avg_freight,
        min(price) as min_item_price,
        max(price) as max_item_price
    from order_items
    group by seller_id
),

-- Aggregate reviews per seller (through order_items)
seller_reviews as (
    select
        oi.seller_id,
        count(distinct r.review_id) as review_count,
        avg(r.review_score) as avg_review_score,
        sum(case when r.review_score = 5 then 1 else 0 end) as five_star_count,
        sum(case when r.review_score = 1 then 1 else 0 end) as one_star_count
    from order_items oi
    inner join reviews r on oi.order_id = r.order_id
    group by oi.seller_id
),

-- Get delivery performance per seller
seller_delivery as (
    select
        oi.seller_id,
        avg(extract(epoch from (o.order_delivered_customer_date - o.order_purchase_timestamp))/86400) as avg_delivery_days,
        sum(case when o.order_delivered_customer_date <= o.order_estimated_delivery_date then 1 else 0 end) as on_time_deliveries,
        count(*) as total_delivered_orders
    from order_items oi
    inner join orders o on oi.order_id = o.order_id
    where o.order_status = 'delivered'
    group by oi.seller_id
),

final as (
    select
        s.seller_id,
        s.seller_zip_code_prefix,
        s.seller_city,
        s.seller_state,
        
        -- Sales metrics
        coalesce(ss.total_orders, 0) as total_orders,
        coalesce(ss.total_items_sold, 0) as total_items_sold,
        coalesce(ss.total_revenue, 0) as total_revenue,
        coalesce(ss.avg_item_price, 0) as avg_item_price,
        coalesce(ss.total_freight, 0) as total_freight,
        coalesce(ss.avg_freight, 0) as avg_freight,
        coalesce(ss.min_item_price, 0) as min_item_price,
        coalesce(ss.max_item_price, 0) as max_item_price,
        
        -- Review metrics
        coalesce(sr.review_count, 0) as review_count,
        coalesce(sr.avg_review_score, 0) as avg_review_score,
        coalesce(sr.five_star_count, 0) as five_star_count,
        coalesce(sr.one_star_count, 0) as one_star_count,
        
        -- Delivery metrics
        coalesce(sd.avg_delivery_days, 0) as avg_delivery_days,
        coalesce(sd.on_time_deliveries, 0) as on_time_deliveries,
        coalesce(sd.total_delivered_orders, 0) as total_delivered_orders,
        
        -- Calculate on-time delivery rate
        case 
            when sd.total_delivered_orders > 0 
            then round(sd.on_time_deliveries::numeric / sd.total_delivered_orders::numeric, 2)
            else 0
        end as on_time_delivery_rate,
        
        -- Seller performance segmentation
        case 
            when ss.total_orders >= 100 then 'high_volume'
            when ss.total_orders >= 20 then 'medium_volume'
            when ss.total_orders >= 1 then 'low_volume'
            else 'inactive'
        end as seller_segment,
        
        -- Revenue segment
        case
            when ss.total_revenue >= 50000 then 'high_revenue'
            when ss.total_revenue >= 10000 then 'medium_revenue'
            when ss.total_revenue >= 1 then 'low_revenue'
            else 'no_revenue'
        end as revenue_segment,
        
        -- Quality score based on reviews
        case 
            when sr.review_count >= 10 then sr.avg_review_score
            else null
        end as quality_score
        
    from sellers s
    left join seller_sales ss on s.seller_id = ss.seller_id
    left join seller_reviews sr on s.seller_id = sr.seller_id
    left join seller_delivery sd on s.seller_id = sd.seller_id
)

select * from final
