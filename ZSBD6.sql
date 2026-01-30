SET SERVEROUTPUT ON

-- 1. Zwracającą nazwę pracy dla podanego parametru id, dodaj wyjątek, 
-- jeśli taka praca nie istnieje.

CREATE OR REPLACE FUNCTION get_job_name(p_job_id IN JOBS.JOB_ID%TYPE)
RETURN JOBS.JOB_TITLE%TYPE IS
    job_title_result JOBS.JOB_TITLE%TYPE;
BEGIN
    SELECT 
        job_title 
    INTO job_title_result
    FROM jobs
    WHERE job_id = p_job_id;
    
    RETURN job_title_result;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20001, 'Brak pracy o id = ' || p_job_id);
END;
/

EXEC DBMS_OUTPUT.PUT_LINE(get_job_name('IT_PROG'));

-- Bloczek anonimowy - wyswietl wszystkie nazwy job
DECLARE
    CURSOR c_all_jobs IS
        SELECT job_id, job_title
        FROM JOBS
        ORDER BY job_id;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== WSZYSTKIE PRACE ===');
    FOR job_rec IN c_all_jobs LOOP
        DBMS_OUTPUT.PUT_LINE(job_rec.job_id || ' : ' || job_rec.job_title);
    END LOOP;
END;
/



-- 2. Zwracającą roczne zarobki (wynagrodzenie 12-to miesięczne plus premia jako
-- wynagrodzenie * commission_pct) dla pracownika o podanym id

CREATE OR REPLACE FUNCTION get_annual_earnings(p_emp_id IN EMPLOYEES.EMPLOYEE_ID%TYPE)
RETURN NUMBER IS
    base_sal EMPLOYEES.SALARY%TYPE;
    comm_rate EMPLOYEES.COMMISSION_PCT%TYPE;
    annual_income NUMBER;
BEGIN
    SELECT salary, NVL(commission_pct, 0)
    INTO base_sal, comm_rate
    FROM employees
    WHERE employee_id = p_emp_id;
    
    annual_income := base_sal * 12 + (base_sal * comm_rate);
    RETURN annual_income;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Brak pracownika o id = ' || p_emp_id);
END;
/

EXEC DBMS_OUTPUT.PUT_LINE(get_annual_earnings(100));

-- 3. Biorącą w nawias numer kierunkowy z numeru telefonu podanego jako varchar

CREATE OR REPLACE FUNCTION wrap_area_code(p_phone IN VARCHAR2)
RETURN VARCHAR2 IS
    area_code VARCHAR2(20);
    remainder VARCHAR2(50);
BEGIN
    area_code := REGEXP_SUBSTR(p_phone, '^[^-. ]+');
    remainder := REGEXP_SUBSTR(p_phone, '[-. ].*');
    
    RETURN CASE 
        WHEN area_code IS NULL THEN p_phone
        ELSE '(' || area_code || ')' || NVL(remainder, '')
    END;
END;
/

EXEC DBMS_OUTPUT.PUT_LINE(wrap_area_code('22-123-4567'));

-- 4. Dla podanego w parametrze ciągu znaków zmieniającą pierwszą i 
-- ostatnią literę na wielką – pozostałe na małe.

CREATE OR REPLACE FUNCTION capitalize_edges(p_text IN VARCHAR2)
RETURN VARCHAR2 IS
    text_length PLS_INTEGER;
    first_char VARCHAR2(1);
    middle_part VARCHAR2(4000);
    last_char VARCHAR2(1);
BEGIN
    text_length := LENGTH(p_text);
    
    IF text_length = 0 THEN
        RETURN p_text;
    ELSIF text_length = 1 THEN
        RETURN UPPER(p_text);
    ELSE
        first_char := UPPER(SUBSTR(p_text, 1, 1));
        middle_part := LOWER(SUBSTR(p_text, 2, text_length - 2));
        last_char := UPPER(SUBSTR(p_text, -1, 1));
        RETURN first_char || middle_part || last_char;
    END IF;
END;
/

EXEC DBMS_OUTPUT.PUT_LINE(capitalize_edges('pRzyKLad'));

-- 5. Dla podanego peselu - przerabiającą pesel na datę urodzenia w 
-- formacie ‘yyyy-mm-dd'.

CREATE OR REPLACE FUNCTION pesel_to_birthdate(p_pesel IN VARCHAR2)
RETURN VARCHAR2 IS
    pesel_input VARCHAR2(11) := p_pesel;
    extracted_year NUMBER;
    extracted_month NUMBER;
    extracted_day NUMBER;
    century_offset NUMBER;
    birth_date DATE;
    full_year NUMBER;
BEGIN
    IF LENGTH(pesel_input) != 11 OR NOT REGEXP_LIKE(pesel_input, '^\d{11}$') THEN
        RAISE_APPLICATION_ERROR(-20003, 'Nieprawidłowy PESEL: ' || p_pesel);
    END IF;

    extracted_year := TO_NUMBER(SUBSTR(pesel_input, 1, 2));
    extracted_month := TO_NUMBER(SUBSTR(pesel_input, 3, 2));
    extracted_day := TO_NUMBER(SUBSTR(pesel_input, 5, 2));

    CASE
        WHEN extracted_month BETWEEN 1 AND 12 THEN
            century_offset := 1900; full_year := 1900 + extracted_year;
        WHEN extracted_month BETWEEN 21 AND 32 THEN
            century_offset := 2000; extracted_month := extracted_month - 20; full_year := 2000 + extracted_year;
        WHEN extracted_month BETWEEN 41 AND 52 THEN
            century_offset := 2100; extracted_month := extracted_month - 40; full_year := 2100 + extracted_year;
        WHEN extracted_month BETWEEN 61 AND 72 THEN
            century_offset := 2200; extracted_month := extracted_month - 60; full_year := 2200 + extracted_year;
        WHEN extracted_month BETWEEN 81 AND 92 THEN
            century_offset := 1800; extracted_month := extracted_month - 80; full_year := 1800 + extracted_year;
        ELSE
            RAISE_APPLICATION_ERROR(-20004, 'Nieprawidłowy miesiąc w PESEL: ' || p_pesel);
    END CASE;

    birth_date := TO_DATE(LPAD(full_year, 4, '0') || LPAD(extracted_month, 2, '0') || LPAD(extracted_day, 2, '0'), 'YYYYMMDD');

    RETURN TO_CHAR(birth_date, 'YYYY-MM-DD');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE BETWEEN -20000 AND -20999 THEN
            RAISE;
        ELSE
            RAISE_APPLICATION_ERROR(-20005, 'Błąd PESEL: ' || SQLERRM);
        END IF;
END;
/

EXEC DBMS_OUTPUT.PUT_LINE(pesel_to_birthdate('02211312345'));

-- 6. Zwracającą liczbę pracowników oraz liczbę departamentów które znajdują się
-- w kraju podanym jako parametr (nazwa kraju). 
-- W przypadku braku kraju - odpowiedni wyjątek

CREATE OR REPLACE FUNCTION country_counts(p_country_name IN COUNTRIES.COUNTRY_NAME%TYPE)
RETURN VARCHAR2 IS
    country_key COUNTRIES.COUNTRY_ID%TYPE;
    employee_count NUMBER;
    department_count NUMBER;
BEGIN
    SELECT country_id INTO country_key
    FROM countries
    WHERE UPPER(country_name) = UPPER(p_country_name);

    SELECT COUNT(DISTINCT d.department_id) INTO department_count
    FROM departments d
    JOIN locations l ON l.location_id = d.location_id
    WHERE l.country_id = country_key;

    SELECT COUNT(e.employee_id) INTO employee_count
    FROM employees e
    JOIN departments d ON d.department_id = e.department_id
    JOIN locations l ON l.location_id = d.location_id
    WHERE l.country_id = country_key;

    RETURN 'Pracownicy: ' || employee_count || ', Departamenty: ' || department_count;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20006, 'Nie znaleziono kraju: ' || p_country_name);
END;
/

EXEC DBMS_OUTPUT.PUT_LINE(country_counts('Canada'));

-- ===============
-- Stworzyć następujące wyzwalacze:
-- ===============
-- 1. Stworzyć tabelę archiwum_departamentów (id, nazwa, data_zamknięcia,
-- ostatni_manager jako imię i nazwisko). 
-- Po usunięciu departamentu dodać odpowiedni rekord do tej tabeli

CREATE TABLE archiwum_departamentow (
    dept_id          NUMBER PRIMARY KEY,
    dept_name        VARCHAR2(100),
    closed_date      DATE,
    manager_fullname VARCHAR2(200)
);

CREATE OR REPLACE TRIGGER trg_arch_departments
BEFORE DELETE ON departments
FOR EACH ROW
DECLARE
    manager_info VARCHAR2(200);
BEGIN
    BEGIN
        SELECT NVL(first_name, '') || ' ' || NVL(last_name, '')
        INTO manager_info
        FROM employees
        WHERE employee_id = :OLD.manager_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            manager_info := 'brak';
    END;

    INSERT INTO archiwum_departamentow (dept_id, dept_name, closed_date, manager_fullname)
    VALUES (
        :OLD.department_id,
        :OLD.department_name,
        SYSDATE,
        manager_info
    );
END;
/

DELETE FROM departments WHERE department_id = 290;
SELECT * FROM archiwum_departamentow ORDER BY dept_id DESC;

-- 2. W razie UPDATE i INSERT na tabeli employees, sprawdzić czy zarobki 
-- łapią się w widełkach 2000 - 26000. Jeśli nie łapią się - zabronić dodania. 
-- Dodać tabelę złodziej(id, USER, czas_zmiany), której będą wrzucane logi,
-- jeśli będzie próba dodania, bądź zmiany wynagrodzenia poza widełki

CREATE TABLE zlodziej (
    audit_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    audit_user   VARCHAR2(128),
    audit_time   TIMESTAMP DEFAULT SYSTIMESTAMP
);

CREATE OR REPLACE TRIGGER trg_employees_salary_guard
BEFORE INSERT OR UPDATE OF salary ON employees
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;
    current_user VARCHAR2(128) := SYS_CONTEXT('USERENV', 'SESSION_USER');
BEGIN
    IF :NEW.salary < 2000 OR :NEW.salary > 26000 THEN
        INSERT INTO zlodziej (audit_user, audit_time)
        VALUES (current_user, SYSTIMESTAMP);
        COMMIT;
        RAISE_APPLICATION_ERROR(-20020,
            'Wynagrodzenie poza widełkami 2000-26000: ' || :NEW.salary);
    END IF;
END;
/

UPDATE employees SET salary = 50000 WHERE employee_id = 103;
SELECT * FROM zlodziej ORDER BY audit_id DESC;

-- 3. Stworzyć sekwencję i wyzwalacz, który będzie odpowiadał za 
-- auto_increment w tabeli employees.

CREATE SEQUENCE employees_seq START WITH 1000 INCREMENT BY 1;

CREATE OR REPLACE TRIGGER trg_employees_autoinc
BEFORE INSERT ON employees
FOR EACH ROW
BEGIN
    IF :NEW.employee_id IS NULL THEN
        :NEW.employee_id := employees_seq.NEXTVAL;
    END IF;
END;
/

INSERT INTO employees (first_name, last_name, email, hire_date, job_id, salary, department_id)
VALUES ('Jan', 'Nowak', 'JAN.NOWAK', SYSDATE, 'IT_PROG', 5000, 60);

-- 4. Stworzyć wyzwalacz, który zabroni dowolnej operacji na tabeli JOD_GRADES 
-- (INSERT, UPDATE, DELETE)

CREATE OR REPLACE TRIGGER trg_job_grades_lock
BEFORE INSERT OR UPDATE OR DELETE ON job_grades
BEGIN
    RAISE_APPLICATION_ERROR(-20030, 'Operacje na JOB_GRADES są zabronione.');
END;
/

DELETE FROM job_grades WHERE grade = 'A';

-- 5. Stworzyć wyzwalacz, który przy próbie zmiany max i min salary w 
-- tabeli jobs zostawia stare wartości.

CREATE OR REPLACE TRIGGER trg_jobs_keep_salaries
BEFORE UPDATE OF min_salary, max_salary ON jobs
FOR EACH ROW
BEGIN
    :NEW.min_salary := :OLD.min_salary;
    :NEW.max_salary := :OLD.max_salary;
END;
/

UPDATE jobs SET min_salary = min_salary + 100 WHERE job_id = 'IT_PROG';

-- ===============
-- Stworzyć paczki:
-- ===============
-- 1.  Składającą się ze stworzonych procedur i funkcji

CREATE OR REPLACE PACKAGE util_functions_pkg AS
    FUNCTION get_job_name(p_job_id IN JOBS.JOB_ID%TYPE)
        RETURN JOBS.JOB_TITLE%TYPE;

    FUNCTION get_annual_earnings(p_emp_id IN EMPLOYEES.EMPLOYEE_ID%TYPE)
        RETURN NUMBER;

    FUNCTION wrap_area_code(p_phone IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION capitalize_edges(p_text IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION pesel_to_birthdate(p_pesel IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION country_counts(p_country_name IN COUNTRIES.COUNTRY_NAME%TYPE)
        RETURN VARCHAR2;
END util_functions_pkg;
/

CREATE OR REPLACE PACKAGE BODY util_functions_pkg AS

    FUNCTION get_job_name(p_job_id IN JOBS.JOB_ID%TYPE)
        RETURN JOBS.JOB_TITLE%TYPE IS
        job_title_result JOBS.JOB_TITLE%TYPE;
    BEGIN
        SELECT job_title INTO job_title_result FROM jobs WHERE job_id = p_job_id;
        RETURN job_title_result;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Brak pracy o id = ' || p_job_id);
    END;
    
    FUNCTION get_annual_earnings(p_emp_id IN EMPLOYEES.EMPLOYEE_ID%TYPE)
        RETURN NUMBER IS
        base_sal EMPLOYEES.SALARY%TYPE;
        comm_rate EMPLOYEES.COMMISSION_PCT%TYPE;
    BEGIN
        SELECT salary, NVL(commission_pct, 0) INTO base_sal, comm_rate FROM employees WHERE employee_id = p_emp_id;
        RETURN base_sal * 12 + (base_sal * comm_rate);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'Brak pracownika o id = ' || p_emp_id);
    END;
    
    FUNCTION wrap_area_code(p_phone IN VARCHAR2)
        RETURN VARCHAR2 IS
        area_code VARCHAR2(20);
        remainder VARCHAR2(50);
    BEGIN
        area_code := REGEXP_SUBSTR(p_phone, '^[^-. ]+');
        remainder := REGEXP_SUBSTR(p_phone, '[-. ].*');
        RETURN CASE WHEN area_code IS NULL THEN p_phone ELSE '(' || area_code || ')' || NVL(remainder, '') END;
    END;
    
    FUNCTION capitalize_edges(p_text IN VARCHAR2)
        RETURN VARCHAR2 IS
        text_length PLS_INTEGER;
    BEGIN
        text_length := LENGTH(p_text);
        IF text_length = 0 THEN
            RETURN p_text;
        ELSIF text_length = 1 THEN
            RETURN UPPER(p_text);
        ELSE
            RETURN UPPER(SUBSTR(p_text, 1, 1)) || LOWER(SUBSTR(p_text, 2, text_length - 2)) || UPPER(SUBSTR(p_text, -1, 1));
        END IF;
    END;
    
    FUNCTION pesel_to_birthdate(p_pesel IN VARCHAR2)
        RETURN VARCHAR2 IS
        pesel_input VARCHAR2(11) := p_pesel;
        extracted_year NUMBER;
        extracted_month NUMBER;
        extracted_day NUMBER;
        birth_date DATE;
        full_year NUMBER;
    BEGIN
        IF LENGTH(pesel_input) != 11 OR NOT REGEXP_LIKE(pesel_input, '^\d{11}$') THEN
            RAISE_APPLICATION_ERROR(-20003, 'Nieprawidłowy PESEL: ' || p_pesel);
        END IF;

        extracted_year := TO_NUMBER(SUBSTR(pesel_input, 1, 2));
        extracted_month := TO_NUMBER(SUBSTR(pesel_input, 3, 2));
        extracted_day := TO_NUMBER(SUBSTR(pesel_input, 5, 2));

        CASE
            WHEN extracted_month BETWEEN 1 AND 12 THEN
                full_year := 1900 + extracted_year;
            WHEN extracted_month BETWEEN 21 AND 32 THEN
                extracted_month := extracted_month - 20; full_year := 2000 + extracted_year;
            WHEN extracted_month BETWEEN 41 AND 52 THEN
                extracted_month := extracted_month - 40; full_year := 2100 + extracted_year;
            WHEN extracted_month BETWEEN 61 AND 72 THEN
                extracted_month := extracted_month - 60; full_year := 2200 + extracted_year;
            WHEN extracted_month BETWEEN 81 AND 92 THEN
                extracted_month := extracted_month - 80; full_year := 1800 + extracted_year;
            ELSE
                RAISE_APPLICATION_ERROR(-20004, 'Nieprawidłowy miesiąc w PESEL: ' || p_pesel);
        END CASE;

        birth_date := TO_DATE(LPAD(full_year, 4, '0') || LPAD(extracted_month, 2, '0') || LPAD(extracted_day, 2, '0'), 'YYYYMMDD');
        RETURN TO_CHAR(birth_date, 'YYYY-MM-DD');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE BETWEEN -20000 AND -20999 THEN
                RAISE;
            ELSE
                RAISE_APPLICATION_ERROR(-20005, 'Błąd PESEL: ' || SQLERRM);
            END IF;
    END;
    
    FUNCTION country_counts(p_country_name IN COUNTRIES.COUNTRY_NAME%TYPE)
        RETURN VARCHAR2 IS
        country_key COUNTRIES.COUNTRY_ID%TYPE;
        employee_count NUMBER;
        department_count NUMBER;
    BEGIN
        SELECT country_id INTO country_key FROM countries WHERE UPPER(country_name) = UPPER(p_country_name);
        SELECT COUNT(DISTINCT d.department_id) INTO department_count FROM departments d JOIN locations l ON l.location_id = d.location_id WHERE l.country_id = country_key;
        SELECT COUNT(e.employee_id) INTO employee_count FROM employees e JOIN departments d ON d.department_id = e.department_id JOIN locations l ON l.location_id = d.location_id WHERE l.country_id = country_key;
        RETURN 'Pracownicy: ' || employee_count || ', Departamenty: ' || department_count;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20006, 'Nie znaleziono kraju: ' || p_country_name);
    END;
END util_functions_pkg;
/

SELECT util_functions_pkg.get_job_name('IT_PROG') FROM dual;
SELECT util_functions_pkg.get_annual_earnings(100) FROM dual;
SELECT util_functions_pkg.pesel_to_birthdate('02211312345') FROM dual;

-- 2. Stworzyć paczkę z procedurami i funkcjami do obsługi tabeli 
-- REGIONS (CRUD), gdzie odczyt z różnymi parametrami

CREATE SEQUENCE regions_seq START WITH 100 INCREMENT BY 1;

CREATE OR REPLACE PACKAGE region_manager_pkg AS
    PROCEDURE insert_region(
        p_region_name IN REGIONS.REGION_NAME%TYPE,
        p_region_id   IN REGIONS.REGION_ID%TYPE DEFAULT NULL);

    PROCEDURE modify_region(
        p_region_id   IN REGIONS.REGION_ID%TYPE,
        p_region_name IN REGIONS.REGION_NAME%TYPE);

    PROCEDURE remove_region(
        p_region_id IN REGIONS.REGION_ID%TYPE);

    FUNCTION fetch_region_by_id(
        p_region_id IN REGIONS.REGION_ID%TYPE)
        RETURN REGIONS%ROWTYPE;

    FUNCTION fetch_region_by_name(
        p_region_name IN REGIONS.REGION_NAME%TYPE)
        RETURN REGIONS%ROWTYPE;

    PROCEDURE show_regions(
        p_region_id     IN REGIONS.REGION_ID%TYPE   DEFAULT NULL,
        p_name_like     IN VARCHAR2                 DEFAULT NULL,
        p_result        OUT SYS_REFCURSOR);
END region_manager_pkg;
/

CREATE OR REPLACE PACKAGE BODY region_manager_pkg AS

    PROCEDURE insert_region(
        p_region_name IN REGIONS.REGION_NAME%TYPE,
        p_region_id   IN REGIONS.REGION_ID%TYPE DEFAULT NULL) IS
        new_id REGIONS.REGION_ID%TYPE;
    BEGIN
        new_id := COALESCE(p_region_id, regions_seq.NEXTVAL);
        INSERT INTO regions (region_id, region_name) VALUES (new_id, p_region_name);
    END insert_region;

    PROCEDURE modify_region(
        p_region_id   IN REGIONS.REGION_ID%TYPE,
        p_region_name IN REGIONS.REGION_NAME%TYPE) IS
    BEGIN
        UPDATE regions SET region_name = p_region_name WHERE region_id = p_region_id;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20051, 'Region nie istnieje: ' || p_region_id);
        END IF;
    END modify_region;

    PROCEDURE remove_region(
        p_region_id IN REGIONS.REGION_ID%TYPE) IS
    BEGIN
        DELETE FROM regions WHERE region_id = p_region_id;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20052, 'Region nie istnieje: ' || p_region_id);
        END IF;
    END remove_region;

    FUNCTION fetch_region_by_id(
        p_region_id IN REGIONS.REGION_ID%TYPE)
        RETURN REGIONS%ROWTYPE IS
        region_record REGIONS%ROWTYPE;
    BEGIN
        SELECT * INTO region_record FROM regions WHERE region_id = p_region_id;
        RETURN region_record;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20053, 'Region nie istnieje: ' || p_region_id);
    END fetch_region_by_id;

    FUNCTION fetch_region_by_name(
        p_region_name IN REGIONS.REGION_NAME%TYPE)
        RETURN REGIONS%ROWTYPE IS
        region_record REGIONS%ROWTYPE;
    BEGIN
        SELECT * INTO region_record FROM regions WHERE UPPER(region_name) = UPPER(p_region_name);
        RETURN region_record;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20054, 'Region nie istnieje: ' || p_region_name);
    END fetch_region_by_name;

    PROCEDURE show_regions(
        p_region_id     IN REGIONS.REGION_ID%TYPE   DEFAULT NULL,
        p_name_like     IN VARCHAR2                 DEFAULT NULL,
        p_result        OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_result FOR
            SELECT r.* FROM regions r
            WHERE (p_region_id IS NULL OR r.region_id = p_region_id)
            AND (p_name_like IS NULL OR UPPER(r.region_name) LIKE UPPER('%' || p_name_like || '%'))
            ORDER BY r.region_id;
    END show_regions;

END region_manager_pkg;
/

BEGIN
    region_manager_pkg.insert_region(p_region_name => 'Antarctica');
    region_manager_pkg.insert_region(p_region_id => 10, p_region_name => 'Europe');
    region_manager_pkg.modify_region(10, 'EU');
    region_manager_pkg.remove_region(10);
END;
/