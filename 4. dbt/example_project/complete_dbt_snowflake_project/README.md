# Complete dbt + Snowflake Learning Project

This is a production-shaped, runnable dbt project for an e-commerce company. It is deliberately small enough to understand, but it demonstrates the core workflow used in real projects:

```text
Snowflake raw tables
        ↓ source()
Staging views
        ↓ ref()
Intermediate transformations
        ↓ ref()
Dimensions and facts
        ↓
Tests, documentation, exposures and CI
```

## What this project demonstrates

- Snowflake sources and source freshness
- Staging, intermediate and marts layers
- `source()` and `ref()` dependency management
- View, table, ephemeral and incremental materializations
- Generic, singular and custom generic data tests
- Unit tests with mocked upstream rows
- Model contracts on a public fact table
- Seeds for small reference data
- Snapshots for customer history (SCD Type 2)
- Jinja macros and variables
- Documentation, column-level lineage and exposures
- Model groups, public access, contracts and versioning
- Selection syntax, selectors and tags
- A development/CI/production workflow
- A GitHub Actions CI example
- Snowflake setup and sample raw data

## Project architecture

| Layer | Purpose | Default materialization |
| --- | --- | --- |
| Sources | Declare raw objects owned by ingestion | Existing Snowflake tables |
| Staging | Rename, cast and lightly clean one source | View |
| Intermediate | Reusable joins and business logic | Ephemeral |
| Marts | Business-facing facts and dimensions | Table / Incremental |

Read [`docs/LEARNING_GUIDE.md`](docs/LEARNING_GUIDE.md) before exploring the models.

## Prerequisites

- Python 3.10+
- A Snowflake account
- A role allowed to create objects in a development database/schema
- dbt Core with the Snowflake adapter

## 1. Create the Snowflake demo environment

Open `setup/snowflake_setup.sql` in a Snowflake worksheet. Review the role, warehouse and database names, then run it with an administrative role.

It creates:

- `DBT_LEARNING_WH`
- `DBT_LEARNING_RAW.RAW_SHOP`
- Five raw source tables with sample rows
- `DBT_LEARNING_ANALYTICS`
- A development role and grants

The setup script is intentionally for a sandbox account. Do not apply it unchanged to production.

## 2. Install dbt

Create a virtual environment and install the dependencies:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
dbt deps
```

On Windows PowerShell, activate with:

```powershell
.venv\Scripts\Activate.ps1
```

## 3. Configure the Snowflake connection

Copy the example profile:

```bash
mkdir -p ~/.dbt
cp profiles.example.yml ~/.dbt/profiles.yml
```

Set these environment variables instead of committing credentials:

```bash
export DBT_SNOWFLAKE_ACCOUNT="your_account_identifier"
export DBT_SNOWFLAKE_USER="your_username"
export DBT_SNOWFLAKE_PASSWORD="your_password"
export DBT_SNOWFLAKE_ROLE="DBT_DEVELOPER"
export DBT_SNOWFLAKE_WAREHOUSE="DBT_LEARNING_WH"
export DBT_SNOWFLAKE_DATABASE="DBT_LEARNING_ANALYTICS"
export DBT_SNOWFLAKE_SCHEMA="DBT_YOUR_NAME"
```

For production, use key-pair or OAuth authentication and a secret manager rather than a password environment variable.

Verify the connection:

```bash
dbt debug
```

## 4. Run the project

```bash
dbt seed
dbt snapshot
dbt build
```

`dbt build` builds resources and runs tests in dependency order. Generate documentation with:

```bash
dbt docs generate
dbt docs serve
```

## Useful commands

```bash
# Build one model
dbt build --select fct_orders

# Build a model and all upstream dependencies
dbt build --select +fct_orders

# Build a model and all downstream dependencies
dbt build --select stg_shop__orders+

# Build all finance-tagged resources
dbt build --select tag:finance

# Use a named selector
dbt build --selector finance

# Rebuild an incremental model from scratch
dbt build --select fct_daily_revenue --full-refresh

# Compile without executing models
dbt compile

# Check source freshness
dbt source freshness
```

## Recommended reading order

1. `dbt_project.yml`
2. `models/staging/shop/_shop__sources.yml`
3. `models/staging/shop/stg_shop__orders.sql`
4. `models/intermediate/commerce/int_orders__enriched.sql`
5. `models/marts/core/fct_orders.sql`
6. `models/marts/core/_core__models.yml`
7. `models/marts/finance/fct_daily_revenue.sql`
8. `snapshots/shop_customers_snapshot.sql`
9. `tests/` and `macros/`
10. `.github/workflows/dbt_ci.yml`

## Important ownership boundary

dbt owns the transformed relations in analytics schemas. An ingestion tool should own the raw source tables. Terraform should normally own infrastructure such as warehouses, databases, roles and grants. Avoid making Terraform and dbt manage the same transformed table.

## Notes

- The sample timestamps are static, so source freshness may warn or fail long after the dataset was created. That is expected in a learning project.
- The project uses the modern dbt Core 1.10+ YAML syntax. Exact dependency versions may be updated as newer compatible releases become available.
- `DBT_ENV_SECRET_*` variables are intentionally not used in project code because dbt restricts where secret-prefixed variables may be referenced.
