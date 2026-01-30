SET SERVEROUTPUT ON

-- 1. Stworzyć blok anonimowy wypisujący zmienną numer_max równą 
-- maksymalnemu numerowi Departamentu i dodaj do tabeli 
-- departamenty – departament z numerem o 10 wiekszym, 
-- typ pola dla zmiennej z nazwą nowego departamentu 
-- (zainicjować na EDUCATION) ustawić taki jak dla 
-- pola department_name w tabeli (%TYPE)

DECLARE
    numer_max departments.department_id%type;
    nowy_numer departments.department_id%type;
    nowa_nazwa departments.department_name%type := 'EDUCATION';
BEGIN
    SELECT MAX(department_id) INTO numer_max FROM departments;
    
    DBMS_OUTPUT.PUT_LINE(
        'Maksymalny numer departamentu: ' ||
        numer_max
    );
    
    nowy_numer := numer_max + 10;
    
    INSERT INTO departments (department_id, department_name)
    VALUES (nowy_numer, nowa_nazwa);
    
    DBMS_OUTPUT.PUT_LINE('Dodano nowy department:');
    DBMS_OUTPUT.PUT_LINE('ID: ' || nowy_numer);
    DBMS_OUTPUT.PUT_LINE('Nazwa: ' || nowa_nazwa);
    
    COMMIT;
EXCEPTION 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Błąd: ' || SQLERRM);
        ROLLBACK;
END;
/

-- 2. Do poprzedniego skryptu dodaj instrukcje zmieniającą 
-- location_id (3000) dla dodanego departamentu.

DECLARE
    numer_max departments.department_id%type;
    nowy_numer departments.department_id%type;
    nowa_nazwa departments.department_name%type := 'EDUCATION';
BEGIN
    SELECT MAX(department_id) INTO numer_max FROM departments;
    
    DBMS_OUTPUT.PUT_LINE(
        'Maksymalny numer departamentu: ' ||
        numer_max
    );
    
    nowy_numer := numer_max + 10;
    
    INSERT INTO departments (department_id, department_name)
    VALUES (nowy_numer, nowa_nazwa);
    
    UPDATE departments
    SET location_id = 3000
    WHERE department_id = nowy_numer;
    
    DBMS_OUTPUT.PUT_LINE('Dodano nowy department:');
    DBMS_OUTPUT.PUT_LINE('ID: ' || nowy_numer);
    DBMS_OUTPUT.PUT_LINE('Nazwa: ' || nowa_nazwa);
    DBMS_OUTPUT.PUT_LINE('Location ID zmienione na: 3000');
    
    COMMIT;
EXCEPTION 
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Błąd: ' || SQLERRM);
        ROLLBACK;
END;
/

-- 3. Stwórz tabelę nowa z jednym polem typu varchar a 
-- następnie wpisz do niej za pomocą pętli liczby 
-- od 1 do 10 bez liczb 4 i 6.

CREATE TABLE nowa (
    liczba VARCHAR2(10)
);

DECLARE
    i NUMBER;
BEGIN
    FOR i in 1..10 LOOP
        IF i NOT IN (4, 6) THEN
            INSERT INTO nowa (liczba) VALUES (TO_CHAR(i));
        END IF;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE(
        'Dodano liczby do tabeli nowa (bez 4 i 6)'
    );
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Błąd: ' || SQLERRM);
        ROLLBACK;
END;
/

SELECT * FROM nowa ORDER BY TO_NUMBER(liczba);

-- 4. Wyciągnąć informacje z tabeli countries do jednej zmiennej 
-- (%ROWTYPE) dla kraju o identyfikatorze ‘CA’. 
-- Wypisać nazwę i region_id na ekran.

DECLARE
    kraj countries%ROWTYPE;
BEGIN
    SELECT *
    INTO kraj
    FROM countries
    WHERE country_id = 'CA';
    
    DBMS_OUTPUT.PUT_LINE('Nazwa kraju: ' || kraj.country_name);
    DBMS_OUTPUT.PUT_LINE('Region ID: ' || kraj.region_id);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Nie znaleziono kraju o ID: CA');
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE(
            'Znaleziono więcej niż jeden kraj o ID: CA'
        );
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Błąd: ' || SQLERRM);
END;
/

-- 5. Zadeklaruj kursor jako wynagrodzenie, nazwisko dla
-- departamentu o numerze 50. Dla elementów kursora wypisać 
-- na ekran, jeśli wynagrodzenie jest wyższe niż 3100:
-- nazwisko osoby i tekst ‘nie dawać podwyżki’ w przeciwnym 
-- przypadku: nazwisko + ‘dać podwyżkę’.

DECLARE
    CURSOR c_pracownicy IS
        SELECT salary, last_name
        FROM employees
        WHERE department_id = 50;
        
    v_wynagrodzenie employees.salary%TYPE;
    v_nazwisko employees.last_name%TYPE;
BEGIN
    OPEN c_pracownicy;
    
    LOOP
        FETCH c_pracownicy INTO v_wynagrodzenie, v_nazwisko;
        
        EXIT WHEN c_pracownicy%NOTFOUND;
        
        IF v_wynagrodzenie > 3100 THEN
            DBMS_OUTPUT.PUT_LINE(v_nazwisko || ' - nie dawać podwyżki');
        ELSE
            DBMS_OUTPUT.PUT_LINE(v_nazwisko || ' - dać podwyżkę');
        END IF;
    END LOOP;
    
    CLOSE c_pracownicy;
END;
/

-- 6. Zadeklarować kursor zwracający zarobki imię i nazwisko 
-- pracownika z parametrami, gdzie pierwsze dwa parametry 
-- określają widełki zarobków a trzeci część imienia pracownika. 
-- Wypisać na ekran pracowników:

--  a. z widełkami 1000- 5000 z częścią imienia a 
--  (może być również A)

DECLARE
    CURSOR c_pracownicy (
        p_min_wynagrodzenie NUMBER,
        p_max_wynagrodzenie NUMBER,
        p_czesc_imienia VARCHAR2
    ) IS
        SELECT salary, first_name, last_name
        FROM employees
        WHERE salary 
            BETWEEN p_min_wynagrodzenie AND p_max_wynagrodzenie
            AND UPPER(first_name) LIKE '%' ||
                UPPER(p_czesc_imienia) || '%';
BEGIN
    DBMS_OUTPUT.PUT_LINE(
        'Pracownicy z widełkami 1000-5000 i 
        imieniem zawierającym literę ''a'':'
    );
    
    FOR pracownik IN c_pracownicy(1000, 5000, 'a') LOOP
        DBMS_OUTPUT.PUT_LINE(
            pracownik.first_name || ' ' || pracownik.last_name ||
            ' - Wynagrodzenie: ' || pracownik.salary || ' PLN'
        );
    END LOOP;
END;
/

--  b. z widełkami 5000-20000 z częścią imienia u 
--  (może być również U)

DECLARE
    CURSOR c_pracownicy (
        p_min_wynagrodzenie NUMBER,
        p_max_wynagrodzenie NUMBER,
        p_czesc_imienia VARCHAR2
    ) IS
        SELECT salary, first_name, last_name
        FROM employees
        WHERE salary 
            BETWEEN p_min_wynagrodzenie AND p_max_wynagrodzenie
            AND UPPER(first_name) LIKE '%' ||
                UPPER(p_czesc_imienia) || '%';
BEGIN
    DBMS_OUTPUT.PUT_LINE(
        'Pracownicy z widełkami 5000-20000 i 
        imieniem zawierającym literę ''u'':'
    );
    
    FOR pracownik IN c_pracownicy(5000, 20000, 'u') LOOP
        DBMS_OUTPUT.PUT_LINE(
            pracownik.first_name || ' ' || pracownik.last_name ||
            ' - Wynagrodzenie: ' || pracownik.salary || ' PLN'
        );
    END LOOP;
END;
/

-- 9. Stwórz procedury:

--  a. dodającą wiersz do tabeli Jobs – z dwoma parametrami 
--  wejściowymi określającymi Job_id, Job_title, 
--  przetestuj działanie wrzuć wyjątki – co najmniej when others.

CREATE OR REPLACE PROCEDURE dodaj_nowe_stanowisko (
    p_job_id IN jobs.job_id%TYPE,
    p_job_title IN jobs.job_title%TYPE
)
IS
    v_istnieje NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_istnieje
    FROM jobs
    WHERE job_id = p_job_id;
    
    IF v_istnieje > 0 THEN
        DBMS_OUTPUT.PUT_LINE(
            'Błąd: Stanowisko o ID ' || 
            p_job_id || 
            ' już istnieje.'
        );
        RETURN;
    END IF;
    
    INSERT INTO jobs (job_id, job_title)
    VALUES (p_job_id, p_job_title);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE(
        'Dodano nowe stanowisko: ' || 
        p_job_id || 
        ' - ' || 
        p_job_title
    );
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Błąd: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Kod błędu: ' || SQLCODE);
        ROLLBACK;
END dodaj_nowe_stanowisko;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('Test 1: Dodanie poprawnego stanowiska');
    dodaj_nowe_stanowisko('IT_DEV', 'Developer');
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('Test 2: Próba dodania duplikatu');
    dodaj_nowe_stanowisko('IT_DEV', 'Inny Developer');
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('Test 3: Test NULL');
    dodaj_nowe_stanowisko(NULL, 'TEST');
END;
/

--  b. modyfikującą title w tabeli Jobs – 
--  z dwoma parametrami id dla którego ma być modyfikacja oraz 
--  nową wartość dla Job_title – przetestować działanie, 
--  dodać swój wyjątek dla no Jobs updated – 
--  najpierw sprawdzić numer błędu.

DECLARE
    v_rowcount NUMBER;
BEGIN
    UPDATE jobs 
    SET job_title = 'TEST'
    WHERE job_id = 'NIEISTNIEJACY_ID';
    
    v_rowcount := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('Liczba zaktualizowanych wierszy: ' || v_rowcount);
    DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE);
END;
/

CREATE OR REPLACE PROCEDURE modyfikuj_stanowisko (
    p_job_id IN jobs.job_id%TYPE,
    p_new_title IN jobs.job_title%TYPE
)
IS
    no_jobs_updated EXCEPTION;
    PRAGMA EXCEPTION_INIT(no_jobs_updated, -20001);
    
BEGIN
    UPDATE jobs
    SET job_title = p_new_title
    WHERE job_id = p_job_id;
    
    IF SQL%ROWCOUNT = 0 THEN
        RAISE no_jobs_updated;
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('Pomyślnie zaktualizowano stanowisko o ID: ' || p_job_id);
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Nieoczekiwany błąd: ' || SQLERRM);
        RAISE;
END modyfikuj_stanowisko;
/

BEGIN
    modyfikuj_stanowisko('IT_PROG', 'Programista IT');
END;
/

BEGIN
    modyfikuj_stanowisko('NIEISTNIEJACY', 'Nowa pozycja');
END;
/

--  c. usuwającą wiersz z tabeli Jobs o podanym Job_id – 
--  przetestować działanie, dodaj wyjątek dla no Jobs deleted.

DECLARE
    v_rowcount NUMBER;
BEGIN
    DELETE FROM jobs
    WHERE job_id = 'NIEISTNIEJACY_ID';
    
    v_rowcount := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE('Liczba usuniętych wierszy: ' || v_rowcount);
    DBMS_OUTPUT.PUT_LINE('SQLCODE: ' || SQLCODE);
END;
/

CREATE OR REPLACE PROCEDURE delete_job (
    p_job_id IN jobs.job_id%TYPE
)
IS
    no_jobs_deleted EXCEPTION;
    
    PRAGMA EXCEPTION_INIT(no_jobs_deleted, -20002);
    
    v_job_title jobs.job_title%TYPE;
    
BEGIN
    SELECT job_title INTO v_job_title
    FROM jobs
    WHERE job_id = p_job_id;
    
    DELETE FROM jobs
    WHERE job_id = p_job_id;
    
    IF SQL%ROWCOUNT = 0 THEN
        RAISE no_jobs_deleted;
    END IF;
    
    DBMS_OUTPUT.PUT_LINE(
        'Pomyślnie usunięto stanowisko: ' || 
        v_job_title || 
        '(ID: ' ||
        p_job_id ||
        ')'
    );
    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE(
                'Błąd: Nie znaleziono stanowiska o ID: ' ||
                p_job_id
            );
            RAISE no_jobs_deleted;
            
        WHEN no_jobs_deleted THEN
            DBMS_OUTPUT.PUT_LINE(
                'Błąd: Nie usunięto żadnego stanowiska. Sprawdź poprawność ID: ' ||
                p_job_id
            );
            
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Nieoczekiwany błąd: ' || SQLERRM);
            RAISE;
END delete_job;
/

BEGIN
    delete_job('IT_DEV');
END;
/

BEGIN
    delete_job('NIEISTNIEJACY');
END;
/

--  d. Wyciągającą zarobki i nazwisko 
--  (parametry zwracane przez procedurę) z tabeli employees 
--  dla pracownika o przekazanym jako parametr id.

CREATE OR REPLACE PROCEDURE get_employee_info (
    p_employee_id IN employees.employee_id%TYPE,
    p_last_name OUT employees.last_name%TYPE,
    p_salary OUT employees.salary%TYPE
)
IS
BEGIN
    SELECT last_name, salary
    INTO p_last_name, p_salary
    FROM employees
    WHERE employee_id = p_employee_id;
    
    DBMS_OUTPUT.PUT_LINE('Znaleziono pracownika o ID: ' || p_employee_id);
    DBMS_OUTPUT.PUT_LINE('Nazwisko pracownika: ' || p_last_name);
    DBMS_OUTPUT.PUT_LINE('Zarobki: ' || p_salary);
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE(
            'Błąd: Nie znaleziono pracownika o ID: ' || 
            p_employee_id
        );
        
        p_last_name := NULL;
        p_salary := NULL;
        
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE(
            'Błąd: Znaleziono więcej niż jednego pracownika o ID: ' ||
            p_employee_id
        );
        p_last_name := NULL;
        p_salary := NULL;
        
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Nieoczekiwany błąd: ' || SQLERRM);
        RAISE;
END get_employee_info;
/

DECLARE
    v_emp_id NUMBER := 100;
    v_last_name employees.last_name%TYPE;
    v_salary employees.salary%TYPE;
    v_bonus NUMBER;
BEGIN
    get_employee_info(v_emp_id, v_last_name, v_salary);
END;
/

--  e. dodającą do tabeli employees wiersz – 
--  większość parametrów ustawić na domyślne 
--  (id poprzez sekwencję), stworzyć wyjątek jeśli wynagrodzenie
--  dodawanego pracownika jest wyższe niż 20000

CREATE SEQUENCE employees_seq
START WITH 1000
INCREMENT BY 1
NOCACHE
NOCYCLE;

CREATE OR REPLACE PROCEDURE add_employee (
    p_first_name IN employees.first_name%TYPE DEFAULT NULL,
    p_last_name IN employees.last_name%TYPE,
    p_email IN employees.email%TYPE,
    p_job_id IN employees.job_id%TYPE,
    p_hire_date IN employees.hire_date%TYPE,
    
    p_phone_number  IN employees.phone_number%TYPE DEFAULT NULL,
    p_salary        IN employees.salary%TYPE DEFAULT 0,
    p_commission_pct IN employees.commission_pct%TYPE DEFAULT NULL,
    p_manager_id    IN employees.manager_id%TYPE DEFAULT NULL,
    p_department_id IN employees.department_id%TYPE DEFAULT NULL
)
IS
    salary_too_high_exception EXCEPTION;
    PRAGMA EXCEPTION_INIT(salary_too_high_exception, -20004);
    
    v_employee_id employees.employee_id%TYPE;
    
    v_hire_date DATE := SYSDATE;
    
BEGIN
    IF p_salary > 20000 THEN
        RAISE salary_too_high_exception;
    END IF;
    
    SELECT employees_seq.NEXTVAL INTO v_employee_id FROM dual;
    
    INSERT INTO employees (
        employee_id,
        first_name,
        last_name,
        email,
        phone_number,
        hire_date,
        job_id,
        salary,
        commission_pct,
        manager_id,
        department_id
    ) VALUES (
      v_employee_id,
      p_first_name,
      p_last_name,
      p_email,
      p_phone_number,
      v_hire_date,
      p_job_id,
      p_salary,
      p_commission_pct,
      p_manager_id,
      p_department_id
    );
    
    DBMS_OUTPUT.PUT_LINE('Pomyślnie dodano pracownika:');
    DBMS_OUTPUT.PUT_LINE('ID: ' || v_employee_id);
    DBMS_OUTPUT.PUT_LINE(
        'Imię i nazwisko: ' || 
        p_first_name || 
        ' ' || 
        p_last_name
    );
    DBMS_OUTPUT.PUT_LINE('Email: ' || p_email);
    DBMS_OUTPUT.PUT_LINE('Stanowisko: ' || p_job_id);
    DBMS_OUTPUT.PUT_LINE('Wynagrodzenie: ' || NVL(TO_CHAR(p_salary), '0'));
    
EXCEPTION
    WHEN salary_too_high_exception THEN
        DBMS_OUTPUT.PUT_LINE(
            'Błąd: Wynagrodzenie ' || 
            p_salary || 
            ' przekracza limit.'
        );
        DBMS_OUTPUT.PUT_LINE('Maksymalne dopuszczalne wynagrodzenie to 20000.');
        ROLLBACK;
        RAISE;
        
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Nieoczekiwany błąd: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END add_employee;
/

BEGIN
    add_employee(
        p_first_name => 'Jan',
        p_last_name => 'Kowalski',
        p_email => 'J.KOWALSKI',
        p_job_id => 'IT_PROG',
        p_hire_date => SYSDATE,
        p_salary => 5000,
        p_department_id => 60
    );
    COMMIT;
END;
/

BEGIN
    add_employee(
        p_first_name => 'Jan',
        p_last_name => 'Kowalski',
        p_email => 'J.KOWALSKI',
        p_job_id => 'IT_PROG',
        p_hire_date => SYSDATE,
        p_salary => 25000,
        p_department_id => 60
    );
    COMMIT;
END;
/