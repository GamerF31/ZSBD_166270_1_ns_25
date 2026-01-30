-- Tworzenie widoków

CREATE VIEW departament50 AS
SELECT * FROM EMPLOYEES
WHERE DEPARTMENT_ID = 50;


SELECT * FROM v_DEPARTAMENT50;

DROP VIEW v_departament50;

CREATE OR REPLACE VIEW v_departament50 AS
SELECT EMPLOYEE_ID, FIRST_NAME, LAST_NAME, SALARY FROM EMPLOYEES
WHERE DEPARTMENT_ID = 50
WITH CHECK OPTION;

-- Zmiana wartości w widoku
UPDATE V_DEPARTAMENT50 SET salary = 100000
WHERE EMPLOYEE_ID = 120;

-- ZADANIA

-- Zadanie 1 Utwórz widok v_wysokie_pensje, dla tabeli employees który pokaże wszystkich 
-- pracowników zarabiających więcej niż 6000.

CREATE VIEW v_wysokie_pensje AS 
SELECT * FROM EMPLOYEES WHERE SALARY > 6000;

-- CHECK
SELECT * FROM V_WYSOKIE_PENSJE;


-- Zadanie 2 Zmień definicję widoku v_wysokie_pensje aby pokazywał  tylko pracowników 
-- zarabiających powyżej  12000.

CREATE OR REPLACE VIEW V_WYSOKIE_PENSJE AS
SELECT * FROM EMPLOYEES WHERE SALARY > 12000;

-- CHECK
SELECT * FROM V_WYSOKIE_PENSJE;

-- Zadanie 3 Usuń widok v_wysokie_pensje. 

DROP VIEW V_WYSOKIE_PENSJE;


-- Zadanie 4 Stwórz widok dla tabeli employees zawierający: employee_id, last_name, first_name, dla 
-- pracowników z departamentu o nazwie Finance

CREATE VIEW v_employee_Zad4 AS
SELECT e.EMPLOYEE_ID, e.LAST_NAME, e.FIRST_NAME, d.DEPARTMENT_NAME FROM EMPLOYEES e
JOIN DEPARTMENTS d ON d.DEPARTMENT_ID = e.DEPARTMENT_ID
WHERE d.DEPARTMENT_NAME = 'Finance';

-- CHECK
SELECT * FROM V_EMPLOYEE_ZAD4;

-- Zadanie 5 Stwórz widok dla tabeli employees zawierający: employee_id, last_name, first_name, 
-- salary, job_id, email, hire_date dla pracowników mających zarobki pomiędzy 5000 a 
-- 12000.

CREATE VIEW v_employee_Zad5 AS
SELECT e.employee_id, e.last_name, e.first_name, e.salary, e.job_id, e.email, e.hire_date FROM EMPLOYEES e
WHERE SALARY BETWEEN 5000 AND 12000;

-- CHECK
SELECT * FROM V_EMPLOYEE_ZAD5;

-- Zadanie 6  Poprzez utworzone  widoki sprawdź czy możesz

-- A dodać nowego pracownika 
INSERT INTO V_EMPLOYEE_ZAD4 (V_EMPLOYEE_ZAD4.EMPLOYEE_ID, V_EMPLOYEE_ZAD4.LAST_NAME, V_EMPLOYEE_ZAD4.FIRST_NAME, V_EMPLOYEE_ZAD4.DEPARTMENT_NAME)
VALUES (121,'Wzorek', 'Adrian', "Student");


-- B Edytować pracownika
UPDATE V_EMPLOYEE_ZAD4 SET FIRST_NAME = 'Damian' WHERE EMPLOYEE_ID = 109;

-- C Usunąć pracownik

DELETE FROM V_EMPLOYEE_ZAD4 WHERE EMPLOYEE_ID = 109;

SELECT * FROM V_EMPLOYEE_ZAD4 WHERE V_EMPLOYEE_ZAD4.EMPLOYEE_ID = 109;



-- Zadanie 7 z WITH CHECK OPTION

CREATE OR REPLACE VIEW v_employee_Zad4_2 AS
SELECT e.EMPLOYEE_ID, e.LAST_NAME, e.FIRST_NAME, d.DEPARTMENT_NAME FROM EMPLOYEES e
JOIN DEPARTMENTS d ON d.DEPARTMENT_ID = e.DEPARTMENT_ID
WHERE d.DEPARTMENT_NAME = 'Finance'
WITH CHECK OPTION;

-- A dodać nowego pracownika 
DESC V_EMPLOYEE_ZAD4;
SELECT e.department_name FROM V_EMPLOYEE_ZAD4_2 e;
INSERT INTO V_EMPLOYEE_ZAD4_2 (EMPLOYEE_ID, LAST_NAME, FIRST_NAME, DEPARTMENT_NAME)
VALUES (109,'Wzorek', 'Adrian', 'Finance');


-- B Edytować pracownika
UPDATE V_EMPLOYEE_ZAD4_2 SET FIRST_NAME = 'Damian' WHERE EMPLOYEE_ID = 109;

-- C Usunąć pracownik

DELETE FROM V_EMPLOYEE_ZAD4_2 WHERE EMPLOYEE_ID = 109;

SELECT * FROM V_EMPLOYEE_ZAD4_2 WHERE V_EMPLOYEE_ZAD4_2.EMPLOYEE_ID = 109;

-- Zadanie 7 Stwórz widok, który dla każdego działu który zatrudnia przynajmniej 4 pracowników 
-- wyświetli: identyfikator działu, nazwę działu, liczbę pracowników w dziale,  średnią 
-- pensja w dziale i najwyższa pensja w dziale.

CREATE VIEW Zaddanie_7 AS
SELECT d.DEPARTMENT_ID, d.DEPARTMENT_NAME,
	   COUNT(e.EMPLOYEE_ID) AS employee_count,
	   AVG(e.SALARY) AS avg_salary,
	   MAX(e.SALARY) AS max_salary
FROM DEPARTMENTS d
JOIN EMPLOYEES e ON e.DEPARTMENT_ID = d.DEPARTMENT_ID
GROUP BY d.DEPARTMENT_ID, d.DEPARTMENT_NAME
HAVING COUNT(e.EMPLOYEE_ID) >= 4
ORDER BY d.DEPARTMENT_NAME ASC;

-- CHECK
SELECT * FROM Zaddanie_7;

SELECT  COUNT(e.EMPLOYEE_ID) as ILE, 
        d.DEPARTMENT_NAME
FROM Departments d
JOIN Employees e ON e.DEPARTMENT_ID = d.DEPARTMENT_ID
GROUP BY d.DEPARTMENT_NAME
HAVING COUNT(e.EMPLOYEE_ID) >= 4 
ORDER BY d.DEPARTMENT_NAME DESC;


-- Zadanie 8 Stwórz analogiczny widok zadania 3 z dodaniem warunku ‘WITH CHECK OPTION’.  
CREATE OR REPLACE VIEW Zadanie_8 AS 
SELECT * FROM EMPLOYEES 
WHERE SALARY BETWEEN 6000 AND 12000
WITH CHECK OPTION;

-- CHECK
SELECT * FROM zadanie_8
ORDER BY SALARY ASC;

-- a.  Sprawdź czy możesz:  
-- i.  dodać pracownika z zarobkami pomiędzy 5000 a 12000.  

INSERT INTO ZADANIE_8 (Employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id)
VALUES (555, 'Adrian', 'Wzorek', 'AWZOREK', '123.123.123', TO_DATE('17.11.2025', 'DD.MM.YYYY'), 'AD_VP', 8000, null, 100, 50);


SELECT * FROM ZADANIE_8
WHERE employee_id = 555;

-- ii.  dodać pracownika z zarobkami powyżej 12000. 

INSERT INTO ZADANIE_8 (Employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id)
VALUES (556, 'Damian', 'Wzorek', 'AWZOREK', '123.123.123', TO_DATE('17.11.2025', 'DD.MM.YYYY'), 'AD_VP', 18000, null, 100, 50);
SELECT * FROM ZADANIE_8
WHERE employee_id = 556;


-- Zadanie 9 Utwórz widok zmaterializowany v_managerowie, który pokaże tylko menedżerów w raz 
-- z nazwami ich działów.

CREATE VIEW v_managerowie AS
SELECT e.first_name || ' ' || e.last_name as Full_Name, d.department_name, e.manager_id 
FROM Employees e
JOIN Departments d ON d.department_id = e.department_id
WHERE e.manager_id = 100;

-- CHECK
SELECT * FROM V_MANAGEROWIE;


-- Zadanie 10 Stwórz widok v_najlepiej_oplacani, który zawiera tylko 10 najlepiej opłacanych 
-- pracowników

SELECT e.first_name || ' ' || e.last_name AS Full_Name, e.salary
FROM Employees e
ORDER BY e.salary DESC
FETCH FIRST 10 ROWS ONLY;