- Main flow with DBT:


Source system ->
-> staging -> intermediate -> marts -> bussiness requirement

- dbt mainly handles the transform part. Raw data is inside Snowflake but still be external to the current dbt project.

- Project config

    + `dbt_project.yml` defines paths and default configs by folder.


    + A model inherits the closest folder config. A model-level config can override it.
    + `profile: complete_dbt_snowflake` points to the matching connection profile in `profiles.yml`. The profile contains the Snowflake account, user, role, warehouse, database, and target schema.

    - Snowflake object names follow: DATABASE.SCHEMA.OBJECT, for example

        + DBT_LEARNING_ANALYTICS.DBT_NAM_FINANCE.
        
        + FCT_DAILY_REVENUE
# DBT project component

## Sources

- Source YAML registers existing input tables. It does not create them.

```yaml
sources:
  - name: shop
    database: DBT_LEARNING_RAW
    schema: RAW_SHOP
    tables:
      - name: orders
```

```sql
{{ source('shop', 'orders') }}
```
mean that

```sql
DBT_LEARNING_RAW.RAW_SHOP.ORDERS
```

- `shop` is a logical dbt name. `RAW_SHOP` is the physical Snowflake schema. Sources can also have docs, tests, and freshness checks.

## Models

- Each SQL file under `models/` is normally one dbt model. The filename is the model name.

```text
stg_shop__orders.sql -> stg_shop__orders
```

The SQL defines how the dataset is made. `ref()` links models and lets dbt build the DAG and run dependencies in order.

```sql
from {{ ref('stg_shop__orders') }}
```

- `source()` reads an object outside the project.
- `ref()` reads a resource managed by the project.

- CTEs are temporary named query steps



## Model YAML

Model YAML adds docs, tests, metadata, and optional config to SQL models.

```text
.sql = how the data is produced
.yml = what it means and what rules it should follow
```


- Metadata is descriptive information such as owner or data classification. Config changes dbt behavior, such as materialization, schema, tags, or access.

- Contract = required column names/types. Data tests = rules for values inside those columns.

## Materializations

- `view`: stores SQL only; results are calculated when queried.
- `table`: stores physical results and is replaced when rebuilt.
- `incremental`: keeps old rows and processes only selected new/recent data.
- `ephemeral`: creates no Snowflake object; SQL is injected into downstream models as a CTE.

## Tests

- All dbt data tests pass when their query returns zero bad rows.

- Generic tests are called in YAML:

```yaml
data_tests: [not_null, unique]
```

- Common tests:

    + not_null
    + unique
    + accepted_values
- relationships
- custom generic tests such as `positive_value` and `not_in_future`

- Singular tests are full SQL files under `tests/`. They check specific business rules, such as a paid order having a payment.

- dbt run: build models only
- dbt test: run tests only
- dbt build: build and test in DAG order

## Snapshots

- Snapshots keep detected history instead of replacing old states.

    + unique_key='customer_id':matches the same customer across runs
    + strategy='timestamp'
    + updated_at='updated_at'
    + invalidate_hard_deletes=True

- First run saves the current rows. Later runs only add versions for new or changed rows and close old versions with `dbt_valid_to`. It does not copy every customer on every run.
## Seeds

- A seed is a small version-controlled CSV loaded as a Snowflake table.


- can set column types, docs, and tests. 

- Seeds are useful for small reference mappings, not large transaction data.

## Selectors

Named selectors are reusable selection rules.

```yaml
- name: finance
  definition:
    union:
      - method: tag
        value: finance
        parents: true
```

- This selects finance-tagged resources plus all upstream dependencies. Unrelated branches are not selected.

```yaml
- name: nightly
  definition:
    exclude:
      - method: fqn
        value: "*"
      - method: tag
        value: manual
```

- This means all resources except those tagged `manual`. A selector does not schedule anything; a job must call it.

- when I run: `dbt build --selector finance`. everthing have task finance will be run and its dependency
