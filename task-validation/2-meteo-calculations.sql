-- Константы и метеорасчеты
DO $$
BEGIN
    -- Таблица констант
    CREATE TABLE IF NOT EXISTS meteo_constants (
        constant_name TEXT PRIMARY KEY,
        constant_value NUMERIC NOT NULL,
        description TEXT
    );

    -- Заполнение констант
    INSERT INTO meteo_constants VALUES
        ('STANDARD_PRESSURE', 750, 'Опорное давление'),
        ('TEMP_THRESHOLD', 25, 'Порог температуры'),
        ('TEMP_CORRECTION_HIGH', 2, 'Высокая температура'),
        ('TEMP_CORRECTION_LOW', 1, 'Низкая температура'),
        ('REFERENCE_VIRTUAL_TEMPERATURE', 15.9, 'Виртуальная температура'),
        ('PRESSURE_SIGN_OFFSET', 500, 'Поправка давления'),
        ('TEMP_SIGN_OFFSET', 50, 'Поправка температуры'),
        ('TEMP_SPECIAL_LIMIT', -50, 'Порог кодирования')
    ON CONFLICT (constant_name) DO UPDATE SET
        constant_value = EXCLUDED.constant_value,
        description = EXCLUDED.description;
END;
$$;

COMMENT ON TABLE meteo_constants IS 'Константы для метеорасчетов';

-- Функция получения константы
CREATE OR REPLACE FUNCTION get_meteo_constant(p_name TEXT)
RETURNS NUMERIC AS $$
DECLARE
    result NUMERIC;
BEGIN
    SELECT constant_value INTO result
    FROM meteo_constants
    WHERE constant_name = p_name;

    IF result IS NULL THEN
        RAISE EXCEPTION 'Константа не найдена: %', p_name;
    END IF;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_meteo_constant(TEXT)
IS 'Получение константы по имени';

-- ДДЧЧМ - Дата, часы и десятки минут окончания метеонаблюдений
CREATE OR REPLACE FUNCTION calculate_ddchm(
    p_day INT, p_hour INT, p_minute INT
)
RETURNS TEXT AS $$
BEGIN
    IF p_day NOT BETWEEN 1 AND 31
       OR p_hour NOT BETWEEN 0 AND 23
       OR p_minute NOT BETWEEN 0 AND 59 THEN
        RAISE EXCEPTION 'Неверная дата или время';
    END IF;

    RETURN LPAD(p_day::TEXT, 2, '0')
        || LPAD(p_hour::TEXT, 2, '0')
        || (p_minute / 10)::TEXT;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_ddchm(INT, INT, INT)
IS 'Расчет ДДЧЧМ';

-- ВВВВ - Высота метеостанции
CREATE OR REPLACE FUNCTION calculate_vvvv(p_height NUMERIC)
RETURNS TEXT AS $$
BEGIN
    RETURN LPAD(TRUNC(p_height)::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_vvvv(NUMERIC)
IS 'Расчет ВВВВ';

-- БББТТ - Отклонение давления и температуры
CREATE OR REPLACE FUNCTION calculate_bbbt(
    p_pressure NUMERIC, p_temperature NUMERIC
)
RETURNS TEXT AS $$
DECLARE
    dp INT;
    dt INT;
BEGIN
    dp := ROUND(p_pressure - get_meteo_constant('STANDARD_PRESSURE'));

    IF p_temperature >= get_meteo_constant('TEMP_THRESHOLD') THEN
        dt := ROUND(p_temperature
            + get_meteo_constant('TEMP_CORRECTION_HIGH')
            - get_meteo_constant('REFERENCE_VIRTUAL_TEMPERATURE'));
    ELSE
        dt := ROUND(p_temperature
            + get_meteo_constant('TEMP_CORRECTION_LOW')
            - get_meteo_constant('REFERENCE_VIRTUAL_TEMPERATURE'));
    END IF;

    IF dp < 0 THEN
        dp := ABS(dp) + get_meteo_constant('PRESSURE_SIGN_OFFSET');
    END IF;

    IF dt <= get_meteo_constant('TEMP_SPECIAL_LIMIT') THEN
        dt := ABS(dt);
    ELSIF dt < 0 THEN
        dt := ABS(dt) + get_meteo_constant('TEMP_SIGN_OFFSET');
    END IF;

    RETURN LPAD(dp::TEXT, 3, '0') || LPAD(dt::TEXT, 2, '0');
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calculate_bbbt(NUMERIC, NUMERIC)
IS 'Расчет БББТТ';

-- Проверка функций
SELECT calculate_ddchm(15, 14, 30) AS "ДДЧЧМ";
SELECT calculate_vvvv(350) AS "ВВВВ";
SELECT calculate_bbbt(765, 25) AS "БББТТ";