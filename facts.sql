-- Создание таблицы фактов закупки
do $$
begin
    begin
        create table olap_v2.fact_purchase (
            id bigint primary key, -- Код
            product_id bigint, -- Код номенклатуры
            range_id bigint, -- Код единицы измерения
            category_id bigint, -- Код группы номенклатуры
            vendor_id bigint, -- Код поставщика
            quantity numeric, -- Количество
            amount numeric, -- Сумма
            date_add timestamp default now(), -- Дата вставки
            month_id bigint -- Код временного отрезка
        );

        comment on table olap_v2.fact_purchase is 'Таблица фактов закупки';

        comment on column olap_v2.fact_purchase.id is 'Код';
        comment on column olap_v2.fact_purchase.product_id is 'Код номенклатуры';
        comment on column olap_v2.fact_purchase.range_id is 'Код единицы измерения';
        comment on column olap_v2.fact_purchase.category_id is 'Код группы номенклатуры';
        comment on column olap_v2.fact_purchase.vendor_id is 'Код поставщика';
        comment on column olap_v2.fact_purchase.quantity is 'Количество';
        comment on column olap_v2.fact_purchase.amount is 'Сумма';
        comment on column olap_v2.fact_purchase.date_add is 'Дата вставки';
        comment on column olap_v2.fact_purchase.month_id is 'Код временного отрезка';
    end;

    begin
        -- Связь с номенклатурой
        alter table olap_v2.fact_purchase
        add foreign key (product_id) references olap_v2.dim_products(id);

        -- Связь с единицами измерения
        alter table olap_v2.fact_purchase
        add foreign key (range_id) references olap_v2.dim_ranges(id);

        -- Связь с группами номенклатуры
        alter table olap_v2.fact_purchase
        add foreign key (category_id) references olap_v2.dim_categories(id);

        -- Связь с поставщиками
        alter table olap_v2.fact_purchase
        add foreign key (vendor_id) references olap_v2.dim_vendors(id);

        -- Связь с временными отрезками
        alter table olap_v2.fact_purchase
        add foreign key (month_id) references olap_v2.dim_months(id);
    end;
end $$;

-- Проверка
select * from olap_v2.fact_purchase;
