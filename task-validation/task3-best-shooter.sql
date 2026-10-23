-- Запрос "Лучший стрелок" 

WITH evaluated_packets AS (
    -- Проверка каждого пакета каждого пользователя на ошибки
    SELECT 
        user_name,
        check_meteo_parameters(
            (equipment_type, station_height, temperature, pressure, wind_direction, wind_speed, bullet_drift)::meteo_input_params
        ) AS err
    FROM meteo_packets
),
error_counted AS (
    -- Группировка по пользователям и расчет количества ошибочных пакетов
    SELECT 
        user_name,
        COUNT(CASE WHEN err != 'Ошибок нет' THEN 1 END) AS error_count,
        COUNT(*) AS total_packets
    FROM evaluated_packets
    GROUP BY user_name
)

-- Вывод итогового рейтинга
SELECT 
    user_name AS "Пользователь (Стрелок)",
    error_count AS "Количество ошибок",
    total_packets AS "Всего пакетов",
    RANK() OVER (ORDER BY error_count ASC) AS "Ранг"
FROM error_counted
ORDER BY error_count ASC;