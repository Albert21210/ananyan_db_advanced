-- Тип для параметров
DROP TYPE IF EXISTS meteo_input_params CASCADE;
CREATE TYPE meteo_input_params AS (
    equipment_type TEXT,
    station_height NUMERIC,
    temperature    NUMERIC,
    pressure       NUMERIC,
    wind_direction NUMERIC,
    wind_speed     NUMERIC,
    bullet_drift   NUMERIC
);

-- Функция проверки на ошибки
CREATE OR REPLACE FUNCTION check_meteo_parameters(p meteo_input_params)
RETURNS TEXT AS $$
BEGIN
    IF p.station_height < 0 OR p.station_height > 5000 THEN 
        RETURN 'Ошибка: Неверная высота'; 
    END IF;
    IF p.temperature < -60 OR p.temperature > 60 THEN 
        RETURN 'Ошибка: Неверная температура'; 
    END IF;
    IF p.pressure < 400 OR p.pressure > 800 THEN 
        RETURN 'Ошибка: Неверное давление'; 
    END IF;
    IF p.wind_direction < 0 OR p.wind_direction > 360 THEN 
        RETURN 'Ошибка: Неверный ветер (направление)'; 
    END IF;
    IF p.wind_speed < 0 OR p.wind_speed > 50 THEN 
        RETURN 'Ошибка: Неверная скорость ветра'; 
    END IF;
    IF p.bullet_drift < -500 OR p.bullet_drift > 500 THEN 
        RETURN 'Ошибка: Неверный снос пуль'; 
    END IF;

    RETURN 'Ошибок нет';
END;
$$ LANGUAGE plpgsql;

-- Блок проверки
SELECT check_meteo_parameters(
    ('АП-11', 150, -25, 760, 180, 10, 5)::meteo_input_params
) AS "Результат проверки первой функции";