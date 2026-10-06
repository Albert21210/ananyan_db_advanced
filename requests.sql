-- 1. Проверка равенства количества измерений для каждого пользователя
SELECT 
    u.id AS user_id,
    u.username, 
    COUNT(m.id) AS total_measurements
FROM users u
LEFT JOIN measurement_batches b ON u.id = b.user_id
LEFT JOIN measurements m ON b.id = m.batch_id
GROUP BY u.id, u.username
ORDER BY u.id;

-- 2. Проверка отсутствия пустых пачек измерений
SELECT 
    b.id AS batch_id, 
    COUNT(m.id) AS measurement_count
FROM measurement_batches b
LEFT JOIN measurements m ON b.id = m.batch_id
GROUP BY b.id
ORDER BY b.id;

-- 3. Проверка полноты параметров (по 5 шт) в каждой пачке
SELECT 
    b.id AS batch_id, 
    COUNT(m.parameter_id) AS param_count,
    (COUNT(m.parameter_id) = 5) AS is_complete
FROM measurement_batches b
LEFT JOIN measurements m ON b.id = m.batch_id
GROUP BY b.id
ORDER BY b.id;

-- 4. Проверка нахождения всех значений в допустимых диапазонах
SELECT 
    m.id AS measurement_id,
    m.value,
    p.name AS parameter_name,
    p.min_val,
    p.max_val
FROM measurements m
JOIN parameters p ON m.parameter_id = p.id
WHERE m.value < p.min_val OR m.value > p.max_val;

-- 5. Проверка соответствия единиц измерения параметрам
SELECT 
    id,
    name, 
    unit,
    min_val,
    max_val
FROM parameters
ORDER BY id;
