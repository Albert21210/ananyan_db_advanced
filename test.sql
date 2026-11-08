do $$
declare v text;
begin
	-- Тест 1. Пример 2 из ТЗ (ДМК): высота 100, давление 765, температура 25, направление 15, скорость 6
	call public.sp_calc_meteo_avg(row(100, 25, 765, 15, 6, 0)::public.calc_input_params, 1);
	select string_agg(format('%s:%s/%s/%s', height, tt, hh, cc), ' ' order by height) into v from calc_meteo_result;
	assert v = '200:11/16/9 400:11/17/11 800:11/18/11 1200:11/18/12 1600:11/19/13 2000:11/19/13 2400:11/19/14 3000:11/20/14 4000:11/20/14', 'Тест 1 (ДМК): ' || v;
	assert public.fn_calc_format_signed(765 - 750, 3) || public.fn_calc_format_signed(public.fn_calc_delta_temperature(25), 2) = '01511', 'БББТТ';

	-- Тест 2. Ветровое ружье, отрицательные значения: давление 743, температура -10, направление 15, снос 70
	call public.sp_calc_meteo_avg(row(100, -10, 743, 15, 0, 70)::public.calc_input_params, 2);
	select string_agg(format('%s:%s/%s/%s', height, tt, hh, cc), ' ' order by height) into v from calc_meteo_result;
	assert v = '200:-26/15/6 400:-25/16/7 800:-24/17/7 1200:-22/17/8 1600:-21/18/8 2000:-20/18/8 2400:-19/18/9 3000:-19/19/9 4000:-18/19/9', 'Тест 2 (ВР): ' || v;

	-- Тест 3. Слабый ветер (2 м/с < 3): направление и скорость нулевые; dT = -16: 200 м = -9 + -6 = -15
	call public.sp_calc_meteo_avg(row(100, -0.5, 750, 15, 2, 0)::public.calc_input_params, 1);
	assert (select tt from calc_meteo_result where height = 200) = -15
	   and (select count(*) from calc_meteo_result where hh = 0 and cc = 0) = 9, 'Тест 3';

	raise notice 'Все тесты пройдены';
end $$;

-- Результат для скриншота: пример 2 из ТЗ (ДМК). БББТТ = 01511
call public.sp_calc_meteo_avg(row(100, 25, 765, 15, 6, 0)::public.calc_input_params, 1);
select height as "H", public.fn_calc_format_signed(tt, 2) as "TT", lpad(hh::text, 2, '0') as "HH", lpad(cc::text, 2, '0') as "CC"
from calc_meteo_result order by height;
