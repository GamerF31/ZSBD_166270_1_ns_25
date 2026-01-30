-- Zadanie 1
-- 1.1. Regions
CREATE TABLE Regions (
    region_id NUMBER PRIMARY KEY,
    region_name VARCHAR2(255) NOT NULL
);

-- 1.2. Countries
CREATE TABLE Countries (
    country_id NUMBER PRIMARY KEY,
    country_name VARCHAR2(255) NOT NULL,
    region_id NUMBER,
    FOREIGN KEY (region_id) REFERENCES Regions(region_id) ON DELETE SET NULL
);

-- 1.3. Locations
CREATE TABLE Locations (
    location_id NUMBER PRIMARY KEY,
    street_address VARCHAR2(255),
    postal_code VARCHAR2(20),
    city VARCHAR2(255) NOT NULL,
    state_province VARCHAR2(255),
    country_id NUMBER,
    FOREIGN KEY (country_id) REFERENCES Countries(country_id) ON DELETE SET NULL
);

-- 1.4. Jobs
CREATE TABLE Jobs (
    job_id NUMBER PRIMARY KEY,
    job_title VARCHAR2(255) NOT NULL,
    min_salary NUMBER(10,2),
    max_salary NUMBER(10,2)
);

-- 1.5. Employees (bez kluczy obcych na razie)
CREATE TABLE Employees (
    employee_id NUMBER PRIMARY KEY,
    first_name VARCHAR2(255),
    last_name VARCHAR2(255) NOT NULL,
    email VARCHAR2(255) NOT NULL UNIQUE,
    phone_number VARCHAR2(20),
    hire_date DATE NOT NULL,
    job_id NUMBER NOT NULL,
    salary NUMBER(10,2) NOT NULL,
    commission_pct NUMBER(5,2),
    manager_id NUMBER,
    department_id NUMBER
);

-- 1.6. Departments (bez klucza obcego do Employees)
CREATE TABLE Departments (
    department_id NUMBER PRIMARY KEY,
    department_name VARCHAR2(255) NOT NULL,
    manager_id NUMBER,
    location_id NUMBER,
    FOREIGN KEY (location_id) REFERENCES Locations(location_id) ON DELETE SET NULL
);

-- 1.7. Dodanie kluczy obcych do Employees
ALTER TABLE Employees
ADD CONSTRAINT fk_emp_job FOREIGN KEY (job_id) REFERENCES Jobs(job_id) ON DELETE CASCADE;

ALTER TABLE Employees
ADD CONSTRAINT fk_emp_dept FOREIGN KEY (department_id) REFERENCES Departments(department_id) ON DELETE SET NULL;

ALTER TABLE Employees
ADD CONSTRAINT fk_emp_mgr FOREIGN KEY (manager_id) REFERENCES Employees(employee_id) ON DELETE SET NULL;

-- 1.8. Dodanie klucza obcego do Departments (manager_id)
ALTER TABLE Departments
ADD CONSTRAINT fk_dept_mgr FOREIGN KEY (manager_id) REFERENCES Employees(employee_id) ON DELETE SET NULL;

-- 1.9. Job_History
CREATE TABLE Job_History (
    employee_id NUMBER,
    start_date DATE,
    end_date DATE,
    job_id NUMBER,
    department_id NUMBER,
    PRIMARY KEY (employee_id, start_date),
    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id) ON DELETE CASCADE,
    FOREIGN KEY (job_id) REFERENCES Jobs(job_id) ON DELETE SET NULL,
    FOREIGN KEY (department_id) REFERENCES Departments(department_id) ON DELETE SET NULL
);

-- 1.10. Dodanie ograniczenia CHECK do tabeli Jobs
ALTER TABLE Jobs
ADD CONSTRAINT chk_salary CHECK(min_salary < max_salary AND max_salary - min_salary >= 2000);


-- Zadanie 2 Wstawienie danych do tabeli

-- 2.1. Tabela Jobs

INSERT INTO Jobs(job_id, job_title, min_salary, max_salary) 
            VALUES (1, 'Programista', 4500, 12000);


INSERT INTO Jobs(job_id, job_title, min_salary, max_salary) 
            VALUES (2, 'Tester', 2500, 7000);

INSERT INTO Jobs(job_id, job_title, min_salary, max_salary) 
            VALUES (3, 'Menedżer', 5500, 10000);

INSERT INTO Jobs(job_id, job_title, min_salary, max_salary) 
            VALUES (4, 'Analityk', 3000, 7500);

-- 2.2. Tabela Regions
INSERT INTO Regions(region_id, region_name)
            VALUES(1, 'Europe');

-- 2.3. Tabela Countries
INSERT INTO Countries(country_id, country_name, region_id)
            VALUES(1, 'Poland', 1);

-- 2.4. Tabela Locations
INSERT INTO Locations(location_id, street_address, postal_code, city, state_province, country_id)
            VALUES(1, 'ul. Przykładowa 1', '00-001', 'Warsaw', 'Mazowieckie', 1);

-- 2.5. Tabela Departments
INSERT INTO Departments(department_id, department_name, manager_id, location_id)
            VALUES(1, 'IT', NULL, 1);


-- Zadanie 3 Wstawienie danych do tabeli Employees
INSERT INTO Employees(employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id)
            VALUES(1, 'Adam', 'Kowalski','adam.kowalski@example.com','123-456-789', TO_DATE('2020-01-15', 'YYYY-MM-DD'), 3, 8000, 0.10, NULL, 1);

INSERT INTO Employees(employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id)
            VALUES(2, 'Paweł', 'Nowak','pawel.nowak@example.com','335-441-121', TO_DATE('2021-02-25', 'YYYY-MM-DD'), 2, 5000, 0.12, NULL, 1);

INSERT INTO Employees(employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id)
            VALUES(3, 'Krzystof', 'Pawłowski','krzystof.pawlowski@example.com','122-233-222', TO_DATE('2019-05-22', 'YYYY-MM-DD'), 1, 6000, 0.10, NULL, 1);
            
INSERT INTO Employees(employee_id, first_name, last_name, email, phone_number, hire_date, job_id, salary, commission_pct, manager_id, department_id)
            VALUES(4, 'Mikołaj', 'Wolej','mikolaj.wolej@example.com','221-334-551', TO_DATE('2024-08-02', 'YYYY-MM-DD'), 4, 4500, 0.10, NULL, 1);


-- Zadanie 4 Zmiana menagera dla poszczególnych pracwoników
UPDATE Employees SET manager_id = 1 WHERE employee_id IN(2,3);


-- Zadanie 5 Zwiększenie minimalnych i maksymalnych wynagrodzeń o 500 jeśli nazwa zaweira 'b' albo 's'

UPDATE Jobs SET min_salary = min_salary + 500, max_salary = max_salary + 500 
WHERE job_title LIKE '%b%' OR job_title LIKE '%s%';


-- Zadanie 6 Usunąć rekordy z tabeli Jobs gdzie maksymalne wynagrodzenie jest większe niż 9000, jeśli są pracownicy przypisani do tych stanowisk to najpierw ustawić ich job_id na NULL

DELETE FROM Jobs WHERE max_salary > 9000;


-- Zadanie 7 Czy można odzyskać usuniętą tabele? 
-- Tak, można odzyskać usuniętą tabelę używając polecenia FLASHBACK TABLE jeśli baza danych jest odpowiednio skonfigurowana i posiada włączoną funkcję flashback.
-- Przykład polecenia:
DROP TABLE Regions CASCADE CONSTRAINTS;

FLASHBACK TABLE Regions TO BEFORE DROP;

SELECT * FROM Regions;

-- Sprawdzenie wstawionych danych

SELECT * FROM Jobs;
SELECT * FROM Regions;
SELECT * FROM Countries;
SELECT * FROM Locations;
SELECT * FROM Departments;
SELECT * FROM Employees;