-- Первая транзакция

-- Создание структуры таблиц и счетчиков
DO $$ 
BEGIN
    -- Безопасная очистка старых объектов
    DROP TABLE IF EXISTS temperature_calculations CASCADE;
    DROP TABLE IF EXISTS measurements CASCADE;
    DROP TABLE IF EXISTS measurement_batches CASCADE;
    DROP TABLE IF EXISTS parameters CASCADE;
    DROP TABLE IF EXISTS users CASCADE;

    -- Таблица пользователей
    CREATE TABLE users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(100) NOT NULL
    );

    -- Таблица параметров
    CREATE TABLE parameters (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        unit VARCHAR(20) NOT NULL,
        min_val NUMERIC NOT NULL,
        max_val NUMERIC NOT NULL
    );

    -- Таблица пачек измерений
    CREATE TABLE measurement_batches (
        id SERIAL PRIMARY KEY,
        user_id INT NOT NULL,
        created_at TIMESTAMP NOT NULL
    );

    -- Таблица конкретных измерений
    CREATE TABLE measurements (
        id SERIAL PRIMARY KEY,
        batch_id INT NOT NULL,
        parameter_id INT NOT NULL,
        value NUMERIC NOT NULL
    );

    -- Пункт 4: Новая таблица «Расчет температуры»
    CREATE TABLE temperature_calculations (
        id SERIAL PRIMARY KEY,
        batch_id INT NOT NULL,
        avg_temperature NUMERIC NOT NULL,
        calculation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
END $$;



-- Вторая транзакция

-- Наполнение тестовыми данными
DO $$ 
BEGIN
    -- Пользователи
    INSERT INTO users (id, username) VALUES
    (1, 'meteo_user_1'),
    (2, 'meteo_user_2'),
    (3, 'meteo_user_3'),
    (4, 'meteo_user_4');

    -- Параметры с диапазонами и аномалией
    INSERT INTO parameters (id, name, unit, min_val, max_val) VALUES
    (1, 'Температура', '°C', -50, 50),
    (2, 'Влажность', '%', 0, 100),
    (3, 'Атмосферное давление', 'мм рт. ст.', 700, 800),
    (4, 'Скорость ветра', 'м/с', 0, 30),
    (5, 'Уровень осадков', 'мм', 0, 50);

    -- Пачки измерений
    INSERT INTO measurement_batches (id, user_id, created_at) VALUES
    (1, 1, '2026-06-01 10:00:00'),
    (2, 1, '2026-06-02 10:00:00'),
    (3, 2, '2026-06-01 11:00:00'),
    (4, 2, '2026-06-02 11:00:00'),
    (5, 3, '2026-06-01 12:00:00'),
    (6, 3, '2026-06-02 12:00:00');

    -- Измерения
    INSERT INTO measurements (batch_id, parameter_id, value) VALUES
    (1, 1, 20.5), (1, 2, 45.0), (1, 3, 750.0), (1, 4, 5.2), (1, 5, 0.0),
    (2, 1, 22.1), (2, 2, 50.0), (2, 3, 755.0), (2, 4, 3.1), (2, 5, 1.2),
    (3, 1, -10.0), (3, 2, 80.0), (3, 3, 720.0), (3, 4, 12.5), (3, 5, 15.0),
    (4, 1, -5.0), (4, 2, 75.0), (4, 3, 725.0), (4, 4, 8.0), (4, 5, 5.5),
    (5, 1, 15.0), (5, 2, 60.0), (5, 3, 760.0), (5, 4, 2.0), (5, 5, 0.0),
    (6, 1, 18.2), (6, 2, 55.0), (6, 3, 762.1), (6, 4, 4.5), (6, 5, 0.5),
    (1, 1, 60.0);

    -- Данные для новой таблицы расчета температуры
    INSERT INTO temperature_calculations (batch_id, avg_temperature) VALUES
    (1, 25.2),
    (2, 22.1),
    (3, -10.0),
    (4, -5.0),
    (5, 15.0),
    (6, 18.2);
END $$;



-- Третяя транзакция

-- Создание связей и внешних ключей
DO $$ 
BEGIN
    -- Привязываем партии измерений к конкретным пользователям (авторам)
    ALTER TABLE measurement_batches
        ADD CONSTRAINT fk_batches_users 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

    -- Привязываем отдельные измерения к соответствующим партиям измерений
    ALTER TABLE measurements
        ADD CONSTRAINT fk_measurements_batches 
        FOREIGN KEY (batch_id) REFERENCES measurement_batches(id) ON DELETE CASCADE;

    -- Привязываем измерения к справочнику параметров (типов метеоданных)
    ALTER TABLE measurements
        ADD CONSTRAINT fk_measurements_parameters 
        FOREIGN KEY (parameter_id) REFERENCES parameters(id) ON DELETE CASCADE;

    -- Привязываем расчеты температуры к соответствующим партиям измерений
    ALTER TABLE temperature_calculations
        ADD CONSTRAINT fk_calc_batches 
        FOREIGN KEY (batch_id) REFERENCES measurement_batches(id) ON DELETE CASCADE;
END $$;



-- Отображение новых метаданных
SELECT 
    ROW_NUMBER() OVER (ORDER BY table_name) AS "№",
    table_name AS "Наименование",
    'Таблица' AS "Тип"
FROM information_schema.tables
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE';