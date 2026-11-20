-- 1. структура olap (postgresql)
create schema if not exists olap;

create table if not exists olap.months (
    code integer primary key,
    date_start date,
    date_end date,
    month_name text,
    year_number integer,
    quarter_number integer,
    quarter_name text
);

-- закупки
create table if not exists olap.purchases (
    id bigint primary key,
    month_code integer references olap.months(code),
    product_id bigint,
    vendor_id bigint,
    storage_id bigint,
    quantity numeric,
    amount numeric
);

-- продажи
create table if not exists olap.sales (
    id bigint primary key,
    month_code integer references olap.months(code),
    ticket_number numeric,
    product_name text,
    quantity numeric,
    price numeric,
    amount numeric
);

-- персонал
create table if not exists olap.personnel (
    person_id integer primary key,
    person_name text
);

create table if not exists olap.work_hours (
    id bigint primary key,
    month_code integer references olap.months(code),
    person_id integer,
    system_period numeric,
    manual_period numeric
);

-- изменения остатков по неделям
create table if not exists olap.stock_moves (
    id bigint primary key,
    week_start date,
    product_id bigint,
    storage_id bigint,
    quantity_change numeric
);

-- фактические остатки (если источник непустой)
create table if not exists olap.stock_balance (
    snapshot_date date,
    storage_id bigint,
    product_code text,
    onhand numeric,
    primary key (snapshot_date, storage_id, product_code)
);

-- таблицы для импорта csv
create table if not exists olap.stg_purchases (
    id bigint, dt date, product_id bigint, vendor_id bigint,
    storage_id bigint, quantity numeric, amount numeric
);

create table if not exists olap.stg_sales (
    id bigint, dt date, ticket_number numeric,
    product_name text, quantity numeric, price numeric, amount numeric
);

create table if not exists olap.stg_personnel (
    person_id integer, person_name text
);

create table if not exists olap.stg_work_hours (
    id bigint, dt date, person_id integer,
    system_period numeric, manual_period numeric
);

create table if not exists olap.stg_stock_moves (
    id bigint, dt date, product_id bigint,
    storage_id bigint, quantity_change numeric
);

create table if not exists olap.stg_stock_balance (
    snapshot_date date, storage_id bigint,
    product_code text, onhand numeric
);
