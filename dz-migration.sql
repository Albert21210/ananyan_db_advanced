DROP TABLE IF EXISTS batches;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS positions;
DROP TABLE IF EXISTS equipment_types;
DROP TABLE IF EXISTS parameters;

CREATE TABLE positions (
    position_id INT PRIMARY KEY,
    title VARCHAR(50) NOT NULL
);

CREATE TABLE users (
    user_id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    position_id INT REFERENCES positions(position_id)
);

CREATE TABLE equipment_types (
    equipment_type_id INT PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL
);

CREATE TABLE parameters (
    parameter_id INT PRIMARY KEY,
    param_name VARCHAR(50) NOT NULL,
    unit VARCHAR(10) NOT NULL
);

CREATE TABLE batches (
    batch_id INT PRIMARY KEY,
    batch_code VARCHAR(20) NOT NULL,
    user_id INT REFERENCES users(user_id),
    equipment_type_id INT REFERENCES equipment_types(equipment_type_id),
    parameter_id INT REFERENCES parameters(parameter_id),
    param_value VARCHAR(20) NOT NULL
);

INSERT INTO positions VALUES (1, 'Оператор'), (2, 'Инженер');
INSERT INTO users VALUES (1, 'Иванов И.И.', 1), (2, 'Петров П.П.', 2);
INSERT INTO equipment_types VALUES (1, 'Станок'), (2, 'Конвейер');
INSERT INTO parameters VALUES (1, 'Температура', 'C'), (2, 'Вес', 'кг');
INSERT INTO batches VALUES (1, 'BATCH-01', 1, 1, 2, '1.25'), (2, 'BATCH-02', 2, 2, 1, '185.0');

SELECT 
    b.batch_id AS "ID пачки",
    b.batch_code AS "Код пачки",
    u.full_name AS "Пользователи",
    p.title AS "Должность",
    eq.type_name AS "Оборудование",
    pm.param_name AS "Параметр",
    b.param_value AS "Значение",
    pm.unit AS "Ед. изм."
FROM batches b
JOIN users u ON b.user_id = u.user_id
JOIN positions p ON u.position_id = p.position_id
JOIN equipment_types eq ON b.equipment_type_id = eq.equipment_type_id
JOIN parameters pm ON b.parameter_id = pm.parameter_id;