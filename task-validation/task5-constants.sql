DO $$
BEGIN
    -- Создание таблицы констант
    CREATE TABLE IF NOT EXISTS meteo_constants (
        constant_name VARCHAR(50) PRIMARY KEY,
        constant_value NUMERIC NOT NULL,
        description TEXT
    );

    -- Запись значений для расчетов
    INSERT INTO meteo_constants VALUES
        ('STANDARD_PRESSURE', 750, 'Опорное давление'),
        ('TEMP_THRESHOLD', 25, 'Порог температурной поправки'),
        ('TEMP_CORRECTION_HIGH', 2, 'Поправка при высокой температуре'),
        ('TEMP_CORRECTION_LOW', 1, 'Поправка при низкой температуре'),
        ('REFERENCE_VIRTUAL_TEMPERATURE', 15.9, 'Опорная виртуальная температура'),
        ('PRESSURE_SIGN_OFFSET', 500, 'Добавка для отрицательного давления'),
        ('TEMP_SIGN_OFFSET', 50, 'Добавка для отрицательной температуры'),
        ('TEMP_SPECIAL_LIMIT', -50, 'Порог особого кодирования температуры')
    ON CONFLICT (constant_name) DO UPDATE
    SET constant_value = EXCLUDED.constant_value,
        description = EXCLUDED.description;

    -- Получение констант по имени
    CREATE OR REPLACE FUNCTION get_meteo_constant(p_name VARCHAR)
    RETURNS NUMERIC LANGUAGE plpgsql AS $f$
    DECLARE
        result NUMERIC;
    BEGIN
        SELECT constant_value INTO result
        FROM meteo_constants WHERE constant_name = p_name;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Константа "%" не найдена', p_name;
        END IF;
        RETURN result;
    END;
    $f$;

    COMMENT ON TABLE meteo_constants IS 'Константы метеорасчетов';
    COMMENT ON FUNCTION get_meteo_constant(VARCHAR)
        IS 'Получение значения константы по имени';

END;
$$ LANGUAGE plpgsql;
