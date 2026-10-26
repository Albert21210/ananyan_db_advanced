-- Проверка параметров и отчеты
DO $$
BEGIN
    -- Тип для параметров
    BEGIN
        CREATE TYPE meteo_input_params AS (
            equipment_type TEXT,
            station_height NUMERIC,
            temperature NUMERIC,
            pressure NUMERIC,
            wind_direction NUMERIC,
            wind_speed NUMERIC,
            bullet_drift NUMERIC
        );
    EXCEPTION WHEN duplicate_object THEN
        RAISE NOTICE 'Тип уже существует';
    END;

    -- Таблица правил проверки
    CREATE TABLE IF NOT EXISTS meteo_validation_rules (
        param_name TEXT PRIMARY KEY,
        min_val NUMERIC,
        max_val NUMERIC,
        error_message TEXT
    );

    -- Заполнение правил
    INSERT INTO meteo_validation_rules VALUES
        ('station_height', 0, 5000, 'Неверная высота'),
        ('temperature', -60, 60, 'Неверная температура'),
        ('pressure', 400, 800, 'Неверное давление'),
        ('wind_direction', 0, 360, 'Неверное направление ветра'),
        ('wind_speed', 0, 50, 'Неверная скорость ветра'),
        ('bullet_drift', -500, 500, 'Неверный снос пуль'),
        ('Температура', -60, 60, 'Неверная температура'),
        ('Вес', 0, 100, 'Неверный вес')
    ON CONFLICT (param_name) DO NOTHING;
END;
$$;

COMMENT ON TYPE meteo_input_params IS 'Входные метеопараметры';
COMMENT ON TABLE meteo_validation_rules IS 'Правила проверки параметров';

-- Функция проверки параметров
CREATE OR REPLACE FUNCTION check_meteo_parameters(p meteo_input_params)
RETURNS TEXT AS $$
DECLARE
    errors TEXT;
BEGIN
    SELECT string_agg(
        CASE
            WHEN r.param_name IS NULL THEN 'Нет правила: ' || d.name
            WHEN d.val IS NULL OR d.val < r.min_val OR d.val > r.max_val
                THEN r.error_message
        END, '; ')
    INTO errors
    FROM (VALUES
        ('station_height', p.station_height),
        ('temperature', p.temperature),
        ('pressure', p.pressure),
        ('wind_direction', p.wind_direction),
        ('wind_speed', p.wind_speed),
        ('bullet_drift', p.bullet_drift)
    ) AS d(name, val)
    LEFT JOIN meteo_validation_rules r ON r.param_name = d.name;

    IF p.equipment_type IS NULL OR trim(p.equipment_type) = '' THEN
        errors := concat_ws('; ', 'Не указан тип оборудования', errors);
    END IF;

    RETURN COALESCE(errors, 'Ошибок нет');
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION check_meteo_parameters(meteo_input_params)
IS 'Проверка корректности параметров';

-- Проверка функции
SELECT check_meteo_parameters(
    ROW('АП-11', 150, -25, 760, 180, 10, 5)::meteo_input_params
);

-- Список параметров с ошибками
WITH data AS (
    SELECT b.batch_code, e.type_name, p.param_name,
           b.param_value,
           CASE
               WHEN trim(b.param_value) ~ '^[+-]?[0-9]+([.][0-9]+)?$'
               THEN b.param_value::NUMERIC
           END AS value
    FROM batches b
    JOIN equipment_types e ON b.equipment_type_id = e.equipment_type_id
    JOIN parameters p ON b.parameter_id = p.parameter_id
),
checked AS (
    SELECT d.*,
        CASE
            WHEN r.param_name IS NULL THEN 'Нет правила: ' || d.param_name
            WHEN d.value IS NULL THEN 'Некорректное число: ' || d.param_value
            WHEN d.value < r.min_val OR d.value > r.max_val
                THEN r.error_message
        END AS error
    FROM data d
    LEFT JOIN meteo_validation_rules r ON d.param_name = r.param_name
)
SELECT
    batch_code AS "№",
    type_name AS "Тип оборудования",
    MAX(CASE WHEN param_name = 'Высота метеопоста' THEN param_value END) AS "Высота метеопоста",
    MAX(CASE WHEN param_name = 'Температура' THEN param_value END) AS "Температура",
    MAX(CASE WHEN param_name IN ('Давление', 'Атмосферное давление') THEN param_value END) AS "Давление",
    MAX(CASE WHEN param_name = 'Направление ветра' THEN param_value END) AS "Направление ветра",
    MAX(CASE WHEN param_name = 'Скорость ветра' THEN param_value END) AS "Скорость ветра",
    MAX(CASE WHEN param_name = 'Дальность сноса пуль' THEN param_value END) AS "Дальность сноса пуль",
    COUNT(error) > 0 AS "Флаг: Есть ошибка",
    COALESCE(string_agg(error, '; '), 'Ошибок нет') AS "Описание ошибки"
FROM checked
GROUP BY batch_code, type_name
ORDER BY batch_code;

-- Лучший стрелок
WITH data AS (
    SELECT u.full_name, p.param_name, b.param_value,
        CASE
            WHEN trim(b.param_value) ~ '^[+-]?[0-9]+([.][0-9]+)?$'
            THEN b.param_value::NUMERIC
        END AS value
    FROM batches b
    JOIN users u ON b.user_id = u.user_id
    JOIN parameters p ON b.parameter_id = p.parameter_id
),
checked AS (
    SELECT d.full_name,
        CASE
            WHEN r.param_name IS NULL OR d.value IS NULL
              OR d.value < r.min_val OR d.value > r.max_val
            THEN 1 ELSE 0
        END AS error
    FROM data d
    LEFT JOIN meteo_validation_rules r ON d.param_name = r.param_name
),
totals AS (
    SELECT full_name, SUM(error) AS errors, COUNT(*) AS total
    FROM checked
    GROUP BY full_name
)
SELECT
    full_name AS "Пользователь",
    errors AS "Количество ошибок",
    total AS "Всего измерений",
    RANK() OVER (ORDER BY errors) AS "Ранг"
FROM totals
ORDER BY errors, full_name;