## How the commands are related

- `dbt build` includes compilation, seeds, snapshots, models, and tests.
- `dbt build` does not run `dbt deps` or `dbt debug`.
- `dbt compile` is useful when I only want to inspect generated SQL.
- I do not need to run `seed`, `snapshot`, and `test` separately before a full `dbt build`.
- A simple flow:

```cmd
dbt deps --profiles-dir .
dbt debug --profiles-dir .
dbt build --profiles-dir .
```

## What happens during `dbt build`

- dbt reads the project and profile.
- It parses SQL, YAML, tests, macros, seeds, and snapshots.
- It builds a DAG from `source()` and `ref()`.
- It compiles Jinja into Snowflake SQL.
- It connects with the configured role and warehouse.
- It runs the start hook.
- It builds ready resources based on dependencies.
- It runs unit tests before their models: test with fake data we give dbt
- It runs data tests after models are built: with current data in Snowflake
- It skips downstream nodes when an upstream error blocks them.
- It runs the end hook and writes artifacts to `target/`.
- The build is not one large transaction. Successful objects remain even when another node fails.

```text
source() → starting data
ref()    → dependency
tests    → decide whether downstream can continue
threads  → parallel execution limit
```

## Upstream and downstream

- Upstream means the sources and models required before the current model.
- Downstream means models that depend on the current model.

```text
A → B → C → D
```

- From `C`:
  - Upstream: `A` and `B`.
  - Downstream: `D`.
- Selection syntax:

```cmd
dbt build --select +fct_orders --profiles-dir .
dbt build --select fct_orders+ --profiles-dir .
dbt build --select +fct_orders+ --profiles-dir .
```

- `+fct_orders`: model plus upstream.
- `fct_orders+`: model plus downstream.
- `+fct_orders+`: upstream, model, and downstream.

## Hooks

- A hook is SQL or Jinja that runs at a specific point in a dbt command.
- Main hook types:
  - `on-run-start`: once before the invocation.
  - `pre-hook`: before a model.
  - `post-hook`: after a model.
  - `on-run-end`: once after the invocation.
- This project currently uses start and end hooks only for log messages.
- Hooks can also manage grants, audit logs, or session settings.
- Large transformation logic should stay in models, not hooks.

## Viewing the DAG

- Generate documentation:

```cmd
dbt docs generate --profiles-dir .
```

- Port `8080` was blocked on Windows, so the docs server uses port `8001`:

```cmd
dbt docs serve --profiles-dir . --host 127.0.0.1 --port 8001
```

- Open `http://localhost:8001`.
- Stop the server with `Ctrl + C`.
- The lineage graph shows intended dependencies from project code.
- It is not a history of the latest build.

## Documentation artifacts

- `manifest.json`
  - Contains resources, configuration, and dependencies parsed from code.
- `catalog.json`
  - Contains columns and relation metadata read from Snowflake.
- `run_results.json`
  - Contains pass, fail, error, skip, and timing results for the latest command.

```text
manifest.json    → project design
catalog.json     → current Snowflake metadata
run_results.json → latest command result
```

## Reading a model page in dbt Docs

- `Depends On` shows upstream resources.
- `Referenced By` shows downstream resources.
- `Code` shows source and compiled SQL.
- `Columns` shows documented or discovered columns.
- `Data Tests` shows quality checks.
- `Unit Tests` shows tests using mocked input and expected output.
- `Description` should explain the model purpose and grain.
- Tags can be used for selection, such as `tag:intermediate`.

## Ephemeral intermediate models

- `int_orders__item_aggregates` is an ephemeral model.
- It does not create a table or view in Snowflake.
- dbt compiles it into a CTE inside downstream SQL.
- It still appears in the DAG because it is a logical dependency.
- Snowflake Catalog cannot inspect an ephemeral relation because no physical object exists.
- dbt Docs therefore relies mainly on YAML column declarations for ephemeral models.

## Why only `order_id` appeared in Columns

- The SQL returns more columns:
  - `order_id`.
  - `line_count`.
  - `item_quantity`.
  - `gross_order_amount`.
- The YAML currently documents only `order_id`.
- `order_id` has `unique` and `not_null` tests.
- The `U`(unit) and `N`(NULL) symbols in dbt Docs represent those tests.
- To show the other columns, they need to be added to the model YAML with descriptions.

## Model grain

- Grain means what one row represents.
- `int_orders__item_aggregates` has one row per order.
- `order_id` should therefore be unique and not null.
- Understanding grain is important before writing joins or aggregations.

```text
Raw order items: many rows per order
        ↓ aggregate
Intermediate model: one row per order
```

## Project flow reviewed today

```text
shop.order_items
    -> stg_shop__order_items
    -> int_orders__item_aggregates

shop.payments
    -> stg_shop__payments
    -> int_orders__payment_aggregates

shop.orders
    -> stg_shop__orders

item aggregates + payment aggregates + orders
    -> int_orders__enriched

int_orders__enriched + stg_shop__customers
    -> dim_customers_v1
```

- `dim_customers_v1` has one row per customer.
- It combines customer details with lifetime order metrics.
- The `_v1` suffix comes from dbt model versioning.

