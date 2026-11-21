-- 3. перенос из src_* в olap_v2 (postgresql, pl/pgsql)
-- вначале импортировать csv в src_* и выполнить скрипт времени
-- вложенные блоки begin/exception дают подтранзакции postgres

create or replace procedure olap_v2.load_resources()
language plpgsql
as $$
begin
    -- измерения
    begin
        insert into olap_v2.dim_ranges (external_id, name, factor)
        select distinct on (external_id) external_id, name, factor
        from olap_v2.src_ranges where external_id is not null
        order by external_id
        on conflict (external_id) do update
        set name = excluded.name, factor = excluded.factor;

        insert into olap_v2.dim_categories (external_id, name, parent_external_id)
        select distinct on (external_id) external_id, name, parent_external_id
        from olap_v2.src_categories where external_id is not null
        order by external_id
        on conflict (external_id) do update
        set name = excluded.name, parent_external_id = excluded.parent_external_id;

        insert into olap_v2.dim_vendor_groups (external_id, name)
        select distinct on (external_id) external_id, name
        from olap_v2.src_vendor_groups where external_id is not null
        order by external_id
        on conflict (external_id) do update set name = excluded.name;

        insert into olap_v2.dim_vendors (external_id, name, group_id)
        select distinct on (v.external_id)
            v.external_id, v.name, g.id
        from olap_v2.src_vendors v
        left join olap_v2.dim_vendor_groups g on v.group_external_id = g.external_id
        where v.external_id is not null
        order by v.external_id
        on conflict (external_id) do update
        set name = excluded.name, group_id = excluded.group_id;

        insert into olap_v2.dim_products (external_id, name, category_id, vendor_id, range_id)
        select distinct on (p.external_id)
            p.external_id, p.name, c.id, v.id, r.id
        from olap_v2.src_products p
        left join olap_v2.dim_categories c on p.category_external_id = c.external_id
        left join olap_v2.dim_vendors v on p.vendor_external_id = v.external_id
        left join olap_v2.dim_ranges r on p.range_external_id = r.external_id
        where p.external_id is not null
        order by p.external_id
        on conflict (external_id) do update
        set name = excluded.name, category_id = excluded.category_id,
            vendor_id = excluded.vendor_id, range_id = excluded.range_id;

        insert into olap_v2.dim_personnel (external_id, name)
        select distinct on (external_id) external_id, name
        from olap_v2.src_personnel where external_id is not null
        order by external_id
        on conflict (external_id) do update set name = excluded.name;

        insert into olap_v2.dim_storages (external_id, name)
        select distinct on (external_id) external_id, name
        from olap_v2.src_storages where external_id is not null
        order by external_id
        on conflict (external_id) do update set name = excluded.name;
    exception when others then
        raise exception 'ошибка переноса измерений: %', sqlerrm;
    end;

    -- факты закупок и продаж
    begin
        insert into olap_v2.fact_purchases
            (source_id, month_id, product_id, vendor_id, storage_id, quantity, amount)
        select distinct on (s.source_id)
            s.source_id, m.id, p.id, v.id, st.id, s.quantity, s.amount
        from olap_v2.src_purchases s
        join olap_v2.dim_months m
            on m.external_id = extract(year from s.dt)::bigint * 100 + extract(month from s.dt)::bigint
        left join olap_v2.dim_products p on s.product_external_id = p.external_id
        left join olap_v2.dim_vendors v on s.vendor_external_id = v.external_id
        left join olap_v2.dim_storages st on s.storage_external_id = st.external_id
        where s.source_id is not null and s.dt is not null
        order by s.source_id
        on conflict (source_id) do update
        set month_id = excluded.month_id, product_id = excluded.product_id,
            vendor_id = excluded.vendor_id, storage_id = excluded.storage_id,
            quantity = excluded.quantity, amount = excluded.amount;

        insert into olap_v2.fact_sales
            (source_id, month_id, ticket_number, product_name, quantity, price, amount)
        select distinct on (s.source_id)
            s.source_id, m.id, s.ticket_number, s.product_name, s.quantity, s.price, s.amount
        from olap_v2.src_sales s
        join olap_v2.dim_months m
            on m.external_id = extract(year from s.dt)::bigint * 100 + extract(month from s.dt)::bigint
        where s.source_id is not null and s.dt is not null
        order by s.source_id
        on conflict (source_id) do update
        set month_id = excluded.month_id, ticket_number = excluded.ticket_number,
            product_name = excluded.product_name, quantity = excluded.quantity,
            price = excluded.price, amount = excluded.amount;
    exception when others then
        raise exception 'ошибка переноса закупок и продаж: %', sqlerrm;
    end;

    -- персонал и остатки
    begin
        insert into olap_v2.fact_work_hours
            (source_id, month_id, person_id, system_period, manual_period)
        select distinct on (s.source_id)
            s.source_id, m.id, p.id, s.system_period, s.manual_period
        from olap_v2.src_work_hours s
        join olap_v2.dim_months m
            on m.external_id = extract(year from s.dt)::bigint * 100 + extract(month from s.dt)::bigint
        left join olap_v2.dim_personnel p on s.person_external_id = p.external_id
        where s.source_id is not null and s.dt is not null
        order by s.source_id
        on conflict (source_id) do update
        set month_id = excluded.month_id, person_id = excluded.person_id,
            system_period = excluded.system_period, manual_period = excluded.manual_period;

        insert into olap_v2.fact_stock_moves
            (source_id, week_start, product_id, storage_id, quantity_change)
        select distinct on (s.source_id)
            s.source_id,
            s.dt - (extract(isodow from s.dt)::integer - 1),
            p.id, st.id, s.quantity_change
        from olap_v2.src_stock_moves s
        left join olap_v2.dim_products p on s.product_external_id = p.external_id
        left join olap_v2.dim_storages st on s.storage_external_id = st.external_id
        where s.source_id is not null and s.dt is not null
        order by s.source_id
        on conflict (source_id) do update
        set week_start = excluded.week_start, product_id = excluded.product_id,
            storage_id = excluded.storage_id, quantity_change = excluded.quantity_change;

        insert into olap_v2.fact_stock_balance
            (snapshot_date, storage_id, product_code, onhand)
        select s.snapshot_date, st.id, s.product_code, sum(s.onhand)
        from olap_v2.src_stock_balance s
        join olap_v2.dim_storages st on s.storage_external_id = st.external_id
        where s.snapshot_date is not null and s.product_code is not null
        group by s.snapshot_date, st.id, s.product_code
        on conflict (snapshot_date, storage_id, product_code)
        do update set onhand = excluded.onhand;
    exception when others then
        raise exception 'ошибка переноса персонала и остатков: %', sqlerrm;
    end;
end;
$$;

-- внешняя транзакция: все изменения сохраняются только вместе
begin;
call olap_v2.load_resources();
commit;

-- проверка ресурсов
select 'закупки' as resource, count(*) as rows_count from olap_v2.fact_purchases
union all select 'продажи', count(*) from olap_v2.fact_sales
union all select 'сотрудники', count(*) from olap_v2.dim_personnel
union all select 'рабочие часы', count(*) from olap_v2.fact_work_hours
union all select 'движение запасов', count(*) from olap_v2.fact_stock_moves
union all select 'фактические остатки', count(*) from olap_v2.fact_stock_balance;
