# dbt Project Structure Explained

## 🏗️ Three-Layer Architecture

### Layer 1: STAGING (models/staging/)
**Purpose**: Clean and standardize raw source data
**Materialization**: Views (lightweight, no storage cost)
**Naming**: `stg_<source_name>`

Example: `stg_customers.sql`
```sql
-- Input: raw public.customers table
-- Output: cleaned staging.stg_customers view
-- Changes:
--   ✓ Rename columns to standard format
--   ✓ Fix data types
--   ✓ Add metadata (_loaded_at timestamp)
--   ✗ NO business logic yet
--   ✗ NO aggregations
```

Files created:
- `stg_customers.sql` - Customer data
- `stg_sellers.sql` - Seller data
- `stg_products.sql` - Product data
- `stg_orders.sql` - Order header
- `stg_order_items.sql` - Order line items
- `stg_order_payments.sql` - Payments
- `stg_order_reviews.sql` - Reviews
- `stg_product_category_translation.sql` - Category names

---

### Layer 2: INTERMEDIATE (models/intermediate/)
**Purpose**: Add business logic and calculated fields
**Materialization**: Views (can change to tables if needed)
**Naming**: `int_<entity>_<description>`

Example: `int_orders_enriched.sql`
```sql
-- Input: staging layer views
-- Output: intermediate.int_orders_enriched view
-- Changes:
--   ✓ Join orders with customers
--   ✓ Calculate delivery metrics
--   ✓ Aggregate payments per order
--   ✓ Add derived fields (on-time status, etc.)
--   ✗ Still not aggregated by time period
```

Files created:
- `int_orders_enriched.sql` - Orders + delivery metrics + customer info
- `int_products_enriched.sql` - Products + sales stats + reviews
- `int_customers_enriched.sql` - Customers + lifetime value + segments

---

### Layer 3: MARTS (models/marts/)
**Purpose**: Final analytics-ready tables for BI tools
**Materialization**: Tables (fast query performance)
**Naming**: `fct_<metric>` or `dim_<entity>`

Example: `fct_sales.sql`
```sql
-- Input: intermediate layer views
-- Output: marts.fct_sales table
-- Changes:
--   ✓ Star schema design
--   ✓ All dimensions joined
--   ✓ Ready for BI tool queries
--   ✓ Optimized for analytics
```

Files created:

**Fact Tables** (events/transactions):
- `fct_sales.sql` - Sales transactions (grain: order line item)
- `fct_daily_sales_metrics.sql` - Daily KPIs (grain: date)
- `fct_product_category_performance.sql` - Category metrics (grain: category)

**Dimension Tables** (attributes):
- `dim_customers.sql` - Customer profiles
- `dim_products.sql` - Product catalog

---

## 📋 Configuration Files

### `dbt_project.yml`
Main project configuration:
- Project name and version
- Where to find models, tests, seeds
- Materialization strategy per folder
- Schema naming

### `profiles.yml`
Database connection:
- PostgreSQL host, port, credentials
- Target environments (dev, prod)
- Schema configuration

**Security Note**: Don't commit this to Git! Use environment variables in production.

### `packages.yml`
Third-party dbt packages:
- `dbt_utils` - Helper functions
- `dbt_expectations` - Advanced data quality tests

### `schema.yml` files
Documentation and tests:
- Column descriptions
- Data type definitions
- Test definitions (unique, not_null, etc.)
- Relationships between tables

---

## 🔄 How Models Reference Each Other

```
ref() function connects models:

┌─────────────────┐
│ stg_customers   │
└────────┬────────┘
         │ {{ ref('stg_customers') }}
         ▼
┌──────────────────────┐
│ int_orders_enriched  │
└──────────┬───────────┘
           │ {{ ref('int_orders_enriched') }}
           ▼
┌──────────────────┐
│   fct_sales      │
└──────────────────┘
```

dbt automatically:
- ✓ Resolves dependencies
- ✓ Runs models in correct order
- ✓ Creates schema if missing
- ✓ Handles errors gracefully

---

## 🧪 Testing Strategy

### Source Tests (`models/staging/src_olist.yml`)
Test raw data quality:
```yaml
columns:
  - name: customer_id
    tests:
      - unique
      - not_null
```

### Model Tests (`models/marts/schema.yml`)
Test transformed data:
```yaml
columns:
  - name: total_revenue
    tests:
      - not_null
      - dbt_utils.expression_is_true:
          expression: ">= 0"
```

### Custom Tests (`tests/`)
SQL queries that should return 0 rows:
```sql
-- Test: revenue should match payments
SELECT ...
WHERE revenue != payment
```

---

## 📊 Materialization Strategies

### View (default for staging/intermediate)
```sql
CREATE VIEW staging.stg_customers AS
SELECT ...
```
**Pros**: No storage, always fresh
**Cons**: Slower queries

### Table (default for marts)
```sql
CREATE TABLE marts.fct_sales AS
SELECT ...
```
**Pros**: Fast queries
**Cons**: Takes storage, needs refresh

### Incremental (advanced)
```sql
INSERT INTO marts.fct_sales
SELECT ... WHERE date > (SELECT MAX(date) FROM marts.fct_sales)
```
**Pros**: Only processes new data
**Cons**: More complex logic

### Ephemeral (hidden)
```sql
-- Not created in database, used in CTE
```
**Pros**: No database clutter
**Cons**: Recomputed every time

---

## 🎯 Model Execution Flow

When you run `dbt run`:

```
1. Parse project
   ├── Read dbt_project.yml
   ├── Find all .sql files
   └── Build dependency graph

2. Connect to database
   ├── Read profiles.yml
   └── Test connection

3. Execute models in order
   ├── Create schemas (staging, intermediate, marts)
   ├── Run staging models (parallel where possible)
   ├── Run intermediate models
   └── Run mart models

4. Report results
   ├── Success/failure count
   ├── Execution time
   └── Logs saved to logs/dbt.log
```

---

## 📈 Generated Schema Structure

After running dbt, your PostgreSQL will have:

```
olist_ecommerce database
│
├── public schema (raw data - from load script)
│   ├── customers
│   ├── sellers
│   ├── products
│   ├── orders
│   ├── order_items
│   ├── order_payments
│   └── order_reviews
│
├── staging schema (views from dbt)
│   ├── stg_customers
│   ├── stg_sellers
│   ├── stg_products
│   ├── stg_orders
│   ├── stg_order_items
│   ├── stg_order_payments
│   └── stg_order_reviews
│
├── intermediate schema (views from dbt)
│   ├── int_orders_enriched
│   ├── int_products_enriched
│   └── int_customers_enriched
│
└── marts schema (tables from dbt)
    ├── fct_sales
    ├── fct_daily_sales_metrics
    ├── fct_product_category_performance
    ├── dim_customers
    └── dim_products
```

**Query the marts for analytics!**
```sql
SELECT * FROM marts.fct_sales LIMIT 10;
```

---

## 🔍 Understanding the DAG (Directed Acyclic Graph)

The dependency graph looks like:

```
                    ┌──────────────┐
                    │ Raw Sources  │
                    │  (public)    │
                    └──────┬───────┘
                           │
            ┌──────────────┼──────────────┐
            │              │              │
     ┌──────▼─────┐ ┌─────▼──────┐ ┌────▼─────┐
     │stg_customers│ │stg_orders  │ │stg_prod. │
     └──────┬─────┘ └─────┬──────┘ └────┬─────┘
            │              │              │
            └──────┬───────┴──────┬───────┘
                   │              │
           ┌───────▼─────┐ ┌─────▼──────────┐
           │int_orders   │ │int_products    │
           │_enriched    │ │_enriched       │
           └───────┬─────┘ └─────┬──────────┘
                   │              │
                   └──────┬───────┘
                          │
                   ┌──────▼──────┐
                   │  fct_sales  │
                   └─────────────┘
```

View in browser: `dbt docs serve`

---

## 💡 Best Practices Implemented

1. **Naming Conventions**
   - `stg_` for staging
   - `int_` for intermediate
   - `fct_` for facts
   - `dim_` for dimensions

2. **One Model = One File**
   - Easy to find
   - Git-friendly
   - Clear ownership

3. **DRY (Don't Repeat Yourself)**
   - Use `ref()` to reuse models
   - Macros for repeated logic
   - Variables in `dbt_project.yml`

4. **Documentation**
   - Every model documented
   - Column descriptions
   - Business logic explained

5. **Testing**
   - Primary keys tested
   - Relationships validated
   - Business rules checked

---

**This architecture scales from GB to TB of data!** 🚀
