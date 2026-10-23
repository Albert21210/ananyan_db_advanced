-- Функции для расчета метеопараметров (ДДЧЧМ, ВВВВ, БББТТ)

-- ДДЧЧМ - Дата, часы и десятки минут окончания метеонаблюдений
CREATE OR REPLACE FUNCTION calculate_ddchm(p_day INT, p_hour INT, p_minute INT)
RETURNS TEXT AS $$
BEGIN
    RETURN LPAD(p_day::TEXT, 2, '0') || 
           LPAD(p_hour::TEXT, 2, '0') || 
           TRUNC(p_minute / 10)::TEXT;
END;
$$ LANGUAGE plpgsql;


-- ВВВВ — Высота метеостанции
CREATE OR REPLACE FUNCTION calculate_vvvv(p_height NUMERIC)
RETURNS TEXT AS $$
BEGIN
    RETURN LPAD(TRUNC(p_height)::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;


-- БББТТ — Отклонение давления и температуры
CREATE OR REPLACE FUNCTION calculate_bbbt(p_pressure NUMERIC, p_temperature NUMERIC)
RETURNS TEXT AS $$
DECLARE
    dp INT := ROUND(p_pressure - 750);
    dt INT := ROUND((p_temperature + CASE WHEN p_temperature >= 25 THEN 2.0 ELSE 1.0 END) - 15.9);
BEGIN
    RETURN 
        (CASE WHEN dp >= 0 THEN LPAD(dp::TEXT, 3, '0') ELSE '5' || LPAD(ABS(dp)::TEXT, 2, '0') END) 
        || 
        (CASE WHEN dt >= 0 THEN LPAD(dt::TEXT, 2, '0') ELSE '5' || ABS(dt)::TEXT END);
END;
$$ LANGUAGE plpgsql;

-- Проверка
SELECT calculate_ddchm(15, 14, 30) AS "Результат ДДЧЧМ";

SELECT calculate_vvvv(350.0) AS "Результат ВВВВ";

SELECT calculate_bbbt(765.0, 25.0) AS "Результат БББТТ";