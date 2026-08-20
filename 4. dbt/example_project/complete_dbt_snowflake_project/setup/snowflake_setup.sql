-- COMPLETE DBT LEARNING PROJECT: SNOWFLAKE SANDBOX SETUP
-- Review every statement before running. Use an isolated learning account/database.

use role accountadmin;

create warehouse if not exists DBT_LEARNING_WH
    warehouse_size = 'XSMALL'
    auto_suspend = 60
    auto_resume = true
    initially_suspended = true
    comment = 'Compute warehouse for the dbt learning project';

create database if not exists DBT_LEARNING_RAW
    comment = 'Raw source data for the dbt learning project';

create schema if not exists DBT_LEARNING_RAW.RAW_SHOP
    comment = 'Raw e-commerce application data';

create database if not exists DBT_LEARNING_ANALYTICS
    comment = 'dbt-managed analytics relations';

create role if not exists DBT_DEVELOPER
    comment = 'Development role for the dbt learning project';

create role if not exists DBT_TRANSFORMER
    comment = 'Production transformation role for the dbt learning project';

grant usage on warehouse DBT_LEARNING_WH to role DBT_DEVELOPER;
grant usage on warehouse DBT_LEARNING_WH to role DBT_TRANSFORMER;

grant usage on database DBT_LEARNING_RAW to role DBT_DEVELOPER;
grant usage on schema DBT_LEARNING_RAW.RAW_SHOP to role DBT_DEVELOPER;
grant select on all tables in schema DBT_LEARNING_RAW.RAW_SHOP to role DBT_DEVELOPER;
grant select on future tables in schema DBT_LEARNING_RAW.RAW_SHOP to role DBT_DEVELOPER;

grant usage on database DBT_LEARNING_RAW to role DBT_TRANSFORMER;
grant usage on schema DBT_LEARNING_RAW.RAW_SHOP to role DBT_TRANSFORMER;
grant select on all tables in schema DBT_LEARNING_RAW.RAW_SHOP to role DBT_TRANSFORMER;
grant select on future tables in schema DBT_LEARNING_RAW.RAW_SHOP to role DBT_TRANSFORMER;

grant usage, create schema on database DBT_LEARNING_ANALYTICS to role DBT_DEVELOPER;
grant usage, create schema on database DBT_LEARNING_ANALYTICS to role DBT_TRANSFORMER;

-- An administrator must grant DBT_DEVELOPER to the user running dbt, for example:
-- grant role DBT_DEVELOPER to user YOUR_USERNAME;

use database DBT_LEARNING_RAW;
use schema RAW_SHOP;

create or replace table customers (
    customer_id number not null,
    first_name varchar not null,
    last_name varchar not null,
    email varchar not null,
    country_code varchar(2) not null,
    created_at timestamp_ntz not null,
    updated_at timestamp_ntz not null,
    _loaded_at timestamp_ntz not null
);

insert into customers values
    (1, 'An', 'Nguyen', 'AN.NGUYEN@EXAMPLE.COM', 'vn', dateadd(day, -300, current_timestamp()), dateadd(day, -2, current_timestamp()), current_timestamp()),
    (2, 'Linh', 'Tran', 'linh.tran@example.com', 'VN', dateadd(day, -250, current_timestamp()), dateadd(day, -5, current_timestamp()), current_timestamp()),
    (3, 'Maya', 'Tan', 'maya.tan@example.com', 'SG', dateadd(day, -180, current_timestamp()), dateadd(day, -10, current_timestamp()), current_timestamp()),
    (4, 'Niran', 'Suk', 'niran.suk@example.com', 'TH', dateadd(day, -90, current_timestamp()), dateadd(day, -1, current_timestamp()), current_timestamp()),
    (5, 'Minh', 'Le', 'minh.le@example.com', 'VN', dateadd(day, -10, current_timestamp()), dateadd(day, -1, current_timestamp()), current_timestamp());

create or replace table orders (
    order_id number not null,
    customer_id number not null,
    status varchar not null,
    order_date date not null,
    created_at timestamp_ntz not null,
    updated_at timestamp_ntz not null,
    _loaded_at timestamp_ntz not null
);

insert into orders values
    (1001, 1, 'completed', dateadd(day, -30, current_date()), dateadd(day, -30, current_timestamp()), dateadd(day, -28, current_timestamp()), current_timestamp()),
    (1002, 1, 'shipped',   dateadd(day, -10, current_date()), dateadd(day, -10, current_timestamp()), dateadd(day, -8, current_timestamp()), current_timestamp()),
    (1003, 2, 'paid',      dateadd(day, -7, current_date()),  dateadd(day, -7, current_timestamp()),  dateadd(day, -7, current_timestamp()), current_timestamp()),
    (1004, 3, 'completed', dateadd(day, -5, current_date()),  dateadd(day, -5, current_timestamp()),  dateadd(day, -3, current_timestamp()), current_timestamp()),
    (1005, 4, 'completed', dateadd(day, -3, current_date()),  dateadd(day, -3, current_timestamp()),  dateadd(day, -1, current_timestamp()), current_timestamp()),
    (1006, 4, 'cancelled', dateadd(day, -1, current_date()),  dateadd(day, -1, current_timestamp()),  dateadd(day, -1, current_timestamp()), current_timestamp());

create or replace table products (
    product_id number not null,
    product_name varchar not null,
    category varchar not null,
    unit_cost_cents number not null,
    created_at timestamp_ntz not null,
    updated_at timestamp_ntz not null,
    _loaded_at timestamp_ntz not null
);

insert into products values
    (501, 'Mechanical Keyboard', 'Accessories', 3000, dateadd(day, -500, current_timestamp()), dateadd(day, -40, current_timestamp()), current_timestamp()),
    (502, 'Wireless Mouse',      'Accessories', 1200, dateadd(day, -450, current_timestamp()), dateadd(day, -20, current_timestamp()), current_timestamp()),
    (503, 'USB-C Hub',           'Accessories', 1800, dateadd(day, -300, current_timestamp()), dateadd(day, -15, current_timestamp()), current_timestamp()),
    (504, 'Laptop Stand',        'Office',      1500, dateadd(day, -200, current_timestamp()), dateadd(day, -10, current_timestamp()), current_timestamp());

create or replace table order_items (
    order_item_id number not null,
    order_id number not null,
    product_id number not null,
    quantity number not null,
    unit_price_cents number not null,
    _loaded_at timestamp_ntz not null
);

insert into order_items values
    (9001, 1001, 501, 1, 4500, current_timestamp()),
    (9002, 1002, 502, 2, 5500, current_timestamp()),
    (9003, 1003, 503, 1, 2500, current_timestamp()),
    (9004, 1004, 504, 2, 4000, current_timestamp()),
    (9005, 1005, 502, 1, 3000, current_timestamp()),
    (9006, 1006, 503, 1, 2500, current_timestamp());

create or replace table payments (
    payment_id number not null,
    order_id number not null,
    payment_method varchar not null,
    payment_status varchar not null,
    amount_cents number not null,
    paid_at timestamp_ntz,
    _loaded_at timestamp_ntz not null
);

insert into payments values
    (7001, 1001, 'card',          'succeeded', 4500, dateadd(day, -30, current_timestamp()), current_timestamp()),
    (7002, 1002, 'bank_transfer', 'succeeded', 11000, dateadd(day, -10, current_timestamp()), current_timestamp()),
    (7003, 1003, 'wallet',        'succeeded', 2500, dateadd(day, -7, current_timestamp()), current_timestamp()),
    (7004, 1004, 'card',          'failed',    8000, dateadd(day, -5, current_timestamp()), current_timestamp()),
    (7005, 1004, 'card',          'succeeded', 8000, dateadd(day, -5, current_timestamp()), current_timestamp()),
    (7006, 1005, 'wallet',        'succeeded', 3000, dateadd(day, -3, current_timestamp()), current_timestamp()),
    (7007, 1005, 'wallet',        'refunded',  3000, dateadd(day, -1, current_timestamp()), current_timestamp());

-- Grants must be refreshed because the demo tables were created after the first grant.
grant select on all tables in schema DBT_LEARNING_RAW.RAW_SHOP to role DBT_DEVELOPER;
grant select on all tables in schema DBT_LEARNING_RAW.RAW_SHOP to role DBT_TRANSFORMER;

select 'Snowflake demo setup complete' as status;

