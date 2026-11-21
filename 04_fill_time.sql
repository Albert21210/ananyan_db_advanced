-- 4. метрика время: 7 полей из тз + внешний код
-- выполняется после 01_structure_postgresql.sql
insert into olap_v2.dim_months
    (external_id, date_start, date_end, month_name, year_number, quarter_number, quarter_name)
select
    extract(year from d)::bigint * 100 + extract(month from d)::bigint,
    d::date,
    (d + interval '1 month - 1 day')::date,
    (array['Январь','Февраль','Март','Апрель','Май','Июнь',
           'Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь'])
        [extract(month from d)::integer],
    extract(year from d)::integer,
    extract(quarter from d)::integer,
    extract(quarter from d)::integer || ' квартал'
from generate_series(date '2010-01-01', date '2040-12-01', interval '1 month') as m(d)
on conflict (external_id) do nothing;

select count(*) from olap_v2.dim_months;
select * from olap_v2.dim_months order by external_id;
