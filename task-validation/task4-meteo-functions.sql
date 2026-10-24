-- Функции для расчета метеопараметров (ДДЧЧМ, ВВВВ, БББТТ)
-- Сначала запускать 5-й файл, а потом этот
DO $$
BEGIN
    -- ДДЧЧМ - Дата, часы и десятки минут окончания метеонаблюдений
    CREATE OR REPLACE FUNCTION calculate_ddchm(
        p_day INT, p_hour INT, p_minute INT
    )
    RETURNS TEXT LANGUAGE plpgsql AS $f$
    BEGIN
        RETURN LPAD(p_day::TEXT, 2, '0')
            || LPAD(p_hour::TEXT, 2, '0') || (p_minute / 10)::TEXT;
    END;
    $f$;

    -- ВВВВ - Высота метеостанции
    CREATE OR REPLACE FUNCTION calculate_vvvv(p_height NUMERIC)
    RETURNS TEXT LANGUAGE plpgsql AS $f$
    BEGIN
        RETURN LPAD(TRUNC(p_height)::TEXT, 4, '0');
    END;
    $f$;

    -- БББТТ - Отклонение давления и температуры
    CREATE OR REPLACE FUNCTION calculate_bbbt(
        p_pressure NUMERIC, p_temperature NUMERIC
    )
    RETURNS TEXT LANGUAGE plpgsql AS $f$
    DECLARE
        dp INT;
        dt INT;
    BEGIN
        dp := ROUND(p_pressure - get_meteo_constant('STANDARD_PRESSURE'));
        dt := ROUND(p_temperature + CASE
            WHEN p_temperature >= get_meteo_constant('TEMP_THRESHOLD')
                THEN get_meteo_constant('TEMP_CORRECTION_HIGH')
            ELSE get_meteo_constant('TEMP_CORRECTION_LOW')
            END - get_meteo_constant('REFERENCE_VIRTUAL_TEMPERATURE'));

        -- Отрицательные значения
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
    $f$;

    COMMENT ON FUNCTION calculate_ddchm(INT, INT, INT) IS 'Формирует ДДЧЧМ';
    COMMENT ON FUNCTION calculate_vvvv(NUMERIC) IS 'Формирует ВВВВ';
    COMMENT ON FUNCTION calculate_bbbt(NUMERIC, NUMERIC) IS 'Рассчитывает БББТТ с использованием таблицы констант';

END;
$$ LANGUAGE plpgsql;

-- Проверка
SELECT calculate_ddchm(15, 14, 30);

SELECT calculate_vvvv(350.0);

SELECT calculate_bbbt(765, 25); 
