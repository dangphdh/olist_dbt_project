# Quick Start Guide

## Prerequisites Checklist

- [ ] Python 3.7+ installed
- [ ] PostgreSQL installed and running
- [ ] Raw Olist data loaded into PostgreSQL

## Installation (5 minutes)

### Option 1: Automated Setup

```bash
cd olist_dbt_project
chmod +x setup.sh
./setup.sh
```

### Option 2: Manual Setup

```bash
# 1. Install dbt
pip install dbt-core dbt-postgres

# 2. Navigate to project
cd olist_dbt_project

# 3. Install packages
dbt deps

# 4. Update profiles.yml with your credentials

# 5. Test connection
dbt debug
```

## Load Raw Data

```bash
cd /media/Mydisk/Dang/DuAnHC
python load_olist_data_to_postgres.py
```

## Run dbt Pipeline

```bash
cd olist_dbt_project

# Run all models
dbt run

# Run tests
dbt test

# Generate documentation
dbt docs generate
dbt docs serve
```

## What Gets Created

### Schemas
- `staging` - Cleaned source data (views)
- `intermediate` - Business logic (views)
- `marts` - Analytics tables (tables)

### Key Tables
- `marts.fct_sales` - Sales transactions
- `marts.fct_daily_sales_metrics` - Daily KPIs
- `marts.dim_customers` - Customer dimension
- `marts.dim_products` - Product dimension

## Common Commands

```bash
# Run everything
dbt build

# Run specific model
dbt run --select fct_sales

# Run model and dependencies
dbt run --select +fct_sales

# Run changed models only
dbt run --select state:modified+

# Test specific model
dbt test --select fct_sales

# Fresh data check
dbt source freshness
```

## Troubleshooting

**Connection Failed?**
- Check `profiles.yml` credentials
- Verify PostgreSQL is running: `sudo systemctl status postgresql`
- Test connection: `psql -U postgres -d olist_ecommerce`

**Model Error?**
- Check logs in `logs/dbt.log`
- Run single model: `dbt run --select model_name`
- Validate SQL syntax

**Test Failed?**
- See which tests failed: `dbt test --store-failures`
- Query failing model directly to debug

## Next Steps

1. Explore the documentation: `dbt docs serve`
2. Query the marts in your SQL client
3. Connect BI tools (Tableau, Power BI, Metabase)
4. Customize models for your use case

## Support

- dbt Docs: https://docs.getdbt.com
- dbt Community: https://www.getdbt.com/community/
- dbt Slack: https://www.getdbt.com/community/join-the-community/
