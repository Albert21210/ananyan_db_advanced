-- Сброс всех таблиц для повторного и многократного запуска скрипта
DROP TABLE IF EXISTS batches;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS positions;
DROP TABLE IF EXISTS equipment_types;
DROP TABLE IF EXISTS parameters;
DROP TABLE IF EXISTS units;
DROP TABLE IF EXISTS base_units;
DROP TABLE IF EXISTS parameter_types;

-- Создание и наполнение первичных таблиц первой версии

-- Справочник должностей
CREATE TABLE positions (
    position_id INT PRIMARY KEY,  -- Уникальный идентификатор должности
    title VARCHAR(50) NOT NULL    -- Название должности
);

-- Таблица пользователей и сотрудников
CREATE TABLE users (
    user_id INT PRIMARY KEY,        -- Уникальный идентификатор пользователя
    full_name VARCHAR(100) NOT NULL, -- Фио сотрудника
    position_id INT NOT NULL        -- Код должности и связь с таблицей positions
);

-- Справочник типов оборудования
CREATE TABLE equipment_types (
    equipment_type_id INT PRIMARY KEY, -- Уникальный идентификатор типа оборудования
    type_name VARCHAR(50) NOT NULL     -- Название типа оборудования
);

-- Таблица параметров первоначальная версия со старой текстовой колонкой unit
CREATE TABLE parameters (
    parameter_id INT PRIMARY KEY, -- Уникальный идентификатор параметра
    param_name VARCHAR(50) NOT NULL, -- Наименование параметра
    unit VARCHAR(10) NOT NULL     -- Текстовая единица измерения, которая будет удалена во второй версии
);

-- Таблица пачек и журнал замеров параметров
CREATE TABLE batches (
    batch_id INT PRIMARY KEY,         -- Уникальный код записи измерения
    batch_code VARCHAR(20) NOT NULL,  -- Номер или код пачки
    user_id INT NOT NULL,             -- Кто проводил замер и связь с users
    equipment_type_id INT NOT NULL,   -- На каком оборудовании и связь с equipment_types
    parameter_id INT NOT NULL,        -- Какой параметр измерялся и связь с parameters
    param_value VARCHAR(20) NOT NULL, -- Значение замера
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Дата и время измерения с автоподстановкой
);

-- Наполнение таблиц первой версии тестовыми данными
INSERT INTO positions VALUES (1, 'Оператор'), (2, 'Инженер');
INSERT INTO users VALUES (1, 'Иванов И.И.', 1), (2, 'Петров П.П.', 2);
INSERT INTO equipment_types VALUES (1, 'Станок'), (2, 'Конвейер');
INSERT INTO parameters VALUES (1, 'Температура', 'C'), (2, 'Вес', 'кг');

-- Вставка первичных записей измерений пачек
INSERT INTO batches (batch_id, batch_code, user_id, equipment_type_id, parameter_id, param_value) VALUES 
(1, 'BATCH-01', 1, 1, 2, '1.25'), 
(2, 'BATCH-02', 2, 2, 1, '185.0');

-- Создание новых справочников и миграция структуры во второй версии

-- Создание справочника базовых единиц измерения
CREATE TABLE base_units (
    base_unit_id INT PRIMARY KEY,     -- Уникальный код базовой единицы
    base_unit_name VARCHAR(50) NOT NULL -- Название базовой единицы
);

-- Создание справочника единиц измерения
CREATE TABLE units (
    unit_id INT PRIMARY KEY,          -- Уникальный код единицы измерения
    unit_name VARCHAR(20) NOT NULL,   -- Обозначение единицы измерения
    base_unit_id INT NOT NULL         -- Связь с базовой величиной base_units
);

-- Создание справочника типов параметров
CREATE TABLE parameter_types (
    parameter_type_id INT PRIMARY KEY, -- Уникальный код типа параметра
    type_name VARCHAR(50) NOT NULL     -- Категория параметра
);

-- Наполнение новых справочников типовыми данными
INSERT INTO base_units VALUES (1, 'Температура'), (2, 'Масса');
INSERT INTO units VALUES (10, '°C', 1), (20, 'кг', 2);
INSERT INTO parameter_types VALUES (100, 'Технологический'), (200, 'Физико-химический');

-- Изменение структуры таблицы parameters и добавление новых колонок
ALTER TABLE parameters ADD COLUMN unit_id INT;
ALTER TABLE parameters ADD COLUMN parameter_type_id INT;

-- Миграция существующих данных в parameters и привязка к новым справочникам
UPDATE parameters SET unit_id = 10, parameter_type_id = 100 WHERE parameter_id = 1;
UPDATE parameters SET unit_id = 20, parameter_type_id = 200 WHERE parameter_id = 2;

-- Удаление устаревшей текстовой колонки unit
ALTER TABLE parameters DROP COLUMN unit;

-- Итоговый запрос для отображения результатов миграции

SELECT 
    b.created_at AS "Дата измерения",
    b.batch_code AS "Номер пачки",
    u.full_name AS "ФИО сотрудника",
    p.param_name || ' (' || un.unit_name || ')' AS "Наименование параметра и ед. измерения", -- Конкатенация наименования параметра и единицы измерения в скобках
    b.param_value AS "Значение"
FROM batches b
JOIN users u ON b.user_id = u.user_id            -- Присоединение данных сотрудника
JOIN parameters p ON b.parameter_id = p.parameter_id -- Присоединение параметров
JOIN units un ON p.unit_id = un.unit_id          -- Присоединение единиц измерения из нового справочника
ORDER BY b.created_at DESC;                      -- Сортировка от более свежих замеров к старым