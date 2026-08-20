## 20/08/2026

#### I ask AI to creata for me an example project like a real project. You can see that in 4. dbt/example_project

## Flow of the project

```text
Application / source system
        ↓ ingestion
Raw tables in Snowflake
        ↓ source()
Staging models
        ↓ ref()
Intermediate models
        ↓ ref()
Marts
```

dbt mainly handles transformation. Raw tables are considered external to the dbt project, even though they are stored in Snowflake.

## Sources

A source registers existing tables with dbt. This allows dbt to manage their locations, dependencies, tests, freshness, and documentation.

```yaml
sources:
  - name: shop
    database: DBT_LEARNING_RAW
    schema: RAW_SHOP
    tables:
      - name: orders
      - name: customers
```

```sql
from {{ source('shop', 'orders') }}
```

dbt compiles this into something similar to:

```sql
from DBT_LEARNING_RAW.RAW_SHOP.ORDERS
```

`shop` is a logical name in dbt, while `RAW_SHOP` is the actual Snowflake schema. Declaring a source does not create or modify the raw table.

## Models

A model is a `select` statement stored in a `.sql` file. dbt uses it to produce a new dataset.

```sql
select
    order_id,
    customer_id,
    lower(status) as order_status
from {{ source('shop', 'orders') }}
```

The file `stg_shop__orders.sql` defines a model named `stg_shop__orders`.

- `source()` references data outside the current dbt project.
- `ref()` references a model, seed, or snapshot managed by the current project.

## Materializations

A model contains the SQL logic. Its materialization controls how dbt implements that logic:

- `view`: stores the SQL definition, not a separate copy of its results. Snowflake calculates the result when the view is queried.
- `table`: stores the result as physical data and must be rebuilt to receive changes.
- `incremental`: processes only new data or a selected lookback window.
- `ephemeral`: creates no separate database object; its SQL is inserted into downstream models as a CTE.

Staging models commonly use views because their logic is usually light, such as renaming columns, casting types, and standardizing values. It is not because staging models are rarely queried.

## Databases, schemas, and relations

A Snowflake object usually has this address:

```text
DATABASE.SCHEMA.TABLE_OR_VIEW
```

For example:

```text
DBT_LEARNING_ANALYTICS.DBT_NAM_FINANCE.FCT_DAILY_REVENUE
```

- `DBT_LEARNING_ANALYTICS`: database
- `DBT_NAM_FINANCE`: schema
- `FCT_DAILY_REVENUE`: table

A `relation` is dbt's general term for a queryable database object, such as a table or view.


## Profiles

```yaml
profile: complete_dbt_snowflake
```

This tells dbt to find a connection profile with the same name in `profiles.yml`. That profile contains the Snowflake account, user, role, warehouse, database, and default schema.

## Model YAML and tests

The SQL file defines the transformation. The YAML file describes the model, its grain, columns, and data-quality rules.

```yaml
models:
  - name: stg_shop__orders
    description: One row per order.
    columns:
      - name: order_id
        data_tests: [not_null, unique]
```

Common tests include:

- `not_null`: the column cannot contain null values.
- `unique`: values cannot be duplicated.
- `accepted_values`: values must belong to an allowed list.
- `relationships`: values must exist in another model, similar to checking a foreign key.
- `positive_value` and `not_in_future`: custom tests defined by this project.

Source tests check raw tables. Model tests check transformed outputs. Tests only query the data and report failures; they do not fix data or create constraints.

## When tests run

```text
dbt run               Builds models without running data tests
dbt test              Tests objects that already exist
dbt build             Builds and tests resources in DAG order
dbt source freshness  Checks whether source data was updated on time
```

