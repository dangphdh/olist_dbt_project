{{
  config(
    materialized='table'
  )
}}

with sales as (
    select * from {{ ref('fct_sales') }}
),

daily_metrics as (
    select
        order_date,
        order_month,
        order_year,
        order_quarter,
        
        -- Order metrics
        count(distinct order_id) as total_orders,
        count(*) as total_items,
        
        -- Revenue metrics
        sum(item_price) as gross_revenue,
        sum(freight_value) as freight_revenue,
        sum(total_item_value) as total_revenue,
        avg(total_item_value) as avg_order_item_value,
        
        -- Customer metrics
        count(distinct customer_id) as unique_customers,
        
        -- Product metrics
        count(distinct product_id) as unique_products,
        count(distinct product_category_name_english) as unique_categories,
        
        -- Seller metrics
        count(distinct seller_id) as unique_sellers,
        
        -- Delivery metrics
        avg(total_delivery_days) as avg_delivery_days,
        sum(case when delivery_status = 'late' then 1 else 0 end) as late_deliveries,
        count(*) as total_deliveries,
        
        -- Payment type distribution
        sum(case when has_credit_card then 1 else 0 end) as credit_card_orders,
        sum(case when has_boleto then 1 else 0 end) as boleto_orders,
        sum(case when has_voucher then 1 else 0 end) as voucher_orders,
        sum(case when has_debit_card then 1 else 0 end) as debit_card_orders
        
    from sales
    group by order_date, order_month, order_year, order_quarter
)

select 
    *,
    -- Calculate late delivery rate
    case 
        when total_deliveries > 0 
        then round(late_deliveries::numeric / total_deliveries::numeric * 100, 2)
        else 0
    end as late_delivery_rate_pct,
    
    -- Revenue per customer
    case 
        when unique_customers > 0
        then round(total_revenue / unique_customers, 2)
        else 0
    end as revenue_per_customer
    
from daily_metrics
order by order_date
