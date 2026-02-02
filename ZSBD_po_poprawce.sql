--Tabele--
CREATE TABLE proj_klienci (
    client_id NUMBER PRIMARY KEY,
    first_name VARCHAR2(50),
    last_name VARCHAR2(50),
    email VARCHAR2(100),
    phone VARCHAR2(20),
    created_at DATE,
    balance NUMBER
);

CREATE TABLE proj_bonusy (
    bonus_id NUMBER PRIMARY KEY,
    client_id NUMBER,
    bonus_amount NUMBER,
    bonus_type VARCHAR2(50),
    bonus_status VARCHAR2(20),
    start_date DATE,
    end_date DATE,
    CONSTRAINT fk_bonus_client
        FOREIGN KEY (client_id) REFERENCES proj_klienci(client_id)
);

CREATE TABLE proj_platnosci (
    payment_id NUMBER PRIMARY KEY,
    client_id NUMBER,
    payment_amount NUMBER,
    payment_method VARCHAR2(20),
    payment_date DATE,
    CONSTRAINT fk_payment_client
        FOREIGN KEY (client_id) REFERENCES proj_klienci(client_id)
);

CREATE TABLE proj_wydarzenia (
    event_id NUMBER PRIMARY KEY,
    event_name VARCHAR2(100),
    event_date DATE,
    team1 VARCHAR2(50),
    team2 VARCHAR2(50),
    status VARCHAR2(20)
);

CREATE TABLE proj_wyniki (
    result_id NUMBER PRIMARY KEY,
    event_id NUMBER,
    team1_score NUMBER,
    team2_score NUMBER,
    result_date DATE,
    CONSTRAINT fk_result_event
        FOREIGN KEY (event_id) REFERENCES proj_wydarzenia(event_id)
);

CREATE TABLE proj_zaklady (
    bet_id NUMBER PRIMARY KEY,
    client_id NUMBER,
    event_id NUMBER,
    bet_amount NUMBER,
    bet_type VARCHAR2(30),
    bet_odds NUMBER,
    bet_date DATE,
    bet_status VARCHAR2(20),
    CONSTRAINT fk_bet_client
        FOREIGN KEY (client_id) REFERENCES proj_klienci(client_id),
    CONSTRAINT fk_bet_event
        FOREIGN KEY (event_id) REFERENCES proj_wydarzenia(event_id)
);

CREATE TABLE log_table (
    log_id NUMBER PRIMARY KEY,
    log_message VARCHAR2(200),
    log_timestamp DATE
);

CREATE TABLE quarterly_summary (
    summary_id NUMBER PRIMARY KEY,
    year NUMBER,
    quarter NUMBER,
    total_amount NUMBER,
    total_count NUMBER,
    created_at DATE
);

CREATE TABLE monthly_summary (
    summary_id NUMBER PRIMARY KEY,
    year NUMBER,
    month NUMBER,
    total_amount NUMBER,
    total_count NUMBER,
    created_at DATE
);

CREATE TABLE yearly_summary (
    summary_id NUMBER PRIMARY KEY,
    year NUMBER,
    total_amount NUMBER,
    total_count NUMBER,
    created_at DATE
);

--TABELA DODANA PO POPRAWCE DLA WYSWIETLANIA ILE OBSTAWIŁ KLIENT--

CREATE TABLE client_bets_summary (
    summary_id NUMBER PRIMARY KEY,
    client_id NUMBER,
    total_bets_amount NUMBER,
    total_bets_count NUMBER,
    created_at DATE,
    CONSTRAINT fk_summary_client
        FOREIGN KEY (client_id) REFERENCES proj_klienci(client_id)
);

--Procdeury--

create or replace PROCEDURE add_client(
    p_client_id IN proj_klienci.client_id%TYPE,
    p_first_name IN proj_klienci.first_name%TYPE,
    p_last_name IN proj_klienci.last_name%TYPE,
    p_email IN proj_klienci.email%TYPE,
    p_phone IN proj_klienci.phone%TYPE,
    p_created_at IN proj_klienci.created_at%TYPE,
    p_balance IN proj_klienci.balance%TYPE
) AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM proj_klienci 
    WHERE client_id = p_client_id;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Client with this ID already exists');
    ELSE
        INSERT INTO proj_klienci (client_id, first_name, last_name, email, phone, created_at, balance)
        VALUES (p_client_id, p_first_name, p_last_name, p_email, p_phone, p_created_at, p_balance);
        COMMIT;
    END IF;
END add_client;

create or replace PROCEDURE add_client_with_pesel_check(
    p_client_id IN proj_klienci.client_id%TYPE,
    p_first_name IN proj_klienci.first_name%TYPE,
    p_last_name IN proj_klienci.last_name%TYPE,
    p_email IN proj_klienci.email%TYPE,
    p_phone IN proj_klienci.phone%TYPE,
    p_created_at IN proj_klienci.created_at%TYPE,
    p_balance IN proj_klienci.balance%TYPE,
    p_pesel IN VARCHAR2
) AS
BEGIN
    IF NOT validate_pesel(p_pesel) THEN
        RAISE_APPLICATION_ERROR(-20001, 'Invalid PESEL number');
    END IF;

    INSERT INTO proj_klienci (client_id, first_name, last_name, email, phone, created_at, balance)
    VALUES (p_client_id, p_first_name, p_last_name, p_email, p_phone, p_created_at, p_balance);
    COMMIT;
END add_client_with_pesel_check;

create or replace PROCEDURE archive_deleted_clients AS
BEGIN
    INSERT INTO proj_klienci_archive (client_id, first_name, last_name, email, phone, created_at, balance)
    SELECT client_id, first_name, last_name, email, phone, created_at, balance
    FROM proj_klienci
    WHERE client_id NOT IN (SELECT client_id FROM proj_klienci_archive);
    COMMIT;
END archive_deleted_clients;

create or replace PROCEDURE delete_client(p_client_id IN proj_klienci.client_id%TYPE) AS
BEGIN
    DELETE FROM proj_klienci WHERE client_id = p_client_id;
    COMMIT;
END delete_client;

--PROCEDURA DODANA PO POPRAWCE DLA WYSWIETLANIA ILE OBSTAWIŁ KLIENT--

create or replace PROCEDURE generate_client_bets_summary AS
BEGIN
    FOR rec IN (
        SELECT 
            client_id,
            SUM(bet_amount) AS total_bets_amount,
            COUNT(*) AS total_bets_count
        FROM proj_zaklady
        GROUP BY client_id
    ) LOOP
        INSERT INTO client_bets_summary (
            summary_id,
            client_id,
            total_bets_amount,
            total_bets_count,
            created_at
        ) VALUES (
            client_bets_summary_seq.NEXTVAL,  
            rec.client_id,
            rec.total_bets_amount,
            rec.total_bets_count,
            SYSDATE
        );
    END LOOP;

    COMMIT;
END generate_client_bets_summary;

create or replace PROCEDURE generate_monthly_summary AS
BEGIN
    FOR rec IN (
        SELECT
            EXTRACT(YEAR FROM payment_date) AS year,
            EXTRACT(MONTH FROM payment_date) AS month,
            SUM(payment_amount) AS total_amount,
            COUNT(*) AS total_count
        FROM proj_platnosci
        GROUP BY EXTRACT(YEAR FROM payment_date), EXTRACT(MONTH FROM payment_date)
    ) LOOP
        INSERT INTO monthly_summary (summary_id, year, month, total_amount, total_count, created_at)
        VALUES (
            monthly_summary_seq.NEXTVAL, -- ID z sekwencji
            rec.year,
            rec.month,
            rec.total_amount,
            rec.total_count,
            SYSDATE
        );
    END LOOP;

    COMMIT;
END generate_monthly_summary;
/

create or replace PROCEDURE generate_quarterly_summary AS
BEGIN
    INSERT INTO quarterly_summary (year, quarter, total_amount, total_count, created_at)
    SELECT
        EXTRACT(YEAR FROM payment_date) AS year,
        CEIL(EXTRACT(MONTH FROM payment_date) / 3) AS quarter,  -- Obliczanie kwartału
        SUM(payment_amount) AS total_amount,
        COUNT(*) AS total_count,
        SYSDATE AS created_at
    FROM proj_platnosci
    GROUP BY EXTRACT(YEAR FROM payment_date), CEIL(EXTRACT(MONTH FROM payment_date) / 3);
    COMMIT;
END generate_quarterly_summary;

create or replace PROCEDURE generate_yearly_summary AS
BEGIN
    INSERT INTO yearly_summary (year, total_amount, total_count, created_at)
    SELECT
        EXTRACT(YEAR FROM payment_date) AS year,
        SUM(payment_amount) AS total_amount,
        COUNT(*) AS total_count,
        SYSDATE AS created_at
    FROM proj_platnosci
    GROUP BY EXTRACT(YEAR FROM payment_date);
    COMMIT;
END generate_yearly_summary;

create or replace PROCEDURE log_message(p_message IN VARCHAR2) AS
BEGIN
    INSERT INTO log_table (log_id, log_message, log_timestamp)
    VALUES (log_table_seq.NEXTVAL, p_message, SYSDATE);
    COMMIT;
END log_message;

create or replace PROCEDURE update_client(
    p_client_id IN proj_klienci.client_id%TYPE,
    p_first_name IN proj_klienci.first_name%TYPE,
    p_last_name IN proj_klienci.last_name%TYPE,
    p_email IN proj_klienci.email%TYPE,
    p_phone IN proj_klienci.phone%TYPE,
    p_balance IN proj_klienci.balance%TYPE
) AS
BEGIN
    UPDATE proj_klienci
    SET first_name = p_first_name,
        last_name = p_last_name,
        email = p_email,
        phone = p_phone,
        balance = p_balance
    WHERE client_id = p_client_id;
    COMMIT;
END update_client;

--Walidacja--

create or replace FUNCTION validate_pesel(p_pesel IN VARCHAR2) RETURN BOOLEAN AS
    v_length NUMBER;
BEGIN
    v_length := LENGTH(p_pesel);
    IF v_length != 11 THEN
        RETURN FALSE;
    END IF;
    RETURN TRUE;
END validate_pesel;

--TRIGGERY--

create or replace TRIGGER trg_log_client_delete
AFTER DELETE ON proj_klienci
FOR EACH ROW
BEGIN
  INSERT INTO log_table(log_id, log_message, log_timestamp)
  VALUES (log_table_seq.NEXTVAL, 'Deleted client: ' || :OLD.client_id, SYSDATE);
END;

create or replace TRIGGER trg_log_client_insert
AFTER INSERT ON proj_klienci
FOR EACH ROW
BEGIN
  INSERT INTO log_table(log_id, log_message, log_timestamp)
  VALUES (log_table_seq.NEXTVAL, 'Added client: ' || :NEW.client_id, SYSDATE);
END;

create or replace TRIGGER trg_log_client_update
AFTER UPDATE ON proj_klienci
FOR EACH ROW
BEGIN
  INSERT INTO log_table(log_id, log_message, log_timestamp)
  VALUES (log_table_seq.NEXTVAL, 'Updated client: ' || :NEW.client_id, SYSDATE);
END;

--Sekwencje--

--SEKWENCJA DODANA PO POPRAWCE DLA WYSWIETLANIA ILE OBSTAWIŁ KLIENT--

CREATE SEQUENCE client_bets_summary_seq
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

CREATE SEQUENCE log_table_seq
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

CREATE SEQUENCE monthly_summary_seq
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

CREATE SEQUENCE quarterly_summary_seq
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

CREATE SEQUENCE yearly_summary_seq
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;