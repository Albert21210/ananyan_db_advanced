-- Создание счетчиков, структуры таблиц и связей
BEGIN;

    -- Безопасная очистка старых объектов
    DROP TABLE IF EXISTS temperature_calculations CASCADE;
    DROP TABLE IF EXISTS measurements CASCADE;
    DROP TABLE IF EXISTS measurement_batches CASCADE;
    DROP TABLE IF EXISTS parameters CASCADE;
    DROP TABLE IF EXISTS base_units CASCADE;
    DROP TABLE IF EXISTS users CASCADE;

    -- Удаление старых счетчиков
    DROP SEQUENCE IF EXISTS users_id_seq CASCADE;
    DROP SEQUENCE IF EXISTS base_units_id_seq CASCADE;
    DROP SEQUENCE IF EXISTS parameters_id_seq CASCADE;
    DROP SEQUENCE IF EXISTS measurement_batches_id_seq CASCADE;
    DROP SEQUENCE IF EXISTS measurements_id_seq CASCADE;
    DROP SEQUENCE IF EXISTS temperature_calculations_id_seq CASCADE;

    -- Создание явных счетчиков
    CREATE SEQUENCE users_id_seq START WITH 1 INCREMENT BY 1;
    CREATE SEQUENCE base_units_id_seq START WITH 1 INCREMENT BY 1;
    CREATE SEQUENCE parameters_id_seq START WITH 1 INCREMENT BY 1;
    CREATE SEQUENCE measurement_batches_id_seq START WITH 1 INCREMENT BY 1;
    CREATE SEQUENCE measurements_id_seq START WITH 1 INCREMENT BY 1;
    CREATE SEQUENCE temperature_calculations_id_seq START WITH 1 INCREMENT BY 1;

    -- Таблица пользователей
    CREATE TABLE users (
        id INT PRIMARY KEY DEFAULT nextval('users_id_seq'),
        username VARCHAR(100) NOT NULL
    );

    -- Таблица базовых единиц
    CREATE TABLE base_units (
        id INT PRIMARY KEY DEFAULT nextval('base_units_id_seq'),
        name VARCHAR(50) NOT NULL
    );

    -- Таблица параметров
    CREATE TABLE parameters (
        id INT PRIMARY KEY DEFAULT nextval('parameters_id_seq'),
        name VARCHAR(100) NOT NULL,
        unit VARCHAR(20) NOT NULL,
        base_unit_id INT NOT NULL,
        min_val NUMERIC NOT NULL,
        max_val NUMERIC NOT NULL,
        CONSTRAINT fk_parameters_base_units FOREIGN KEY (base_unit_id) REFERENCES base_units(id) ON DELETE CASCADE
    );

    -- Таблица пачек измерений
    CREATE TABLE measurement_batches (
        id INT PRIMARY KEY DEFAULT nextval('measurement_batches_id_seq'),
        user_id INT NOT NULL,
        created_at TIMESTAMP NOT NULL,
        CONSTRAINT fk_batches_users FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );

    -- Таблица конкретных измерений
    CREATE TABLE measurements (
        id INT PRIMARY KEY DEFAULT nextval('measurements_id_seq'),
        batch_id INT NOT NULL,
        parameter_id INT NOT NULL,
        value NUMERIC NOT NULL,
        CONSTRAINT fk_measurements_batches FOREIGN KEY (batch_id) REFERENCES measurement_batches(id) ON DELETE CASCADE,
        CONSTRAINT fk_measurements_parameters FOREIGN KEY (parameter_id) REFERENCES parameters(id) ON DELETE CASCADE
    );

    -- Пункт 4: Новая таблица «Расчет температуры»
    CREATE TABLE temperature_calculations (
        id INT PRIMARY KEY DEFAULT nextval('temperature_calculations_id_seq'),
        batch_id INT NOT NULL,
        avg_temperature NUMERIC NOT NULL,
        calculation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT fk_calc_batches FOREIGN KEY (batch_id) REFERENCES measurement_batches(id) ON DELETE CASCADE
    );

COMMIT;


-- Наполнение тестовыми данными
BEGIN;

    -- Пользователи
    INSERT INTO users (id, username) VALUES
    (1, 'meteo_user_1'),
    (2, 'meteo_user_2'),
    (3, 'meteo_user_3'),
    (4, 'meteo_user_4');

    -- Базовые единицы измерения
    INSERT INTO base_units (id, name) VALUES
    (1, 'Температурные единицы'),
    (2, 'Единицы влажности'),
    (3, 'Единицы давления'),
    (4, 'Скорость'),
    (5, 'Объем осадков');

    -- Параметры с привязкой к базовым единицам и диапазонам
    INSERT INTO parameters (id, name, unit, base_unit_id, min_val, max_val) VALUES
    (1, 'Температура', '°C', 1, -50, 50),
    (2, 'Влажность', '%', 2, 0, 100),
    (3, 'Атмосферное давление', 'мм рт. ст.', 3, 700, 800),
    (4, 'Скорость ветра', 'м/с', 4, 0, 30),
    (5, 'Уровень осадков', 'мм', 5, 0, 50);

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

COMMIT;


-- Отображение новых метаданных
SELECT
    ROW_NUMBER() OVER (ORDER BY table_name) AS "№",
    table_name AS "Наименование",
    'Таблица' AS "Тип"
FROM information_schema.tables
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'
  AND table_catalog = current_database();
