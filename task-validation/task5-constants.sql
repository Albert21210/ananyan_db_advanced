-- Управление константами и справочными значениями
DROP TABLE IF EXISTS meteo_constants CASCADE;

-- Создание таблицы для хранения системных метеоконстант
CREATE TABLE IF NOT EXISTS meteo_constants (
    constant_name VARCHAR(50) PRIMARY KEY,
    constant_value NUMERIC NOT NULL,
    description TEXT
);

-- Заполнение базовых табличных и стандартных значений
INSERT INTO meteo_constants (constant_name, constant_value, description) 
VALUES 
    ('STANDARD_PRESSURE', 750.0, 'Стандартное атмосферное давление (мм рт. ст.)'),
    ('STANDARD_TEMPERATURE', 15.0, 'Стандартная температура воздуха (°С)'),
    ('MAX_WIND_SPEED', 50.0, 'Максимально допустимая скорость ветра (м/с)')
ON CONFLICT (constant_name) DO NOTHING;

-- Функция для безопасного получения значения константы по ее имени
CREATE OR REPLACE FUNCTION get_meteo_constant(p_name VARCHAR)
RETURNS NUMERIC AS $$
DECLARE
    v_val NUMERIC;
BEGIN
    SELECT constant_value INTO v_val
    FROM meteo_constants
    WHERE constant_name = p_name;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Константа с именем "%" не найдена в справочнике', p_name;
    END IF;
    
    RETURN v_val;
END;
$$ LANGUAGE plpgsql;

-- Проверка
SELECT * FROM meteo_constants;

SELECT get_meteo_constant('STANDARD_PRESSURE') AS "Стандартное давление";

SELECT get_meteo_constant('UNKNOWN_CONSTANT');