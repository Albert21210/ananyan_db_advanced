-- Cоздание таблицы фактов закупки
do $$
begin
    begin
        create table olap_v2.fact_purchase (
            id bigint primary key,
            product_id bigint references olap_v2.dim_products(id),
            range_id bigint references olap_v2.dim_ranges(id),
            category_id bigint references olap_v2.dim_categories(id),
            vendor_id bigint references olap_v2.dim_vendors(id),
            quantity numeric,
            amount numeric,
            date_add timestamp default now(),
            month_id bigint references olap_v2.dim_months(id)
        );
    end;
end $$;

-- Проверка
select * from olap_v2.fact_purchase;
