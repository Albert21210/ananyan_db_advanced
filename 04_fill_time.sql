-- 4. время: код, начало/конец месяца, месяц, год, квартал
insert into olap.months
select extract(year from d)::integer * 100 + extract(month from d)::integer,
       d::date,
       (d + interval '1 month - 1 day')::date,
       (array['Январь','Февраль','Март','Апрель','Май','Июнь',
              'Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь'])
           [extract(month from d)::integer],
       extract(year from d)::integer,
       extract(quarter from d)::integer,
       extract(quarter from d)::integer || ' квартал'
from generate_series(date '2010-01-01', date '2040-12-01', interval '1 month') as t(d)
on conflict do nothing;

select * from olap.months order by code;
