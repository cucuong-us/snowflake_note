## Snowflake setup

- Ran `setup/snowflake_setup.sql` once with `ACCOUNTADMIN`.
- Created:
  - Warehouse: `DBT_LEARNING_WH`.
  - Raw database: `DBT_LEARNING_RAW`.
  - Analytics database: `DBT_LEARNING_ANALYTICS`.
  - Roles: `DBT_DEVELOPER` and `DBT_TRANSFORMER`.
  - Raw schema: `RAW_SHOP`.
- Raw tables:
  - `CUSTOMERS`.
  - `ORDERS`.
  - `ORDER_ITEMS`.
  - `PRODUCTS`.
  - `PAYMENTS`.
- Granted `DBT_DEVELOPER` to my Snowflake user.
- Normal dbt work should use `DBT_DEVELOPER`, not `ACCOUNTADMIN`.

## Virtual warehouse

- A warehouse is compute used to run queries.
- Snowflake does not automatically choose a warehouse for a job.
- The client or job specifies the warehouse it wants to use.
- dbt reads the warehouse name from `profiles.yml`.
- `DBT_LEARNING_WH` is X-Small, resumes automatically, and suspends when idle.

## Databases and schemas

- `DBT_LEARNING_RAW` contains source data.
- `DBT_LEARNING_ANALYTICS` contains transformed data created by dbt.
- Snowflake creates `INFORMATION_SCHEMA` automatically for metadata.
- The default development schema is `DBT_CUONG`.
- A custom macro combines the default schema with each resource-specific schema.
- I created some schemas for special purpose:
    + DBT_CUONG + REFERENCE -> DBT_CUONG_REFERENCE
    + DBT_CUONG + STAGING   -> DBT_CUONG_STAGING
    + DBT_CUONG + MARTS     -> DBT_CUONG_MARTS
    + DBT_CUONG + FINANCE   -> DBT_CUONG_FINANCE
    + DBT_CUONG + SNAPSHOTS -> DBT_CUONG_SNAPSHOTS

## dbt connection

- `profiles.yml` is stored inside the project.
- It is listed in `.gitignore` and must not be committed.
- Main connection settings:
  + Role: `DBT_DEVELOPER`.
  + Warehouse: `DBT_LEARNING_WH`.
  + Database: `DBT_LEARNING_ANALYTICS`.
  + Schema: `DBT_CUONG`.
  +  Threads: `4`.
- `--profiles-dir .` tells dbt to read `profiles.yml` from the current directory.

```
dbt debug --profiles-dir .
```

- The connection test passed successfully.
## Dependencies

```
dbt deps --profiles-dir .
```
## Seeds

- A seed is a small reference dataset stored as CSV in Git.
- This project uses `seeds/order_statuses.csv`.

```cmd
dbt seed --profiles-dir .
```

- The command creates:

```
DBT_LEARNING_ANALYTICS.DBT_CUONG_REFERENCE.ORDER_STATUSES
```

- The CSV is the source of truth.
- Adding, editing, or deleting CSV rows and rerunning the seed replaces the Snowflake table contents.
- Manual changes made directly to the Snowflake seed table can disappear on the next run.
- Use `--full-refresh` after changing columns or data types:

```cmd
dbt seed --full-refresh --profiles-dir .
```

- Seeds are suitable for small status mappings and reference lists, not large operational datasets.

## Snapshots

- Snapshots keep historical versions using SCD Type 2.
- The current snapshot tracks `RAW_SHOP.CUSTOMERS`.
- Main settings:
  - `unique_key: customer_id`.
  - `strategy: timestamp`.
  - `updated_at: updated_at`.
  - `hard_deletes: invalidate`.
- `dbt_valid_from` marks when a version became valid.
- `dbt_valid_to` marks when it stopped being valid.
- `dbt_valid_to = null` means the version is current.

### Hard-delete options

- `ignore`:
  - Do nothing when a row disappears from the source.
  - The old version remains current.
- `invalidate`:
  - Close the current version by setting `dbt_valid_to`.
  - No separate deleted-state row is created.
- `new_record`:
  - Add a separate deleted version.
  - Use `dbt_is_deleted` to make the deletion explicit.

## Data tests

- Tests in `_snapshots.yml` check the snapshot output.
- `dbt_scd_id` has `not_null` and `unique` tests.
- `customer_id` has `not_null` only because one customer can have multiple historical versions.
- A failed test does not repair or delete bad rows.
- dbt reports the failure and returns a nonzero exit code.

```cmd
dbt test --select shop_customers_snapshot --profiles-dir .
```

## dbt build

```cmd
dbt build --profiles-dir .
```

- Without `--select`, this builds the entire dbt project.
- It processes models, seeds, snapshots, unit tests, and data tests in DAG order.
- Dependencies come mainly from `source()` and `ref()`.
- Independent resources can run in parallel.
- `threads: 4` allows up to four independent dbt nodes to run concurrently.
- Threads are not Snowflake CPUs and do not control warehouse size.

### Materializations

- Staging models: views.
- Intermediate models: ephemeral.
- Core marts: tables.
- Daily finance revenue: incremental table.
- Snapshot: snapshot table.
- Seed: regular table.

### Ephemeral intermediate models

- They do not create separate tables or views in Snowflake.
- dbt inserts their compiled SQL into downstream models as CTEs.
- Their logic still runs as part of the downstream query.
- This reduces intermediate database objects but can make compiled SQL longer.

## Errors fixed

### Duplicate snapshot

- The same snapshot existed in both SQL and YAML.
- Kept the modern YAML definition and removed the duplicate SQL version.

### Deprecated source configuration

- `freshness` and `meta` were top-level source properties.
- Moved them into `config` for dbt 1.12.

### Missing schema for the unit test

- The unit test needs:

```text
DBT_LEARNING_ANALYTICS.DBT_CUONG
```

- The schema was missing because all physical models use suffixed schemas.
- The previous build still completed several resources:
  - Seed.
  - Five staging views.
  - Customer snapshot.
  - `DIM_PRODUCTS`.
  - `FCT_ORDER_ITEMS`.
- These models were skipped after the upstream test error:
  - `DIM_CUSTOMERS`.
  - `FCT_ORDERS`.
  - `FCT_DAILY_REVENUE`.
- Fix:

```sql
use role DBT_DEVELOPER;

create schema if not exists
DBT_LEARNING_ANALYTICS.DBT_CUONG;
```

- Then rerun:

```cmd
dbt build --profiles-dir .
```

## Where the code lives

- Source code remains in the dbt project
- dbt compiles Jinja and sends SQL to Snowflake.
- Snowflake views store compiled SQL definitions.
- Snowflake tables store data and metadata, not the original dbt files.
- `ref()`, `source()`, macros, tests, and YAML remain in the repository.
- Compiled SQL is available under `target/compiled` and `target/run`.

```text
Git/dbt project = source code and business logic
Snowflake       = SQL execution and data storage
Warehouse       = compute used to run SQL
```

## Commands to remember


- `dbt debug --profiles-dir .`:Validates the project configuration and tests the Snowflake connection. It does not create or modify data.
`dbt deps --profiles-dir .`:Downloads packages listed in packages.yml, such as dbt_utils. It does not change Snowflake.    
`dbt seed --profiles-dir .`:Loads CSV files from seeds/ into Snowflake tables. Rerunning it replaces table contents with the current CSV data.
`dbt snapshot --profiles-dir .`:Detects source-data changes and updates SCD Type 2 history. It inserts new versions and closes outdated versions.
`dbt test --profiles-dir .`: Runs data-quality checks such as not_null, unique, and relationships. It reports failures but does not repair data.
`dbt build --profiles-dir .`:Builds seeds, snapshots, models, and tests in dependency order. Without --select, it processes the entire project.
`dbt compile --profiles-dir .`: Converts Jinja, ref(), and source() into executable Snowflake SQL. It does not create tables or views.
```

Build one model:

```cmd
dbt build --select fct_orders --profiles-dir .
```

Build one model and its upstream dependencies:

```cmd
dbt build --select +fct_orders --profiles-dir .
```

Build staging resources:

```cmd
dbt build --select path:models/staging --profiles-dir .
```
