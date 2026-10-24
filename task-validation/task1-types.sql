DO $$
BEGIN
    -- Тип для параметров
    BEGIN
        IF to_regtype('meteo_input_params') IS NULL THEN
            CREATE TYPE meteo_input_params AS (
                equipment_type TEXT, station_height NUMERIC,
                temperature NUMERIC, pressure NUMERIC,
                wind_direction NUMERIC, wind_speed NUMERIC, bullet_drift NUMERIC
            );
        END IF;
        COMMENT ON TYPE meteo_input_params IS 'Входные метеопараметры';

        -- Создание таблицы для хранения граничных условий
        CREATE TABLE IF NOT EXISTS meteo_validation_rules (
            param_name VARCHAR(50) PRIMARY KEY,
            min_val NUMERIC NOT NULL, max_val NUMERIC NOT NULL,
            error_message TEXT NOT NULL
        );
        COMMENT ON TABLE meteo_validation_rules IS 'Правила проверки параметров';

        -- Заполние правил проверки
        INSERT INTO meteo_validation_rules VALUES
            ('station_height', 0, 5000, 'Неверная высота'),
            ('temperature', -60, 60, 'Неверная температура'),
            ('pressure', 400, 800, 'Неверное давление'),
            ('wind_direction', 0, 360, 'Неверное направление ветра'),
            ('wind_speed', 0, 50, 'Неверная скорость ветра'),
            ('bullet_drift', -500, 500, 'Неверный снос пуль')
        ON CONFLICT (param_name) DO UPDATE
        SET min_val = EXCLUDED.min_val, max_val = EXCLUDED.max_val,
            error_message = EXCLUDED.error_message;

        -- Проверка значений и объединие всех ошибкок в строку
        CREATE OR REPLACE FUNCTION check_meteo_parameters(p meteo_input_params)
        RETURNS TEXT LANGUAGE plpgsql AS $f$
        DECLARE
            errors TEXT;
        BEGIN
            WITH data(name, value) AS (
                VALUES ('station_height', p.station_height),
                       ('temperature', p.temperature), ('pressure', p.pressure),
                       ('wind_direction', p.wind_direction),
                       ('wind_speed', p.wind_speed), ('bullet_drift', p.bullet_drift)
            )
            SELECT string_agg(CASE
                WHEN r.param_name IS NULL THEN 'Нет правила: ' || d.name
                WHEN d.value IS NULL OR d.value < r.min_val
                    OR d.value > r.max_val THEN r.error_message
                END, '; ' ORDER BY d.name)
            INTO errors
            FROM data d LEFT JOIN meteo_validation_rules r ON r.param_name = d.name;

            IF p.equipment_type IS NULL OR p.equipment_type = '' THEN
                errors := 'Не указан тип оборудования; ' || COALESCE(errors, '');
            END IF;
            RETURN COALESCE(errors, 'Ошибок нет');
        END;
        $f$;
        COMMENT ON FUNCTION check_meteo_parameters(meteo_input_params)
            IS 'Возвращает все ошибки по табличным правилам';
    END;

    -- Вывод результата
    RAISE NOTICE '%', check_meteo_parameters(
        ('АП-11', 150, -25, 760, 180, 10, 5)::meteo_input_params
    );
END;
$$ LANGUAGE plpgsql;
