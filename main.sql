do $$ begin
	if to_regclass('public.calc_correction_temperature') is not null and to_regclass('public.calc_temperature_correction') is null then
		alter table public.calc_correction_temperature rename to calc_temperature_correction; end if;   -- имя после прошлого запуска
	if to_regclass('public.calc_temperature_correction') is null then   -- Таблица 1 из ТЗ (виртуальная поправка)
		create table public.calc_temperature_correction(temperature numeric(8,2) primary key, correction numeric(8,2) not null);
		insert into public.calc_temperature_correction values (0,0),(5,0.5),(10,1),(15,1),(20,1.5),(25,2),(30,3.5),(40,4.5); end if;
	if to_regtype('public.interpolation_type') is null then create type public.interpolation_type as (x0 numeric, y0 numeric, x1 numeric, y1 numeric); end if;
	if not exists (select 1 from pg_roles where rolname = 'admin') then create role admin; end if;   -- роль из учебного скрипта (OWNER TO admin)
	if not exists (select 1 from pg_proc where proname = 'fn_calc_interpolation') then
		create function public.fn_calc_interpolation(par_x numeric, par_i public.interpolation_type) returns numeric language sql as
		$f$ select case when par_i.x1 = par_i.x0 then par_i.y0 else par_i.y0 + (par_i.y1 - par_i.y0) * (par_x - par_i.x0) / (par_i.x1 - par_i.x0) end $f$; end if;
end $$;

drop procedure if exists public.sp_calc_meteo_avg(public.calc_input_params, integer);
drop function if exists public.fn_calc_tt(integer, integer), public.fn_calc_wind(integer, integer, numeric), public.fn_calc_delta_temperature(numeric), public.fn_calc_format_signed(integer, integer);
drop type if exists public.calc_input_params;
drop table if exists calc_correction, calc_correction_old, calc_correction_headers, calc_correction_types, calc_correction_heights cascade;
drop sequence if exists calc_correction_seq, calc_correction_types_seq, calc_correction_height_seq;

-- ЧАСТЬ 1. Учебный скрипт
do $$
begin
	-- Создаем новые структуры
	begin
		-- Таблица стандартных высот
		create sequence calc_correction_height_seq;
		create table calc_correction_heights
		(
		        id integer primary key not null default nextval('public.calc_correction_height_seq'),
		        height integer not null
		);
		insert into calc_correction_heights(height)
		values(200),(400),(800),(1200),(1600),(2000),(2400),(3000),(4000);
		comment on table calc_correction_heights is 'Таблица стандартных высот';
		comment on column calc_correction_heights.id is 'Уникальный код';
		comment on column calc_correction_heights.height is 'Высота';
		-- Справочник типов таблиц корректировок
		create sequence calc_correction_types_seq;
		create table calc_correction_types
		(
		        id integer not null primary key default nextval('public.calc_correction_types_seq'),
		        parent_id integer,
		        measurment_equipment_id integer,
		        description text not null,
		        header_values integer[]
		);
		comment on table calc_correction_types is 'Справочник типов таблиц с собственными заголовками';
		comment on column calc_correction_types.id is 'Уникальный код';
		comment on column calc_correction_types.parent_id is 'Уникальный код владельца - тип таблицы';
		comment on column calc_correction_types.measurment_equipment_id is 'Тип оборудования';
		comment on column calc_correction_types.description is 'Описание к таблице';
		comment on column calc_correction_types.header_values is 'Значения в заголовке таблице';
		-- Универсальная таблица корректировок
		create sequence calc_correction_seq;
		create table calc_correction
		(
		        id integer not null primary key default nextval('public.calc_correction_seq'),
		        height_id integer not null,
		        type_id integer not null,
		        row_values integer[]
		);
		comment on table calc_correction is 'Универсальная таблица корректировок';
		comment on column calc_correction.id is 'Уникальный код';
		comment on column calc_correction.height_id is 'Код высоты';
		comment on column calc_correction.type_id is 'Код типа таблиц';
		comment on column calc_correction.row_values is 'Значения с корректировками';
	end;
	-- Добавляем данные
	begin
		insert into calc_correction_types(  description, header_values)
		values( 'Таблица 2', array[0, 1, 2, 3, 4, 5, 6, 7, 8, 8, 10, 20, 30, 40, 50]),  -- 1
		( 'Таблица 3, скорость среднего ветра', null), -- 2
		( 'Таблица 3, направление среднего ветра', null);       -- 3
		insert into calc_correction_types( description, parent_id, measurment_equipment_id, header_values)
		values
		('Таблица 3, Скорость среднего ветра (ВР)', 2, 2, array[40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]), -- 4
		('Таблица 3, Направление среднего ветра (ВР)',3, 2, array[40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]), -- 5
		('Таблица 3, Скорость среднего ветра (ДМК)',2, 1, array[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]), -- 6
		('Таблица 3, Направление среднего ветра (ДМК)',3, 1, array[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]); -- 7
		insert into calc_correction_types( description, parent_id)
		values('Таблица 2, Положительные температуры', 1 ), -- 8
		('Таблица 2, Отрицательные температуры', 1 ) --9
		;
		insert into calc_correction(height_id, type_id, row_values )
		-- Таблица 2, отрицптельные значения
		values(1, 8, array[-1, -2, -3, -4, -5, -6, -7, -8, -8, -9, -20, -29, -39, -49]), -- 200
		(2, 8, array[-1, -2, -3, -4, -5, -6, -6, -7, -8, -9, -19, -29, -39, -48]), -- 400
		(3, 8, array[-1, -2, -3, -4, -5, -6, -6, -7, -7, -8, -18, -28, -37, -46]), -- 800
		(4, 8, array[-1, -2, -3, -4, -4, -5, -5, -6, -7, -8, -17, -26, -35, -44]), -- 1200
		-- Таблица 2, положитеьные значения
		(1, 7, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 200
		(2, 7, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 400
		(3, 7, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 800
		(4, 7, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 1200
		-- Таблица 3, Скорость среднего ветра (ВР)
		(1, 4, array[3, 4, 5, 6, 7, 7, 8, 9, 10, 11, 12, 12]), -- 200
		(2, 4, array[4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14 ,15]), -- 400
		(3, 4, array[4, 5, 6, 7, 8, 9, 10, 11, 13, 14, 15 ,16]), -- 800
		(4, 4, array[4, 5, 7, 8, 8, 9, 11, 12, 13, 15 ,15, 16]), -- 1200
		-- Таблица 3, Направление среднего ветра (ВР)
		(1, 5, array[0]), -- 200
		(2, 5, array[1]), -- 400
		(3, 5, array[2]), -- 800
		(4, 5, array[2]), -- 1200
		-- Таблица 3,Скорость среднего ветра (ДМК)
		(1, 6, array[4,6,8,9,10,12,14,15,16,18,20,21,22]), -- 200
		(2, 6, array[5,7,10,11,12,14,17,18,20,22,23,25,27]), -- 400
		(3, 6, array[5,8,10,11,13,15,18,19,21,23,25,27,28]), -- 800
		(4, 6, array[5,8,11,12,13,16,19,20,23,24,26,28,30]), -- 1200
		-- 'Таблица 3, Направление среднего ветра (ДМК)
		(1, 7, array[1]), -- 200
		(2, 7, array[2]), -- 400
		(3, 7, array[3]), -- 800
		(4, 7, array[3]) -- 1200
		;
	end;
	-- Прочее
	begin
		-- Наименование подправляем
		alter table public.calc_temperature_correction rename to calc_correction_temperature;
		CREATE OR REPLACE FUNCTION public.fn_calc_temperature_interpolation(
			par_temperature numeric)
		    RETURNS numeric
		    LANGUAGE 'plpgsql'
		    COST 100
		    VOLATILE PARALLEL UNSAFE
		AS $BODY$
				        declare
				                var_interpolation interpolation_type;
				                var_result numeric(8,2) default 0;
				                var_min_temparure numeric(8,2) default 0;
				                var_max_temperature numeric(8,2) default 0;
				                var_denominator numeric(8,2) default 0;
				        begin
				                                raise notice 'Расчет интерполяции для температуры %', par_temperature;
				                -- Проверим, возможно температура совпадает со значением в справочнике
				                if exists (select 1 from public.calc_correction_temperature where temperature = par_temperature ) then
				                begin
				                        select correction
				                        into  var_result
				                        from  public.calc_correction_temperature
				                        where
				                                temperature = par_temperature;
				                end;
				                else
				                begin
				                        -- Получим диапазон в котором работают поправки
				                        select min(temperature), max(temperature)
				                        into var_min_temparure, var_max_temperature
				                        from public.calc_correction_temperature;
				                        if par_temperature < var_min_temparure or
				                           par_temperature > var_max_temperature then
				                                raise exception 'Некорректно передан параметр! Невозможно рассчитать поправку. Значение должно укладываться в диаппазон: %, %',
				                                        var_min_temparure, var_max_temperature;
				                        end if;
				                        -- Получим граничные параметры
				                        select x0, y0, x1, y1
				                                                 into var_interpolation.x0, var_interpolation.y0, var_interpolation.x1, var_interpolation.y1
				                        from
				                        (
				                                select t1.temperature as x0, t1.correction as y0
				                                from public.calc_correction_temperature as t1
				                                where t1.temperature <= par_temperature
				                                order by t1.temperature desc
				                                limit 1
				                        ) as leftPart
				                        cross join
				                        (
				                                select t1.temperature as x1, t1.correction as y1
				                                from public.calc_correction_temperature as t1
				                                where t1.temperature >= par_temperature
				                                order by t1.temperature
				                                limit 1
				                        ) as rightPart;
				                        raise notice 'Граничные значения %', var_interpolation;
				                        var_result :=  fn_calc_interpolation( par_temperature,  var_interpolation);
				                end;
				                end if;
				                                return var_result;
				end;
		$BODY$;
		ALTER FUNCTION public.fn_calc_temperature_interpolation(numeric)
		    OWNER TO admin;
		COMMENT ON FUNCTION public.fn_calc_temperature_interpolation(numeric)
		    IS 'Функция для расчета интерполяции для метео приближенный';
	end;
end $$;

-- ЧАСТЬ 2. Исправление и дополнение справочников (Таблица 2, Таблица 3).
create table calc_correction_headers(id integer generated always as identity primary key,
	type_id integer not null references calc_correction_types(id),
	header_value integer not null, unique (type_id, header_value));   -- Таблица 2: со знаком; направление ветра: 0
comment on table calc_correction_headers is 'Заголовки (аргументы столбцов) таблиц корректировок'; comment on column calc_correction_headers.id is 'Уникальный код';
comment on column calc_correction_headers.type_id is 'Код типа таблицы'; comment on column calc_correction_headers.header_value is 'Значение аргумента: Таблица 2 - со знаком, направление ветра - 0';

alter table calc_correction rename to calc_correction_old;
create table calc_correction(id integer generated always as identity primary key,
	height_id integer not null references calc_correction_heights(id),
	header_id integer not null references calc_correction_headers(id),
	value integer not null, unique (height_id, header_id));
comment on table calc_correction is 'Универсальная таблица корректировок (одна ячейка - одна строка)'; comment on column calc_correction.id is 'Уникальный код'; comment on column calc_correction.height_id is 'Код высоты';
comment on column calc_correction.header_id is 'Код заголовка (столбца)'; comment on column calc_correction.value is 'Значение поправки'; comment on table calc_correction_types is 'Справочник типов таблиц корректировок; заголовки хранятся в calc_correction_headers';

alter table calc_correction_types drop column header_values;
delete from calc_correction_types where id in (8, 9);
update calc_correction_types set description = 'Таблица 2, отклонение температуры' where id = 1;
alter table calc_correction_types add foreign key (parent_id) references calc_correction_types(id);

insert into calc_correction_headers(type_id, header_value)   -- Таблица 2: -50..50 (единицы 1..9 и десятки), ВР 40..150, ДМК 3..15, направление 0
select 1, s from generate_series(-50, 50) s where s <> 0 and (abs(s) < 10 or s % 10 = 0)
union select 4, generate_series(40, 150, 10) union select 6, generate_series(3, 15) union select 5, 0 union select 7, 0;

insert into calc_correction(height_id, header_id, value)
select ht.id, hd.id, hd.header_value from calc_correction_heights ht
cross join calc_correction_headers hd where hd.type_id = 1 and hd.header_value > 0;

-- Таблица 2 (минус; плюс = заголовку). Таблица 3: ВР - скорость (тип 4), направление (тип 5); ДМК - скорость (тип 6), направление (тип 7); '3-00' = 3
with src(type_id, height_id, a) as (
	select v.type_id, ht.id, v.a from (values
		(1,200,array[-1,-2,-3,-4,-5,-6,-7,-8,-8,-9,-20,-29,-39,-49]), (4,200,array[3,4,5,6,7,7,8,9,10,11,12,12]), (6,200,array[4,6,8,9,10,12,14,15,16,18,20,21,22]),
		(1,400,array[-1,-2,-3,-4,-5,-6,-6,-7,-8,-9,-19,-29,-38,-48]), (4,400,array[4,5,6,7,8,9,10,11,12,13,14,15]), (6,400,array[5,7,10,11,12,14,17,18,20,22,23,25,27]),
		(1,800,array[-1,-2,-3,-4,-5,-6,-6,-7,-7,-8,-18,-28,-37,-46]), (4,800,array[4,5,6,7,8,9,10,11,13,14,15,16]), (6,800,array[5,8,10,11,13,15,18,19,21,23,25,27,28]),
		(1,1200,array[-1,-2,-3,-4,-4,-5,-5,-6,-7,-8,-17,-26,-35,-44]), (4,1200,array[4,5,7,8,8,9,11,12,13,15,15,16]), (6,1200,array[5,8,11,12,13,16,19,20,22,24,26,28,30]),
		(1,1600,array[-1,-2,-3,-3,-4,-4,-5,-6,-7,-7,-17,-25,-34,-42]), (4,1600,array[4,6,7,8,9,10,11,13,14,15,17,17]), (6,1600,array[6,8,11,13,14,17,20,21,23,25,27,29,32]),
		(1,2000,array[-1,-2,-3,-3,-4,-4,-5,-6,-6,-7,-16,-24,-32,-40]), (4,2000,array[4,6,7,8,9,10,11,13,14,16,17,18]), (6,2000,array[6,9,11,13,14,17,20,21,24,26,28,30,32]),
		(1,2400,array[-1,-2,-2,-3,-4,-4,-5,-5,-6,-7,-15,-23,-31,-38]), (4,2400,array[4,6,8,9,9,10,12,14,15,16,18,19]), (6,2400,array[6,9,12,14,15,18,21,22,25,27,29,32,34]),
		(1,3000,array[-1,-2,-2,-3,-4,-4,-4,-5,-5,-6,-15,-22,-30,-37]), (4,3000,array[5,6,8,9,10,11,12,14,15,17,18,19]), (6,3000,array[6,9,12,14,15,18,21,23,25,28,30,32,36]),
		(1,4000,array[-1,-2,-2,-3,-4,-4,-4,-4,-5,-6,-14,-20,-27,-34]), (4,4000,array[5,6,8,9,10,11,12,14,16,18,19,20]), (6,4000,array[6,10,12,14,16,19,22,24,26,29,32,34,36]),
		(5,200,array[0]),(5,400,array[1]),(5,800,array[2]),(5,1200,array[2]),(5,1600,array[3]),(5,2000,array[3]),(5,2400,array[3]),(5,3000,array[4]),(5,4000,array[4]),
		(7,200,array[1]),(7,400,array[2]),(7,800,array[3]),(7,1200,array[3]),(7,1600,array[4]),(7,2000,array[4]),(7,2400,array[4]),(7,3000,array[5]),(7,4000,array[5])) v(type_id, h, a)
	join calc_correction_heights ht on ht.height = v.h)
insert into calc_correction(height_id, header_id, value)
select s.height_id, hd.id, x.val
from src s cross join lateral unnest(s.a) with ordinality as x(val, n)
join (select id, type_id, row_number() over (partition by type_id order by abs(header_value)) as n
      from calc_correction_headers where type_id <> 1 or header_value < 0) hd on hd.type_id = s.type_id and hd.n = x.n;
drop table calc_correction_old;

-- ЧАСТЬ 3. Расчет приближенного метеобюллетеня
create type public.calc_input_params as (height integer, temperature numeric(5,1), pressure integer, wind_direction integer, wind_speed integer, drift_distance integer);
comment on type public.calc_input_params is 'Входящие параметры для расчета приближенного метеобюллетеня'; comment on column public.calc_input_params.height is 'Высота метеопоста, м'; comment on column public.calc_input_params.temperature is 'Температура воздуха, °C (-58..58)';
comment on column public.calc_input_params.pressure is 'Давление, мм рт. ст. (500..900)'; comment on column public.calc_input_params.wind_direction is 'Направление ветра, б.д. угломера (0..59)'; comment on column public.calc_input_params.wind_speed is 'Скорость ветра, м/с (0..15, для ДМК)'; comment on column public.calc_input_params.drift_distance is 'Дальность сноса пуль, м (0..150, для ВР)';

create function public.fn_calc_tt(par_height_id integer, par_dt integer) returns integer language sql stable as $$
	select coalesce(sum(c.value), 0)::integer from public.calc_correction c
	join public.calc_correction_headers hd on hd.id = c.header_id
	where c.height_id = par_height_id and hd.type_id = 1
	  and hd.header_value in (sign(par_dt) * (least(abs(par_dt), 50) / 10 * 10), sign(par_dt) * (least(abs(par_dt), 50) % 10));
$$;

create function public.fn_calc_wind(par_type_id integer, par_height_id integer, par_x numeric) returns integer language sql stable as $$
	with t as (select hd.header_value as x, c.value as y from public.calc_correction c
	           join public.calc_correction_headers hd on hd.id = c.header_id
	           where c.height_id = par_height_id and hd.type_id = par_type_id)
	select round(l.y + (u.y - l.y) * (par_x - l.x) / greatest(u.x - l.x, 1))::integer
	from (select x, y from t where x <= par_x order by x desc limit 1) l,
	     (select x, y from t where x >= par_x order by x limit 1) u;
$$;

create function public.fn_calc_delta_temperature(par_temperature numeric) returns integer language sql as $$
	select round(par_temperature + case when par_temperature < 0 then 0
	       else public.fn_calc_temperature_interpolation(least(par_temperature, 40)) end - 15.9)::integer;
$$;

create function public.fn_calc_format_signed(par_value integer, par_digits integer) returns text language sql immutable as $$
	select lpad((case when par_value < 0 then (5 * 10 ^ (par_digits - 1) - par_value)::integer else par_value end)::text, par_digits, '0');
$$;

create procedure public.sp_calc_meteo_avg(par_input public.calc_input_params, par_equipment_id integer)
language plpgsql as $$
declare
	var_dt   integer := public.fn_calc_delta_temperature(par_input.temperature);
	var_wind integer := case par_equipment_id when 1 then par_input.wind_speed else par_input.drift_distance end;
	var_min  integer := case par_equipment_id when 1 then 3 else 40 end;   -- слабее - ветер принимается равным нулю
begin
	if par_equipment_id is null or par_equipment_id not in (1, 2) or not coalesce(par_input.temperature between -58 and 58
	   and par_input.pressure between 500 and 900 and par_input.wind_direction between 0 and 59
	   and var_wind between 0 and case par_equipment_id when 1 then 15 else 150 end, false) then
		raise exception 'Некорректные входные данные';
	end if;
	create temp table if not exists calc_meteo_result(height integer, tt integer, hh integer, cc integer); truncate calc_meteo_result;
	insert into calc_meteo_result
	select h.height, public.fn_calc_tt(h.id, var_dt),
	       case when var_wind < var_min then 0 else (par_input.wind_direction + d.value) % 60 end,
	       case when var_wind < var_min then 0 else public.fn_calc_wind(s.id, h.id, var_wind) end
	from public.calc_correction_heights h
	join public.calc_correction_types s on s.parent_id = 2 and s.measurment_equipment_id = par_equipment_id
	left join (select c.height_id, c.value from public.calc_correction c
	           join public.calc_correction_headers hd on hd.id = c.header_id
	           join public.calc_correction_types t on t.id = hd.type_id
	           where t.parent_id = 3 and t.measurment_equipment_id = par_equipment_id) d on d.height_id = h.id;
end;
$$;

comment on function public.fn_calc_tt(integer, integer) is 'TT: сумма значений Таблицы 2 для десятков и единиц отклонения (-13 = -10 + -3); больше 50 берется как 50'; comment on function public.fn_calc_wind(integer, integer, numeric) is 'CC: значение Таблицы 3 между соседними столбцами интерполируется и округляется до 1 м/с';
comment on function public.fn_calc_delta_temperature(numeric) is 'Отклонение приземной виртуальной температуры от +15,9 °C (с виртуальной поправкой из Таблицы 1)'; comment on function public.fn_calc_format_signed(integer, integer) is 'Запись в бюллетень: отрицательное значение - к старшему разряду прибавляется 5 (-7: 507 / 57)';
comment on procedure public.sp_calc_meteo_avg(public.calc_input_params, integer) is 'Приближенный метеобюллетень: вход - параметры и оборудование (1 - ДМК, 2 - ВР); выход - временная таблица calc_meteo_result (H, TT, HH, CC) по типовым высотам';