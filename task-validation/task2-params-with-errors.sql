-- Получение исходных данных из таблиц первой миграции
WITH source_data AS (
    SELECT
        b.batch_id,
        b.batch_code,
        e.type_name,
        p.param_name,
        b.param_value,
        CASE p.param_name
            WHEN 'Высота метеопоста' THEN 'station_height'
            WHEN 'Температура' THEN 'temperature'
            WHEN 'Давление' THEN 'pressure'
            WHEN 'Атмосферное давление' THEN 'pressure'
            WHEN 'Направление ветра' THEN 'wind_direction'
            WHEN 'Скорость ветра' THEN 'wind_speed'
            WHEN 'Дальность сноса пуль' THEN 'bullet_drift'
        END AS rule_name
    FROM batches b
    LEFT JOIN equipment_types e
        ON e.equipment_type_id = b.equipment_type_id
    LEFT JOIN parameters p ON p.parameter_id = b.parameter_id
),

-- Проверка имеющихся числовых значений по таблице правил
checked AS (
    SELECT d.*,
        CASE
            WHEN r.param_name IS NULL
                THEN 'Нет правила для параметра: ' || COALESCE(d.param_name, 'неизвестен')
            WHEN d.param_value::NUMERIC < r.min_val
              OR d.param_value::NUMERIC > r.max_val
                THEN COALESCE(r.error_message, 'Значение вне диапазона')
        END AS error
    FROM source_data d
    LEFT JOIN meteo_validation_rules r ON r.param_name = d.rule_name
)

-- Извлечение данных из набора и вывод таблицы
SELECT
    batch_code AS "№",
    type_name AS "Тип оборудования",
    MAX(CASE WHEN rule_name = 'station_height' THEN param_value END) AS "Высота метеопоста",
    MAX(CASE WHEN rule_name = 'temperature' THEN param_value END) AS "Температура",
    MAX(CASE WHEN rule_name = 'pressure' THEN param_value END) AS "Давление",
    MAX(CASE WHEN rule_name = 'wind_direction' THEN param_value END) AS "Направление ветра",
    MAX(CASE WHEN rule_name = 'wind_speed' THEN param_value END) AS "Скорость ветра",
    MAX(CASE WHEN rule_name = 'bullet_drift' THEN param_value END) AS "Дальность сноса пуль",
    COUNT(error) > 0 AS "Флаг: Есть ошибка",
    COALESCE(string_agg(error, '; '), 'Ошибок в имеющихся значениях нет') AS "Описание ошибки"
FROM checked
GROUP BY batch_code, type_name
ORDER BY batch_code, type_name;
