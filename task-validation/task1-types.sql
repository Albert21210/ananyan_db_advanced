-- Тип для параметров
DROP TYPE IF EXISTS meteo_input_params CASCADE;
CREATE TYPE meteo_input_params AS (
    equipment_type TEXT,
    station_height NUMERIC,
    temperature NUMERIC,
    pressure NUMERIC,
    wind_direction NUMERIC,
    wind_speed NUMERIC,
    bullet_drift NUMERIC
);
COMMENT ON TYPE meteo_input_params IS 'Тип данных для передачи метеопакетов';

-- Создание таблицы для хранения граничных условий
CREATE TABLE IF NOT EXISTS meteo_validation_rules (
    param_name VARCHAR(50) PRIMARY KEY,
    min_val NUMERIC NOT NULL,
    max_val NUMERIC NOT NULL,
    error_message TEXT NOT NULL
);
COMMENT ON TABLE meteo_validation_rules IS 'Справочник допустимых диапазонов для валидации';

-- Заполнение справочника правил
DO $$
BEGIN
    INSERT INTO meteo_validation_rules (param_name, min_val, max_val, error_message) VALUES
        ('station_height', 0, 5000, 'Ошибка: Неверная высота'),
        ('temperature', -60, 60, 'Ошибка: Неверная температура'),
        ('pressure', 400, 800, 'Ошибка: Неверное давление'),
        ('wind_direction', 0, 360, 'Ошибка: Неверный ветер (направление)'),
        ('wind_speed', 0, 50, 'Ошибка: Неверная скорость ветра'),
        ('bullet_drift', -500, 500, 'Ошибка: Неверный снос пуль')
    ON CONFLICT (param_name) DO UPDATE 
    SET min_val = EXCLUDED.min_val, 
        max_val = EXCLUDED.max_val, 
        error_message = EXCLUDED.error_message;
END;
$$;

-- Функция проверки на ошибки
CREATE OR REPLACE FUNCTION check_meteo_parameters(p meteo_input_params)
RETURNS TEXT AS $$
DECLARE
    r RECORD;
BEGIN
    -- Проверка высоты станции
    SELECT min_val, max_val, error_message INTO r FROM meteo_validation_rules WHERE param_name = 'station_height';
    IF p.station_height < r.min_val OR p.station_height > r.max_val THEN 
        RETURN r.error_message; 
    END IF;

    -- Проверка температуры
    SELECT min_val, max_val, error_message INTO r FROM meteo_validation_rules WHERE param_name = 'temperature';
    IF p.temperature < r.min_val OR p.temperature > r.max_val THEN 
        RETURN r.error_message; 
    END IF;

    -- Проверка давления
    SELECT min_val, max_val, error_message INTO r FROM meteo_validation_rules WHERE param_name = 'pressure';
    IF p.pressure < r.min_val OR p.pressure > r.max_val THEN 
        RETURN r.error_message; 
    END IF;

    -- Проверка направления ветра
    SELECT min_val, max_val, error_message INTO r FROM meteo_validation_rules WHERE param_name = 'wind_direction';
    IF p.wind_direction < r.min_val OR p.wind_direction > r.max_val THEN 
        RETURN r.error_message; 
    END IF;

    -- Проверка скорости ветра
    SELECT min_val, max_val, error_message INTO r FROM meteo_validation_rules WHERE param_name = 'wind_speed';
    IF p.wind_speed < r.min_val OR p.wind_speed > r.max_val THEN 
        RETURN r.error_message; 
    END IF;

    -- Проверка сноса пуль
    SELECT min_val, max_val, error_message INTO r FROM meteo_validation_rules WHERE param_name = 'bullet_drift';
    IF p.bullet_drift < r.min_val OR p.bullet_drift > r.max_val THEN 
        RETURN r.error_message; 
    END IF;

    RETURN 'Ошибок нет';
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION check_meteo_parameters(meteo_input_params) IS 'Функция валидации метеопараметров по справочнику правил';

-- Проверка
DO $$
DECLARE
    v_test meteo_input_params;
    v_result TEXT;
BEGIN
    v_test := ROW('АП-11', 150, -25, 760, 180, 10, 5)::meteo_input_params;
    v_result := check_meteo_parameters(v_test);
    RAISE NOTICE 'Результат проверки: %', v_result;
END;
$$;
