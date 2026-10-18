-- Создание пользовательского типа данных для интерполяции (x0, y0, x1, y1)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'interpolation_interval') THEN
        CREATE TYPE interpolation_interval AS (
            x0 NUMERIC,
            y0 NUMERIC,
            x1 NUMERIC,
            y1 NUMERIC
        );
    END IF;
END $$;


-- Создание функции для определения параметров (интервала) по температуре
CREATE OR REPLACE FUNCTION get_interpolation_interval(p_temp NUMERIC)
RETURNS interpolation_interval AS $$
DECLARE
    v_result interpolation_interval;
BEGIN
    -- Логика выбора опорных точек (интервала) в зависимости от температуры
    IF p_temp <= -20 THEN
        v_result := (-30, 1.2, -20, 1.0);
    ELSIF p_temp <= 0 THEN
        v_result := (-20, 1.0, 0, 0.8);
    ELSIF p_temp <= 20 THEN
        v_result := (0, 0.8, 20, 0.6);
    ELSE
        v_result := (20, 0.6, 40, 0.4);
    END IF;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;


-- Создание функции для расчета интерполяции
CREATE OR REPLACE FUNCTION calculate_interpolation(p_x NUMERIC, p_interval interpolation_interval)
RETURNS NUMERIC AS $$
DECLARE
    v_y NUMERIC;
BEGIN
    -- Защита от деления на ноль, если x1 равно x0
    IF p_interval.x1 = p_interval.x0 THEN
        RETURN p_interval.y0;
    END IF;
    
    -- Формула линейной интерполяции: y = y0 + (x - x0) * (y1 - y0) / (x1 - x0)
    v_y := p_interval.y0 + (p_x - p_interval.x0) * (p_interval.y1 - p_interval.y0) / (p_interval.x1 - p_interval.x0);
    
    RETURN v_y;
END;
$$ LANGUAGE plpgsql;


-- Проверочный скрипт
SELECT 
    t.val AS "Температура (x)",
    (get_interpolation_interval(t.val)).x0 AS "x0",
    (get_interpolation_interval(t.val)).y0 AS "y0",
    (get_interpolation_interval(t.val)).x1 AS "x1",
    (get_interpolation_interval(t.val)).y1 AS "y1",
    calculate_interpolation(t.val, get_interpolation_interval(t.val)) AS "Результат (y)"
FROM (
    VALUES (-25::NUMERIC), (-10::NUMERIC), (10::NUMERIC), (30::NUMERIC)
) AS t(val);