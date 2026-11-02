-- ------------------------------------------------------------
-- 1. Выбрать дни недели, в которые почтовые отделения работают больше 8 часов.
-- 
-- ------------------------------------------------------------

SELECT DISTINCT
    ws.day_of_week
FROM work_schedules ws
WHERE
    (ws.end_time - ws.start_time)
    - COALESCE(
        ws.break_end_time - ws.break_start_time,
        INTERVAL '0 minutes'
    ) > INTERVAL '8 hours'
ORDER BY ws.day_of_week;

-- ------------------------------------------------------------
-- 2. Выбратьотделы почтовых отделений, которые обслуживают только физических лиц и принимают заказные писма. 
-- ------------------------------------------------------------

SELECT
    d.department_code,
    d.name,
    d.department_functions
FROM departments d
WHERE d.serves_individuals IS TRUE
  AND d.serves_legal_entities IS FALSE
  AND d.department_functions ILIKE '%заказн%'
  AND d.department_functions ILIKE '%письм%';

-- ------------------------------------------------------------
-- 3.Создать таблицу, содержашую даные 1 запроса с указанием времини начало и окончания работы, времини начало и оканчания перирыврв и даных об отделах.
-- ------------------------------------------------------------

DROP TABLE IF EXISTS departments_working_more_8_hours;

CREATE TABLE departments_working_more_8_hours AS
SELECT
    ws.post_office_code,
    ws.day_of_week,
    ws.start_time,
    ws.end_time,
    ws.break_start_time,
    ws.break_end_time,
    d.department_code,
    d.name AS department_name,
    d.serves_individuals,
    d.serves_legal_entities,
    d.department_functions
FROM work_schedules ws
JOIN departments d
  ON d.department_code = ws.department_code
WHERE ws.end_time - ws.start_time > INTERVAL '8 hours';

-- Проверка созданной таблицы
SELECT *
FROM departments_working_more_8_hours
ORDER BY post_office_code, day_of_week, department_code;

-- ------------------------------------------------------------
-- 4. Добавить в созданую таблицу отделы, названия которых состоят из нескольких слов.
-- ------------------------------------------------------------
INSERT INTO departments_working_more_8_hours (
    post_office_code,
    day_of_week,
    start_time,
    end_time,
    break_start_time,
    break_end_time,
    department_code,
    department_name,
    serves_individuals,
    serves_legal_entities,
    department_functions
)
SELECT
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    d.department_code,
    d.name,
    d.serves_individuals,
    d.serves_legal_entities,
    d.department_functions
FROM departments d
WHERE d.name ~ '\s+'
AND NOT EXISTS (
    SELECT 1
    FROM departments_working_more_8_hours t
    WHERE t.department_code = d.department_code
);

-- ------------------------------------------------------------
-- 5. Всозданую таблицу для всех отделов, обслуживающих только юридических лиц,
--    включить обслуживание физических лиц.
-- ------------------------------------------------------------

UPDATE departments
SET serves_individuals = TRUE
WHERE serves_legal_entities IS TRUE
  AND serves_individuals IS FALSE;

-- ------------------------------------------------------------
-- 6. Удалить из созданной таблицы все отделы, перерывы которых
--    меньше получаса.
-- ------------------------------------------------------------

DELETE FROM departments_working_more_8_hours
WHERE COALESCE(
    break_end_time - break_start_time,
    INTERVAL '0 minutes'
) < INTERVAL '30 minutes';

-- ------------------------------------------------------------
-- 7. Посчитать количество отделов, обслуживаюших только юридических лиц,и отделов ,обслуживающх все котогории
--  в кадый из дней неделию
-- ------------------------------------------------------------
SELECT
    ws.day_of_week,

    COUNT(DISTINCT ws.department_code) FILTER (
        WHERE d.serves_legal_entities = TRUE
          AND d.serves_individuals = FALSE
    ) AS only_legal_entities,

    COUNT(DISTINCT ws.department_code) FILTER (
        WHERE d.serves_legal_entities = TRUE
          AND d.serves_individuals = TRUE
    ) AS all_client_categories

FROM work_schedules ws

JOIN departments d
    ON d.department_code = ws.department_code

GROUP BY ws.day_of_week

ORDER BY
    CASE ws.day_of_week
        WHEN 'Monday_1' THEN 1
        WHEN 'Tuesday_1' THEN 2
        WHEN 'Wednesday_1' THEN 3
        WHEN 'Thursday_1' THEN 4
        WHEN 'Friday_1' THEN 5
        WHEN 'Saturday_1' THEN 6
        WHEN 'Monday_2' THEN 1
        WHEN 'Tuesday_2' THEN 2
        WHEN 'Wednesday_2' THEN 3
        WHEN 'Thursday_2' THEN 4
        WHEN 'Friday_2' THEN 5
        WHEN 'Saturday_2' THEN 6
    END;

