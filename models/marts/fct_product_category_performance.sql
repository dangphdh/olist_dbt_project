{{
  config(
    materialized='table'
  )
}}

with sales as (
    select * from {{ ref('fct_sales') }}
),

category_metrics as (
    select
        product_category_name_english as category,
        
        -- Sales metrics
        count(distinct order_id) as total_orders,
        count(*) as total_items_sold,
        sum(item_price) as gross_revenue,
        sum(freight_value) as freight_revenue,
        sum(total_item_value) as total_revenue,
        avg(item_price) as avg_item_price,
        avg(total_item_value) as avg_total_item_value,
        
        -- Product metrics
        count(distinct product_id) as unique_products,
        
        -- Customer metrics
        count(distinct customer_id) as unique_customers,
        
        -- Delivery metrics
        avg(total_delivery_days) as avg_delivery_days,
        sum(case when delivery_status = 'late' then 1 else 0 end) as late_deliveries,
        count(*) as total_deliveries,
        
        -- Rating metrics
        avg(product_avg_rating) as avg_category_rating,
        sum(product_review_count) as total_reviews
        
    from sales
    where product_category_name_english is not null
    group by product_category_name_english
)

select 
    *,
    -- Calculate percentages
    round(late_deliveries::numeric / nullif(total_deliveries, 0)::numeric * 100, 2) as late_delivery_rate_pct,
    round(total_revenue / sum(total_revenue) over () * 100, 2) as revenue_share_pct
    
from category_metrics
order by total_revenue desc
