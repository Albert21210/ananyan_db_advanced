-- 3. загрузка данных в olap (postgresql)
-- сначала импортировать csv в stg_* и заполнить olap.months

do $$
begin
    -- закупки
    insert into olap.purchases
        (id, month_code, product_id, vendor_id, storage_id, quantity, amount)
    select id, extract(year from dt)::integer * 100 + extract(month from dt)::integer,
           product_id, vendor_id, storage_id, quantity, amount
    from olap.stg_purchases
    where id is not null and dt is not null
    on conflict (id) do nothing;

    -- продажи
    insert into olap.sales
        (id, month_code, ticket_number, product_name, quantity, price, amount)
    select id, extract(year from dt)::integer * 100 + extract(month from dt)::integer,
           ticket_number, product_name, quantity, price, amount
    from olap.stg_sales
    where id is not null and dt is not null
    on conflict (id) do nothing;

    -- сотрудники
    insert into olap.personnel (person_id, person_name)
    select person_id, person_name
    from olap.stg_personnel
    where person_id is not null
    on conflict (person_id) do nothing;

    -- рабочее время
    insert into olap.work_hours
        (id, month_code, person_id, system_period, manual_period)
    select id, extract(year from dt)::integer * 100 + extract(month from dt)::integer,
           person_id, system_period, manual_period
    from olap.stg_work_hours
    where id is not null and dt is not null
    on conflict (id) do nothing;

    -- движение запасов
    insert into olap.stock_moves
        (id, week_start, product_id, storage_id, quantity_change)
    select id, (dt - (extract(isodow from dt)::integer - 1))::date,
           product_id, storage_id, quantity_change
    from olap.stg_stock_moves
    where id is not null and dt is not null
    on conflict (id) do nothing;

    -- фактические остатки
    insert into olap.stock_balance
        (snapshot_date, storage_id, product_code, onhand)
    select snapshot_date, storage_id, product_code, sum(onhand)
    from olap.stg_stock_balance
    where snapshot_date is not null and storage_id is not null
      and product_code is not null
    group by snapshot_date, storage_id, product_code
    on conflict (snapshot_date, storage_id, product_code)
    do update set onhand = excluded.onhand;
end $$;

-- проверка
select 'закупки' as resource, count(*) as rows_count from olap.purchases
union all select 'продажи', count(*) from olap.sales
union all select 'сотрудники', count(*) from olap.personnel
union all select 'рабочее время', count(*) from olap.work_hours
union all select 'движение товаров', count(*) from olap.stock_moves
union all select 'остатки', count(*) from olap.stock_balance;
