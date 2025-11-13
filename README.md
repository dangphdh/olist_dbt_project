# Olist E-commerce dbt Project

A modern data transformation pipeline for Olist Brazilian e-commerce data using dbt (data build tool) and PostgreSQL.

## 📋 Table of Contents

- [Overview](#overview)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Setup Instructions](#setup-instructions)
- [Running the Project](#running-the-project)
- [Data Models](#data-models)
- [Testing](#testing)
- [Documentation](#documentation)

## 🎯 Overview

This dbt project transforms raw Olist e-commerce data into analytics-ready tables following best practices:

- **Modular SQL**: Reusable, version-controlled transformations
- **Automated Testing**: Data quality checks on every run
- **Documentation**: Auto-generated lineage and data dictionary
- **Incremental Processing**: Efficient data pipelines

## 📁 Project Structure

```
olist_dbt_project/
├── dbt_project.yml           # Project configuration
├── profiles.yml              # Database connection settings
├── packages.yml              # dbt package dependencies
│
├── models/
│   ├── staging/              # Raw data cleaning & standardization
│   │   ├── src_olist.yml    # Source definitions
│   │   ├── stg_customers.sql
│   │   ├── stg_orders.sql
│   │   ├── stg_products.sql
│   │   └── ...
│   │
│   ├── intermediate/         # Business logic & enrichment
│   │   ├── int_orders_enriched.sql
│   │   ├── int_products_enriched.sql
│   │   ├── int_customers_enriched.sql
│   │   └── schema.yml
│   │
│   └── marts/               # Analytics-ready tables
│       ├── fct_sales.sql
│       ├── fct_daily_sales_metrics.sql
│       ├── fct_product_category_performance.sql
│       ├── dim_customers.sql
│       ├── dim_products.sql
│       └── schema.yml
│
├── seeds/                    # CSV reference data
├── macros/                   # Custom SQL functions
├── tests/                    # Custom data tests
└── snapshots/               # Type-2 SCD tables (future)
```

## 🔧 Prerequisites

1. **Python 3.7+** installed
2. **PostgreSQL** database with raw Olist data loaded
3. **dbt-core** and **dbt-postgres** adapter

## 🚀 Setup Instructions

### Step 1: Install dbt

```bash
# Install dbt with PostgreSQL adapter
pip install dbt-core dbt-postgres

# Verify installation
dbt --version
```

### Step 2: Load Raw Data

First, load the raw CSV data into PostgreSQL using the provided script:

```bash
cd /media/Mydisk/Dang/DuAnHC
python load_olist_data_to_postgres.py
```

This creates the source tables that dbt will transform.

### Step 3: Configure Database Connection

Edit `profiles.yml` and update your PostgreSQL credentials:

```yaml
olist_ecommerce:
  target: dev
  outputs:
    dev:
      type: postgres
      host: localhost
      user: your_username
      password: your_password
      port: 5432
      dbname: olist_ecommerce
      schema: public
      threads: 4
```

**Alternative**: Move `profiles.yml` to `~/.dbt/profiles.yml` (recommended for security)

### Step 4: Install dbt Packages

```bash
cd olist_dbt_project
dbt deps
```

This installs helpful packages like `dbt_utils` and `dbt_expectations`.

### Step 5: Test Connection

```bash
dbt debug
```

You should see "All checks passed!"

## 🏃 Running the Project

### Build All Models

```bash
# Run all transformations
dbt run
```

This executes models in dependency order:
1. **Staging models** (views in `staging` schema)
2. **Intermediate models** (views in `intermediate` schema)
3. **Mart models** (tables in `marts` schema)

### Run Specific Models

```bash
# Run just the marts
dbt run --select marts

# Run a specific model and its dependencies
dbt run --select +fct_sales

# Run a model and everything downstream
dbt run --select stg_orders+
```

### Test Data Quality

```bash
# Run all tests
dbt test

# Test specific models
dbt test --select fct_sales
```

### Generate Documentation

```bash
# Generate docs
dbt docs generate

# Serve documentation site
dbt docs serve
```

This opens a browser with interactive lineage diagrams and data dictionary!

### Full Workflow

```bash
# Complete workflow: run models + tests + docs
dbt build
```

## 📊 Data Models

### Staging Layer (`models/staging/`)

Clean, standardized versions of raw source tables:

- `stg_customers` - Customer master data
- `stg_sellers` - Seller master data
- `stg_products` - Product catalog
- `stg_orders` - Order header information
- `stg_order_items` - Order line items
- `stg_order_payments` - Payment transactions
- `stg_order_reviews` - Customer reviews
- `stg_product_category_translation` - Category translations

### Intermediate Layer (`models/intermediate/`)

Enriched models with business logic:

- **`int_orders_enriched`**: Orders with calculated delivery times, payment aggregations, and customer context
- **`int_products_enriched`**: Products with sales metrics, review scores, and category information
- **`int_customers_enriched`**: Customers with lifetime value, segmentation, and purchase patterns

### Marts Layer (`models/marts/`)

Analytics-ready tables for reporting:

#### Fact Tables
- **`fct_sales`**: Grain = order line item. Complete sales transactions with all dimensions
- **`fct_daily_sales_metrics`**: Grain = date. Daily aggregated KPIs
- **`fct_product_category_performance`**: Grain = category. Category-level performance metrics

#### Dimension Tables
- **`dim_customers`**: Customer attributes with lifetime metrics and segmentation
- **`dim_products`**: Product attributes with performance metrics

## 🧪 Testing

The project includes comprehensive data quality tests:

### Generic Tests
- **Uniqueness**: Primary keys are unique
- **Not Null**: Required fields have values
- **Relationships**: Foreign keys are valid
- **Accepted Values**: Enums contain only valid values

### Custom Tests
- Revenue values are non-negative
- Dates are within reasonable ranges

Run tests:
```bash
# All tests
dbt test

# Failed tests only
dbt test --select result:fail

# Test a specific model
dbt test --select fct_sales
```

## 📚 Documentation

### View Documentation

```bash
dbt docs generate
dbt docs serve
```

### What's Included

- **Data lineage**: Visual DAG showing model dependencies
- **Column descriptions**: Documentation for every field
- **Source freshness**: Data quality metrics
- **Test results**: Which tests passed/failed

## 🎯 Example Queries

After running `dbt run`, query the marts:

```sql
-- Daily revenue trend
SELECT 
    order_date,
    total_revenue,
    unique_customers,
    avg_order_item_value
FROM marts.fct_daily_sales_metrics
ORDER BY order_date;

-- Top performing categories
SELECT 
    category,
    total_revenue,
    revenue_share_pct,
    avg_category_rating
FROM marts.fct_product_category_performance
ORDER BY total_revenue DESC
LIMIT 10;

-- Customer segmentation
SELECT 
    customer_segment,
    value_segment,
    COUNT(*) as customer_count,
    AVG(lifetime_value) as avg_ltv
FROM marts.dim_customers
GROUP BY customer_segment, value_segment;

-- Sales by product category and month
SELECT 
    order_month,
    product_category_name_english,
    SUM(total_item_value) as revenue,
    COUNT(DISTINCT customer_id) as customers
FROM marts.fct_sales
GROUP BY order_month, product_category_name_english
ORDER BY order_month, revenue DESC;
```

## 🔄 Development Workflow

1. **Make changes** to SQL models
2. **Run models**: `dbt run --select +my_model`
3. **Test changes**: `dbt test --select my_model`
4. **Review results** in database
5. **Commit to git** when satisfied

## 📈 Performance Tips

- Use `--select` to run only changed models
- Materialize large tables, keep small ones as views
- Add indexes in post-hooks for frequently queried columns
- Use incremental models for very large fact tables

## 🐛 Troubleshooting

### "Compilation Error"
- Check SQL syntax in your model
- Verify all `ref()` and `source()` references exist

### "Database Error"
- Test connection: `dbt debug`
- Verify credentials in `profiles.yml`
- Ensure source tables exist

### "Test Failed"
- Run `dbt test` to see which tests failed
- Query the model directly to investigate data issues

## 📝 Next Steps

- [ ] Add incremental models for large fact tables
- [ ] Create snapshots for slowly changing dimensions
- [ ] Add macros for common calculations
- [ ] Set up CI/CD with GitHub Actions
- [ ] Create exposures for BI dashboards
- [ ] Add data freshness checks

## 📄 License

This project uses the Olist Brazilian E-commerce Public Dataset available on Kaggle.

## 🤝 Contributing

Contributions are welcome! Please:
1. Create a feature branch
2. Make your changes
3. Run tests: `dbt test`
4. Submit a pull request

---

**Built with ❤️ using dbt**
