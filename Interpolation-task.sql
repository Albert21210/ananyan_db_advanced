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

    -- Создание таблицы-справочника опорных температур и значений
    CREATE TABLE IF NOT EXISTS temperature_points (
        temp NUMERIC PRIMARY KEY,
        val NUMERIC NOT NULL
    );

    -- Заполнение таблицы базовыми опорными данными
    IF NOT EXISTS (SELECT 1 FROM temperature_points LIMIT 1) THEN
        INSERT INTO temperature_points (temp, val) VALUES
            (-30, 1.2),
            (-20, 1.0),
            (0,   0.8),
            (20,  0.6),
            (40,  0.4);
    END IF;

    -- Функция для динамического определения интервала (x0, y0, x1, y1) из таблицы
    CREATE OR REPLACE FUNCTION get_interpolation_interval(p_temp NUMERIC)
    RETURNS interpolation_interval AS $fn$
    DECLARE
        v_result interpolation_interval;
    BEGIN
        -- Ищем нижнюю границу (x0, y0): максимальная точка <= p_temp
        SELECT temp, val INTO v_result.x0, v_result.y0
        FROM temperature_points
        WHERE temp <= p_temp
        ORDER BY temp DESC
        LIMIT 1;

        -- Ищем верхнюю границу (x1, y1): минимальная точка > p_temp
        SELECT temp, val INTO v_result.x1, v_result.y1
        FROM temperature_points
        WHERE temp > p_temp
        ORDER BY temp ASC
        LIMIT 1;

        -- Обработка граничных случаев (если точка выходит за пределы таблицы)
        IF v_result.x0 IS NULL THEN
            SELECT temp, val INTO v_result.x0, v_result.y0 FROM temperature_points ORDER BY temp ASC LIMIT 1 OFFSET 0;
            SELECT temp, val INTO v_result.x1, v_result.y1 FROM temperature_points ORDER BY temp ASC LIMIT 1 OFFSET 1;
        ELSIF v_result.x1 IS NULL THEN
            SELECT temp, val INTO v_result.x0, v_result.y0 FROM temperature_points ORDER BY temp DESC LIMIT 1 OFFSET 1;
            SELECT temp, val INTO v_result.x1, v_result.y1 FROM temperature_points ORDER BY temp DESC LIMIT 1 OFFSET 0;
        END IF;

        RETURN v_result;
    END;
    $fn$ LANGUAGE plpgsql;

    -- Функция расчёта линейной интерполяции
    CREATE OR REPLACE FUNCTION calculate_interpolation(p_x NUMERIC, p_interval interpolation_interval)
    RETURNS NUMERIC AS $fn$
    BEGIN
        IF p_interval.x1 = p_interval.x0 THEN
            RETURN p_interval.y0;
        END IF;
        RETURN p_interval.y0 + (p_x - p_interval.x0) * (p_interval.y1 - p_interval.y0) / (p_interval.x1 - p_interval.x0);
    END;
    $fn$ LANGUAGE plpgsql;

END $$;


-- Проверочный скрипт
SELECT 
    t.test_temp AS "Температура (х)",
    (get_interpolation_interval(t.test_temp)).x0 AS "x0",
    (get_interpolation_interval(t.test_temp)).y0 AS "y0",
    (get_interpolation_interval(t.test_temp)).x1 AS "x1",
    (get_interpolation_interval(t.test_temp)).y1 AS "y1",
    calculate_interpolation(t.test_temp, get_interpolation_interval(t.test_temp)) AS "Результат (y)"
FROM (
    VALUES 
        (-25::NUMERIC), 
        (-10::NUMERIC), 
        (10::NUMERIC), 
        (30::NUMERIC)
) AS t(test_temp);
