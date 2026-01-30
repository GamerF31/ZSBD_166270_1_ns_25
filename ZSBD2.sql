-- Zadanie 1 Usunięcie tabel

DROP TABLE Countries CASCADE CONSTRAINTS;
DROP TABLE Employees CASCADE CONSTRAINTS;
DROP TABLE Departments CASCADE CONSTRAINTS;
DROP TABLE Jobs CASCADE CONSTRAINTS;
DROP TABLE Job_History CASCADE CONSTRAINTS;
DROP TABLE Locations CASCADE CONSTRAINTS;
DROP TABLE Regions CASCADE CONSTRAINTS;
DROP TABLE Locations CASCADE CONSTRAINTS;

-- Zadanie 2 Kopiowanie wszystkich tabel od użytkownika HR

-- Zadanie 2.1 Kopioweanie tabel

CREATE TABLE Countries AS SELECT * FROM hr.Countries;
CREATE TABLE Departments AS SELECT * FROM hr.Departments;
CREATE TABLE Employees AS SELECT * FROM hr.Employees;
CREATE TABLE Jobs AS SELECT * FROM hr.Jobs;
CREATE TABLE Job_Grades AS SELECT * FROM hr.Job_Grades;
CREATE TABLE Job_History AS SELECT * FROM hr.Job_History;
CREATE TABLE Locations AS SELECT * FROM hr.Locations;
CREATE TABLE Products AS SELECT * FROM hr.Products;
CREATE TABLE Regions AS SELECT * FROM hr.Regions;
CREATE TABLE Sales AS SELECT * FROM hr.Sales;

--  Zadanie 2.2 Połączenie tabel

-- Zadanie 2.2.1 Dodanie kluczy głównych do tabel

ALTER TABLE Countries ADD CONSTRAINT pk_country PRIMARY KEY (country_id);
ALTER TABLE Departments ADD CONSTRAINT pk_department PRIMARY KEY (department_id);
ALTER TABLE Employees ADD CONSTRAINT pk_employee PRIMARY KEY (employee_id);
ALTER TABLE Jobs ADD CONSTRAINT pk_job PRIMARY KEY (job_id);
ALTER TABLE Job_Grades ADD CONSTRAINT pk_job_grade PRIMARY KEY (grade_id);
ALTER TABLE Job_History ADD CONSTRAINT pk_job_history PRIMARY KEY (employee_id, start_date);
ALTER TABLE Locations ADD CONSTRAINT pk_location PRIMARY KEY (location_id);
ALTER TABLE Products ADD CONSTRAINT pk_product PRIMARY KEY (product_id);
ALTER TABLE Regions ADD CONSTRAINT pk_region PRIMARY KEY (region_id);
ALTER TABLE Sales ADD CONSTRAINT pk_sale PRIMARY KEY (sale_id);

-- Zadanie 2.2.2 Ustawienie kluczy obcych

-- Countries and Regions
DESC Countries;
ALTER TABLE Countries ADD CONSTRAINT fk_country_region FOREIGN KEY (region_id) REFERENCES Regions(region_id) ON DELETE CASCADE;
DESC Regions;

-- Employees and Departments
DESC Employees;
ALTER TABLE Employees ADD CONSTRAINT fk_employee_job FOREIGN KEY (job_id) REFERENCES Jobs(job_id) ON DELETE CASCADE;
ALTER TABLE Employees ADD CONSTRAINT fk_employee_manager FOREIGN KEY (manager_id) REFERENCES Employees(employee_id) ON DELETE SET NULL;
ALTER TABLE Employees ADD CONSTRAINT fk_employee_department FOREIGN KEY (department_id) REFERENCES Departments(department_id) ON DELETE SET NULL;
DESC Departments;
ALTER TABLE Departments ADD CONSTRAINT fk_department_location FOREIGN KEY (location_id) REFERENCES Locations(location_id) ON DELETE SET NULL;
ALTER TABLE Departments ADD CONSTRAINT fk_department_manager FOREIGN KEY (manager_id) REFERENCES Employees(employee_id) ON DELETE SET NULL;

-- Jobs_history and Job
DESC Job_History;
DESC Jobs;
ALTER TABLE Job_History ADD CONSTRAINT fk_job_history_employee FOREIGN KEY (employee_id) REFERENCES Employees(employee_id) ON DELETE CASCADE;
ALTER TABLE Job_History ADD CONSTRAINT fk_job_history_department FOREIGN KEY (department_id) REFERENCES Departments(department_id) ON DELETE SET NULL;
ALTER TABLE Job_History ADD CONSTRAINT fk_job_history_job_title FOREIGN KEY (job_id) REFERENCES Jobs(job_id) ON DELETE SET NULL;

--  Job Grades and Location
DESC Job_Grades;
DESC Locations;

DESC Products;
DESC Regions;

-- Sales and Employees
DESC Sales;
ALTER TABLE Sales ADD CONSTRAINT fk_sales_employees_id FOREIGN KEY (employee_id) REFERENCES Employees(employee_id) ON DELETE CASCADE;
ALTER TABLE Sales ADD CONSTRAINT fk_sales_product_id FOREIGN KEY (product_id) REFERENCES Products(product_id) ON DELETE CASCADE;

-- Zadanie 3 Odpowiednie zapytania SQL

--  Zadanie 3.1 Z tabeli employees wypisz w jednej kolumnie nazwisko i zarobki – nazwij 
-- kolumnę wynagrodzenie, dla osób z departamentów 20 i 50 z zarobkami 
-- pomiędzy 2000 a 7000, uporządkuj kolumny według nazwiska 

SELECT last_name || ' ' || salary AS wynagrodzenie
FROM Employees
WHERE department_id IN (20, 50)
AND salary BETWEEN 2000 AND 7000
ORDER BY last_name;


-- Zadanie 3.2 Z tabeli employees wyciągnąć informację data zatrudnienia, nazwisko oraz 
-- kolumnę podaną przez użytkownika dla osób mających menadżera 
-- zatrudnionych w roku 2005. Uporządkować według kolumny podanej przez 
-- użytkownika

ACCEPT column_name PROMPT 'Podaj nazwę kolumny do sortowania (np. salary, employee_id): '

SELECT hire_date, last_name, salary, manager_id
FROM Employees
WHERE manager_id IN (
    SELECT employee_id
    FROM Employees
    WHERE EXTRACT(YEAR FROM hire_date) = 2005
)
ORDER BY &column_name ASC;

-- Zadanie 3.3 Wypisać imiona i nazwiska  razem, zarobki oraz numer telefonu porządkując 
-- dane według pierwszej kolumny malejąco  a następnie drugiej rosnąco (użyć 
-- numerów do porządkowania) dla osób z trzecią literą nazwiska ‘e’ oraz częścią 
-- imienia podaną przez użytkownika 


SELECT first_name || ' ' || last_name AS Full_Name, salary, phone_number
    FROM Employees
    WHERE SUBSTR(last_name, 3, 1) = 'e'
    -- Wykonanie warunku dla części imienia podanej przez użytkownika
    -- Użycie '%' do dopasowania wzorców
    AND first_name LIKE '%' || :user_input || '%'
ORDER BY Full_Name DESC, salary ASC;


-- Zadanie 3.4 Wypisać imię i nazwisko, liczbę miesięcy przepracowanych – funkcje 
-- months_between oraz round oraz kolumnę wysokość_dodatku jako (użyć CASE 
-- lub DECODE): 
-- ●  10% wynagrodzenia dla liczby miesięcy do 150 
-- ●  20% wynagrodzenia dla liczby miesięcy od 150 do 200 
-- ●  30% wynagrodzenia dla liczby miesięcy od 200 
-- ●  uporządkować według liczby miesięcy

SELECT first_name || ' ' || last_name AS Full_Name,
       ROUND(MONTHS_BETWEEN(SYSDATE, hire_date)) AS Months_Worked,
       CASE 
           WHEN ROUND(MONTHS_BETWEEN(SYSDATE, hire_date)) < 150 THEN salary * 0.10 || ' zł'
           WHEN ROUND(MONTHS_BETWEEN(SYSDATE, hire_date)) BETWEEN 150 AND 200 THEN salary * 0.20 || ' zł'
           ELSE salary * 0.30 || ' zł'
       END AS Height_of_Bonus
FROM Employees
ORDER BY Months_Worked;


-- Zadanie 3.5 Dla każdego działów w których minimalna płaca jest wyższa niż 5000 wypisz 
-- sumę oraz średnią zarobków zaokrągloną do całości nazwij odpowiednio 
-- kolumny

SELECT department_id,
       SUM(salary) AS Total_Salary,
       ROUND(AVG(salary)) AS Average_Salary
FROM Employees
WHERE department_id IN (
    SELECT department_id
    FROM Employees
    GROUP BY department_id
    HAVING MIN(salary) > 5000
)
GROUP BY department_id;

-- Zadanie 3.6 Wypisać nazwisko, numer departamentu, nazwę departamentu, id pracy, dla 
-- osób z pracujących Toronto

SELECT e.last_name, e.department_id, d.department_name, e.job_id
FROM Employees e
JOIN Departments d ON e.DEPARTMENT_ID = d.department_id
WHERE d.location_id IN(
    SELECT location_id
    FROM LOCATIONS
    WHERE city = 'Toronto'
) ORDER BY e.last_name;


-- Zadanie 3.7 Dla pracowników o imieniu „Jennifer” wypisz imię i nazwisko tego pracownika 
-- oraz osoby które z nim współpracują

SELECT e1.first_name || ' ' || e1.last_name AS Full_Name1,
        e2.first_name || ' ' || e2.last_name AS Full_Name2
FROM Employees e1 JOIN Employees e2 ON e1.department_id = e2.department_id
WHERE e1.first_name = 'Jennifer' AND e1.employee_id != e2.employee_id;



-- Zadanie 3.8 Wypisać wszystkie departamenty w których nie ma pracowników

SELECT d.department_id, d.department_name
FROM Departments d
LEFT JOIN Employees e ON e.department_id = d.department_id
WHERE e.employee_id IS NULL;


-- Zadanie 3.9 Wypisz imię i nazwisko, id pracy, nazwę departamentu, zarobki, oraz 
-- odpowiedni grade dla każdego pracownika

DESC Job_Grades;

SELECT e.first_name || ' ' || e.last_name AS Full_Name, e.job_id, e.department_id, e.salary, g.GRADE
FROM Employees e
JOIN Job_Grades g ON e.salary BETWEEN g.min_salary AND g.max_salary;


-- Zadanie 3.10 Wypisz imię nazwisko oraz zarobki dla osób które zarabiają więcej niż średnia 
-- wszystkich, uporządkuj malejąco według zarobków

SELECT e.first_name || ' ' || e.last_name AS Full_Name, e.salary
FROM Employees e 
WHERE e.salary >(
    SELECT AVG(salary)
    FROM Employees
) ORDER BY e.salary DESC;

-- Zadanie 3.11 Wypisz id imię i nazwisko osób, które pracują w departamencie z osobami 
-- mającymi w nazwisku „u”

SELECT e.employee_id, e.first_name || ' ' || e.last_name AS Full_Name, e.department_id
FROM Employees e
WHERE e.last_name LIKE '%u%' AND e.department_id IN (
    SELECT DISTINCT department_id
    FROM Employees
    WHERE last_name LIKE '%u%'
);

-- Zadanie 3.12  Znajdź pracowników, którzy pracują dłużej niż średnia długość zatrudnienia w firmie

SELECT e.first_name || ' ' || e.last_name AS Full_Name,
ROUND(MONTHS_BETWEEN(SYSDATE, e.hire_date)) AS Months_Worked
FROM Employees e
WHERE ROUND(MONTHS_BETWEEN(SYSDATE, e.hire_date)) > (
    SELECT AVG(ROUND(MONTHS_BETWEEN(SYSDATE, hire_date)))
    FROM Employees
);

-- Zadanie 3.13 Wypisz nazwę departamentu, liczbę pracowników oraz średnie wynagrodzenie 
-- w każdym departamencie. Sortuj według liczby pracowników malejąco.

SELECT COUNT(e.employee_id) AS Number_of_Employees,
         d.department_name,
         ROUND(AVG(e.salary)) AS Average_Salary
FROM Employees e
JOIN Departments d ON e.department_id = d.department_id
GROUP BY d.department_name
ORDER BY Number_of_Employees DESC;

-- Zadanie 3.14 Wypisz imiona i nazwiska pracowników, którzy zarabiają mniej niż jakikolwiek 
-- pracownik w departamencie „IT”.

SELECT e.first_name || ' ' || e.last_name AS Full_Name, e.salary
FROM Employees e
WHERE e.salary < (
    SELECT MIN(e2.salary)
    FROM Employees e2
    JOIN Departments d ON e2.department_id = d.department_id
    WHERE d.department_name = 'IT'
);

-- Zadanie 3.15 Znajdź departamenty, w których pracuje co najmniej jeden pracownik 
-- zarabiający więcej niż średnia pensja w całej firmie.

SELECT d.department_name, COUNT(e.employee_id) AS Number_of_Employees
FROM Departments d
JOIN Employees e ON e.DEPARTMENT_ID = d.department_id
WHERE e.salary > (
    SELECT AVG(salary)
    FROM Employees
)
GROUP BY d.department_name;


-- Zadanie 3.16 Wypisz pięć najlepiej opłacanych stanowisk pracy wraz ze średnimi zarobkami.

SELECT j.job_title, ROUND(AVG(e.salary)) AS Average_Salary
FROM Jobs j
JOIN Employees e ON e.job_id = j.job_id
GROUP BY j.job_title
ORDER BY Average_Salary DESC
FETCH FIRST 5 ROWS ONLY;


-- Zadanie 3.17 Dla każdego regionu, wypisz nazwę regionu, liczbę krajów oraz liczbę 
-- pracowników, którzy tam pracują

DESC Departments;

SELECT r.region_name,
       COUNT(DISTINCT c.country_id) AS Number_of_Countries,
       COUNT(DISTINCT e.employee_id) AS Number_of_Employees
FROM Regions r
LEFT JOIN Countries c ON c.region_id = r.region_id
LEFT JOIN Locations l ON l.country_id = c.country_id
LEFT JOIN Departments d ON d.location_id = l.location_id
LEFT JOIN Employees e ON e.DEPARTMENT_ID = d.department_id
GROUP BY r.region_name;

-- Zadanie 3.18 Podaj imiona i nazwiska pracowników, którzy zarabiają więcej niż ich 
-- menedżerowie.

SELECT e.first_name || ' ' || e.last_name AS Full_Name, e.salary, j.JOB_TITLE
FROM Employees e
JOIN Jobs j ON e.job_id = j.job_id
WHERE e.salary > (
    SELECT m.salary
    FROM Employees m 
    WHERE m.EMPLOYEE_ID = e.manager_id
)GROUP BY e.first_name, e.last_name, e.salary, j.JOB_TITLE
ORDER BY e.salary ASC;

-- Zadanie 3.19 Policz, ilu pracowników zaczęło pracę w każdym miesiącu (bez względu na rok)

SELECT TO_CHAR(hire_date, 'Month') AS Hire_Month,
       COUNT(employee_id) AS Number_of_Employees
FROM Employees
GROUP BY TO_CHAR(hire_date, 'Month'), TO_CHAR(hire_date, 'MM')
ORDER BY TO_CHAR(hire_date, 'MM');

-- Zadanie 3.20 Znajdź trzy departamenty z najwyższą średnią pensją i wypisz ich nazwę oraz 
-- średnie wynagrodzenie.

SELECT d.department_name, ROUND(AVG(e.salary)) AS Average_Salary
FROM Departments d
JOIN Employees e ON e.department_id = d.department_id
GROUP BY d.department_name
ORDER BY Average_Salary DESC
FETCH FIRST 3 ROWS ONLY;