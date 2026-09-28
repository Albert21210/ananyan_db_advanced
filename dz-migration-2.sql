-- Создание новых таблиц-справочников (если они еще не созданы)
CREATE TABLE IF NOT EXISTS base_units (
    base_unit_id INT PRIMARY KEY,       -- Уникальный код базовой величины
    base_unit_name VARCHAR(50) NOT NULL  -- Наименование базовой величины
);

CREATE TABLE IF NOT EXISTS units (
    unit_id INT PRIMARY KEY,            -- Уникальный код единицы измерения
    unit_name VARCHAR(20) NOT NULL,     -- Обозначение единицы измерения
    base_unit_id INT NOT NULL           -- Связь со справочником base_units
);

CREATE TABLE IF NOT EXISTS parameter_types (
    parameter_type_id INT PRIMARY KEY,  -- Уникальный код типа параметра
    type_name VARCHAR(50) NOT NULL      -- Наименование категории параметра
);

-- Наполнение новых справочников данными
INSERT INTO base_units VALUES (1, 'Температура'), (2, 'Масса')
ON CONFLICT (base_unit_id) DO NOTHING;

INSERT INTO units VALUES (10, '°C', 1), (20, 'кг', 2)
ON CONFLICT (unit_id) DO NOTHING;

INSERT INTO parameter_types VALUES (100, 'Технологический'), (200, 'Физико-химический')
ON CONFLICT (parameter_type_id) DO NOTHING;

-- Добавление новых колонок в таблицу parameters
ALTER TABLE parameters ADD COLUMN IF NOT EXISTS unit_id INT;             -- Новое поле для связи с единицами измерения
ALTER TABLE parameters ADD COLUMN IF NOT EXISTS parameter_type_id INT;   -- Новое поле для связи с типами параметров

-- Перенос и нормализация данных
UPDATE parameters SET unit_id = 10, parameter_type_id = 100 WHERE parameter_id = 1; -- Привязка первого параметра
UPDATE parameters SET unit_id = 20, parameter_type_id = 200 WHERE parameter_id = 2; -- Привязка второго параметра

-- Удаление устаревших полей
ALTER TABLE parameters DROP COLUMN IF EXISTS unit;                   -- Удаление денормализованного текстового поля unit

-- Итоговый отчет о замерных данных в формате ANSI-92 SQL
SELECT 
    CURRENT_TIMESTAMP AS "Дата измерения",                 -- Динамическое текущее время при каждом запуске
    b.batch_code AS "Номер пачки",
    u.full_name AS "ФИО сотрудника",
    p.param_name || ' (' || un.unit_name || ')' AS "Наименование параметра", -- Конкатенация параметра и единицы измерения
    b.param_value AS "Значение"
FROM batches b
JOIN users u ON b.user_id = u.user_id                 -- Связь замера с сотрудником
JOIN parameters p ON b.parameter_id = p.parameter_id -- Связь замера с параметром
JOIN units un ON p.unit_id = un.unit_id               -- Связь параметра с единицей измерения
ORDER BY b.batch_id ASC;                               -- Сортировка по порядку (1, 2)
