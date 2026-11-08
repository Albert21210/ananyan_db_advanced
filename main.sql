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
		-- Наименование подправлю
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

	-- Отдельная таблица для хранения заголовков, связь со справочником типов
	begin

		create sequence calc_correction_headers_seq;
		create table calc_correction_headers
		(
		        id integer primary key not null default nextval('public.calc_correction_headers_seq'),
		        header_values integer[] not null
		);

		comment on table calc_correction_headers is 'Заголовки таблиц корректировок';
		comment on column calc_correction_headers.id is 'Уникальный код';
		comment on column calc_correction_headers.header_values is 'Значения в заголовке таблицы';

		insert into calc_correction_headers(header_values)
		values(array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50]), -- 1 Таблица 2, отрицательные
		(array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 2 Таблица 2, положительные
		(array[40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]), -- 3 Таблица 3 (ВР)
		(array[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]); -- 4 Таблица 3 (ДМК)

		alter table calc_correction_types add column header_id integer references calc_correction_headers(id);
		comment on column calc_correction_types.header_id is 'Код заголовка таблицы';

		update calc_correction_types set header_id = 1 where id in (1, 9);
		update calc_correction_types set header_id = 2 where id = 8;
		update calc_correction_types set header_id = 3 where id in (4, 5);
		update calc_correction_types set header_id = 4 where id in (6, 7);

		alter table calc_correction_types drop column header_values;

	end;

	-- Исправление данных справочников (Таблица 2, Таблица 3)
	begin

		-- Таблица 2: отрицательные значения загружены с типом 8 (положительные), правильный тип 9
		update calc_correction set type_id = 9 where type_id = 8 and row_values[1] < 0;

		-- Таблица 2: положительные значения загружены с типом 7 (направление ДМК), правильный тип 8
		update calc_correction set type_id = 8 where type_id = 7 and array_length(row_values, 1) = 12;

		-- Таблица 2, 400 м, dT = 40: было -39, по таблице -38
		update calc_correction set row_values[13] = -38 where type_id = 9 and height_id = 2;

		-- Таблица 3 (ДМК), 1200 м, V0 = 11: было 23, по таблице 22
		update calc_correction set row_values[9] = 22 where type_id = 6 and height_id = 4;

	end;

	-- Добавление отсутствующих данных: высоты 1600, 2000, 2400, 3000, 4000 (код высоты 5-9)
	begin

		insert into calc_correction(height_id, type_id, row_values)
		values
		-- Таблица 2, отрицательные значения
		(5, 9, array[-1, -2, -3, -3, -4, -4, -5, -6, -7, -7, -17, -25, -34, -42]), -- 1600
		(6, 9, array[-1, -2, -3, -3, -4, -4, -5, -6, -6, -7, -16, -24, -32, -40]), -- 2000
		(7, 9, array[-1, -2, -2, -3, -4, -4, -5, -5, -6, -7, -15, -23, -31, -38]), -- 2400
		(8, 9, array[-1, -2, -2, -3, -4, -4, -4, -5, -5, -6, -15, -22, -30, -37]), -- 3000
		(9, 9, array[-1, -2, -2, -3, -4, -4, -4, -4, -5, -6, -14, -20, -27, -34]), -- 4000
		-- Таблица 2, положительные значения
		(5, 8, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 1600
		(6, 8, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 2000
		(7, 8, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 2400
		(8, 8, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 3000
		(9, 8, array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30]), -- 4000
		-- Таблица 3, Скорость среднего ветра (ВР)
		(5, 4, array[4, 6, 7, 8, 9, 10, 11, 13, 14, 15, 17, 17]), -- 1600
		(6, 4, array[4, 6, 7, 8, 9, 10, 11, 13, 14, 16, 17, 18]), -- 2000
		(7, 4, array[4, 6, 8, 9, 9, 10, 12, 14, 15, 16, 18, 19]), -- 2400
		(8, 4, array[5, 6, 8, 9, 10, 11, 12, 14, 15, 17, 18, 19]), -- 3000
		(9, 4, array[5, 6, 8, 9, 10, 11, 12, 14, 16, 18, 19, 20]), -- 4000
		-- Таблица 3, Направление среднего ветра (ВР)
		(5, 5, array[3]), -- 1600
		(6, 5, array[3]), -- 2000
		(7, 5, array[3]), -- 2400
		(8, 5, array[4]), -- 3000
		(9, 5, array[4]), -- 4000
		-- Таблица 3, Скорость среднего ветра (ДМК)
		(5, 6, array[6, 8, 11, 13, 14, 17, 20, 21, 23, 25, 27, 29, 32]), -- 1600
		(6, 6, array[6, 9, 11, 13, 14, 17, 20, 21, 24, 26, 28, 30, 32]), -- 2000
		(7, 6, array[6, 9, 12, 14, 15, 18, 21, 22, 25, 27, 29, 32, 34]), -- 2400
		(8, 6, array[6, 9, 12, 14, 15, 18, 21, 23, 25, 28, 30, 32, 36]), -- 3000
		(9, 6, array[6, 10, 12, 14, 16, 19, 22, 24, 26, 29, 32, 34, 36]), -- 4000
		-- Таблица 3, Направление среднего ветра (ДМК)
		(5, 7, array[4]), -- 1600
		(6, 7, array[4]), -- 2000
		(7, 7, array[4]), -- 2400
		(8, 7, array[5]), -- 3000
		(9, 7, array[5]) -- 4000
		;

		alter table calc_correction_types add foreign key (parent_id) references calc_correction_types(id);
		alter table calc_correction add foreign key (height_id) references calc_correction_heights(id),
			add foreign key (type_id) references calc_correction_types(id),
			add unique (height_id, type_id);

	end;

	-- Расчет приближенного метеобюллетеня
	begin

		-- Входящие параметры
		create type public.calc_input_params as
		(
		        height integer,
		        temperature numeric(5, 1),
		        pressure integer,
		        wind_direction integer,
		        wind_speed integer,
		        drift_distance integer
		);

		comment on type public.calc_input_params is 'Входящие параметры для расчета приближенного метеобюллетеня';
		comment on column public.calc_input_params.height is 'Высота метеопоста, м';
		comment on column public.calc_input_params.temperature is 'Температура воздуха, °C (-58..58)';
		comment on column public.calc_input_params.pressure is 'Давление, мм рт. ст. (500..900)';
		comment on column public.calc_input_params.wind_direction is 'Направление ветра, б.д. угломера (0..59)';
		comment on column public.calc_input_params.wind_speed is 'Скорость ветра, м/с (0..15, для ДМК)';
		comment on column public.calc_input_params.drift_distance is 'Дальность сноса пуль, м (0..150, для ВР)';

		-- Отклонение приземной виртуальной температуры от +15,9 °C
		create function public.fn_calc_delta_temperature(par_temperature numeric)
		returns integer
		language sql
		as $f$
		        select round(par_temperature + case when par_temperature < 0 then 0
		                     else public.fn_calc_temperature_interpolation(least(par_temperature, 40)) end - 15.9)::integer
		$f$;

		-- Запись числа в бюллетень: отрицательное - к старшему разряду прибавляется 5 (-7: 507 / 57)
		create function public.fn_calc_format_signed(par_value integer, par_digits integer)
		returns text
		language sql
		immutable
		as $f$
		        select lpad((case when par_value < 0 then (5 * 10 ^ (par_digits - 1) - par_value)::integer
		                          else par_value end)::text, par_digits, '0')
		$f$;

		-- Линейная интерполяция значения по таблице: заголовок + строка значений
		create function public.fn_calc_array_interpolate(par_header integer[], par_values integer[], par_x numeric)
		returns integer
		language sql
		immutable
		as $f$
		        select round(l.y + (u.y - l.y) * (par_x - l.x) / greatest(u.x - l.x, 1))::integer
		        from (select h.v as x, par_values[h.i::integer] as y
		              from unnest(par_header) with ordinality as h(v, i) where h.v <= par_x order by h.v desc limit 1) as l,
		             (select h.v as x, par_values[h.i::integer] as y
		              from unnest(par_header) with ordinality as h(v, i) where h.v >= par_x order by h.v limit 1) as u
		$f$;

		-- Хранимая процедура расчета. Вход: входящие параметры, тип оборудования (1 - ДМК, 2 - ВР).
		-- Выход: временная таблица calc_meteo_result (H, TT, HH, CC) по каждой типовой высоте
		create procedure public.sp_calc_meteo_avg(par_input public.calc_input_params, par_equipment_id integer)
		language plpgsql
		as $proc$
		declare
		        var_dt          integer := public.fn_calc_delta_temperature(par_input.temperature);
		        var_abs         integer := least(abs(var_dt), 50);  -- Таблица 2 заканчивается на 50
		        var_wind        integer := case par_equipment_id when 1 then par_input.wind_speed else par_input.drift_distance end;
		        var_min_wind    integer := case par_equipment_id when 1 then 3 else 40 end;  -- слабее - ветер равен нулю
		        var_type_temp   integer := case when var_dt < 0 then 9 else 8 end;  -- 8 - положительные, 9 - отрицательные
		        var_type_speed  integer;
		        var_type_dir    integer;
		        var_hdr_temp    integer[];
		        var_hdr_speed   integer[];
		begin
		        if par_equipment_id is null or par_equipment_id not in (1, 2)
		           or not coalesce(par_input.temperature between -58 and 58
		                           and par_input.pressure between 500 and 900
		                           and par_input.wind_direction between 0 and 59
		                           and var_wind between 0 and case par_equipment_id when 1 then 15 else 150 end, false) then
		                raise exception 'Некорректные входные данные';
		        end if;

		        select t.id, h.header_values into var_type_speed, var_hdr_speed
		        from calc_correction_types t join calc_correction_headers h on h.id = t.header_id
		        where t.parent_id = 2 and t.measurment_equipment_id = par_equipment_id;

		        select t.id into var_type_dir
		        from calc_correction_types t
		        where t.parent_id = 3 and t.measurment_equipment_id = par_equipment_id;

		        select h.header_values into var_hdr_temp
		        from calc_correction_types t join calc_correction_headers h on h.id = t.header_id
		        where t.id = var_type_temp;

		        create temp table if not exists calc_meteo_result(height integer, tt integer, hh integer, cc integer);
		        truncate calc_meteo_result;

		        -- TT: сумма значений Таблицы 2 для десятков и единиц отклонения (-13 = -10 + -3).
		        -- Положительных значений для 40 и 50 в таблице нет, принимаются равными заголовку
		        insert into calc_meteo_result
		        select ht.height,
		               coalesce(ct.row_values[array_position(var_hdr_temp, var_abs / 10 * 10)], var_abs / 10 * 10)
		               + coalesce(ct.row_values[array_position(var_hdr_temp, var_abs % 10)], var_abs % 10),
		               case when var_wind < var_min_wind then 0
		                    else (par_input.wind_direction + cd.row_values[1]) % 60 end,
		               case when var_wind < var_min_wind then 0
		                    else public.fn_calc_array_interpolate(var_hdr_speed, cs.row_values, var_wind) end
		        from calc_correction_heights ht
		        left join calc_correction ct on ct.height_id = ht.id and ct.type_id = var_type_temp
		        left join calc_correction cs on cs.height_id = ht.id and cs.type_id = var_type_speed
		        left join calc_correction cd on cd.height_id = ht.id and cd.type_id = var_type_dir
		        order by ht.height;
		end;
		$proc$;

		comment on function public.fn_calc_delta_temperature(numeric) is 'Отклонение приземной виртуальной температуры от +15,9 °C (с виртуальной поправкой из Таблицы 1)';
		comment on function public.fn_calc_format_signed(integer, integer) is 'Запись в бюллетень: отрицательное значение - к старшему разряду прибавляется 5 (-7: 507 / 57)';
		comment on function public.fn_calc_array_interpolate(integer[], integer[], numeric) is 'Линейная интерполяция значения по таблице (заголовок + строка значений)';
		comment on procedure public.sp_calc_meteo_avg(public.calc_input_params, integer) is 'Приближенный метеобюллетень: вход - параметры и оборудование (1 - ДМК, 2 - ВР); выход - временная таблица calc_meteo_result (H, TT, HH, CC) по типовым высотам';

	end;

	commit;
	
end $$;
