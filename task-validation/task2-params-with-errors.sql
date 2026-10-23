-- Создание таблицы для хранения пакетов метеоданных
CREATE TABLE IF NOT EXISTS meteo_packets (
    id SERIAL PRIMARY KEY,
    batch_code INT NOT NULL,           -- Код пачки 
    equipment_type TEXT NOT NULL,      -- Тип оборудования (например, АП-11)
    station_height NUMERIC NOT NULL,   -- Высота метеопоста
    temperature NUMERIC NOT NULL,      -- Температура
    pressure NUMERIC NOT NULL,         -- Давление
    wind_direction NUMERIC NOT NULL,   -- Направление ветра
    wind_speed NUMERIC NOT NULL,       -- Скорость ветра
    bullet_drift NUMERIC NOT NULL      -- Дальность сноса пуль
);

-- Заполнение тестовыми данными
INSERT INTO meteo_packets (batch_code, equipment_type, station_height, temperature, pressure, wind_direction, wind_speed, bullet_drift) 
SELECT 101, 'АП-11', 150, -20, 760, 180, 10, 5 WHERE NOT EXISTS (SELECT 1 FROM meteo_packets WHERE batch_code = 101);

INSERT INTO meteo_packets (batch_code, equipment_type, station_height, temperature, pressure, wind_direction, wind_speed, bullet_drift) 
SELECT 102, 'АП-11', -50, -75, 760, 400, 10, 5 WHERE NOT EXISTS (SELECT 1 FROM meteo_packets WHERE batch_code = 102);

INSERT INTO meteo_packets (batch_code, equipment_type, station_height, temperature, pressure, wind_direction, wind_speed, bullet_drift) 
SELECT 103, 'МТ-1',  300,  15, 300,  90,  5,  2 WHERE NOT EXISTS (SELECT 1 FROM meteo_packets WHERE batch_code = 103);


-- Основной запрос "Список параметров с ошибками" с использованием CTE
WITH evaluated_packets AS (
    SELECT 
        batch_code,
        equipment_type,
        station_height,
        temperature,
        pressure,
        wind_direction,
        wind_speed,
        bullet_drift,
        -- Передача поля как композитный тип meteo_input_params в функцию валидации
        check_meteo_parameters(
            (equipment_type, station_height, temperature, pressure, wind_direction, wind_speed, bullet_drift)::meteo_input_params
        ) AS error_result
    FROM meteo_packets
)

-- Извлечение данных из временного набора CTE и вывод таблицы
SELECT 
    batch_code AS "№",
    equipment_type AS "Тип оборудования",
    station_height AS "Высота метеопоста",
    temperature AS "Температура",
    pressure AS "Давление",
    wind_direction AS "Направление ветра",
    wind_speed AS "Скорость ветра",
    bullet_drift AS "Дальность сноса пуль",
    -- Флаг: Есть ошибка
    CASE 
        WHEN error_result = 'Ошибок нет' THEN 'Нет'
        ELSE 'Да'
    END AS "Флаг: Есть ошибка",
    error_result AS "Описание ошибки"
FROM evaluated_packets;