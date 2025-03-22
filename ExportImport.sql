CREATE OR REPLACE DIRECTORY MY_DIRECTORY AS 'coursePDB';


GRANT READ, WRITE ON DIRECTORY MY_DIRECTORY TO PUBLIC;
SELECT * FROM ALL_DIRECTORIES WHERE DIRECTORY_NAME = 'MY_DIRECTORY';

CREATE OR REPLACE PROCEDURE ExportUsersToJson(p_file_name IN VARCHAR2) AS
    v_file UTL_FILE.FILE_TYPE;    -- ���������� �����
    v_json CLOB;                  -- JSON ������
    v_buffer VARCHAR2(32000);     -- ����� ��� ������ ��������
    v_chunk_size CONSTANT PLS_INTEGER := 30000; -- ������ ����� ������
BEGIN
    -- ��������� ���� ��� ������
    v_file := UTL_FILE.FOPEN('MY_DIRECTORY', p_file_name, 'W');

    -- �������� ������������ JSON �������
    v_json := '[';

    -- ������ ��� ������� ������
    FOR rec IN (SELECT User_id, User_role, login, pass, user_name, last_name, phone_number, pasport
                FROM UsersView) LOOP
        -- ��������� ������ JSON ��� ������� ������
        v_json := v_json || '{"User_id": ' || rec.User_id ||
                   ', "User_role": ' || rec.User_role ||
                   ', "login": "' || rec.login ||
                   '", "pass": "' || rec.pass ||
                   '", "user_name": "' || rec.user_name ||
                   '", "last_name": "' || rec.last_name ||
                   '", "phone_number": "' || rec.phone_number ||
                   '", "pasport": "' || rec.pasport || '"},';

        -- ��������� ����� JSON. ���� ��������� �����, ���������� ����� � ����
        WHILE LENGTH(v_json) > v_chunk_size LOOP
            v_buffer := SUBSTR(v_json, 1, v_chunk_size);
            UTL_FILE.PUT_LINE(v_file, v_buffer);
            v_json := SUBSTR(v_json, v_chunk_size + 1);
        END LOOP;
    END LOOP;

    -- ������� ��������� ������� � ��������� ������
    v_json := RTRIM(v_json, ',') || ']';

    -- ���������� ���������� JSON
    WHILE LENGTH(v_json) > 0 LOOP
        v_buffer := SUBSTR(v_json, 1, v_chunk_size);
        UTL_FILE.PUT_LINE(v_file, v_buffer);
        v_json := SUBSTR(v_json, v_chunk_size + 1);
    END LOOP;

    -- ��������� ����
    UTL_FILE.FCLOSE(v_file);

    DBMS_OUTPUT.PUT_LINE('���� ������� ������� � MY_DIRECTORY: ' || p_file_name);
EXCEPTION
    WHEN OTHERS THEN
        -- ��������� ���� � ������ ������
        IF UTL_FILE.IS_OPEN(v_file) THEN
            UTL_FILE.FCLOSE(v_file);
        END IF;
        DBMS_OUTPUT.PUT_LINE('������ ��� ������ �����: ' || SQLERRM);
END ExportUsersToJson;
/




CREATE OR REPLACE PROCEDURE ExportUsersToJson(p_file_name IN VARCHAR2) AS
    v_file UTL_FILE.FILE_TYPE;        -- ���������� �����
    v_json_line VARCHAR2(32767);      -- ���������� ��� ���������� �������� ������
BEGIN
    -- ��������� ���� ��� ������
    v_file := UTL_FILE.FOPEN('MY_DIRECTORY', p_file_name, 'W');

    -- �������� ������������ JSON �������
    UTL_FILE.PUT_LINE(v_file, '[');

    -- ������ ��� ������� ������
    FOR rec IN (SELECT User_id, User_role, login, pass, user_name, last_name, phone_number, pasport
                FROM UsersView) LOOP
        -- ��������� ������ JSON ��� ������� ������
        v_json_line := '{"User_id": ' || rec.User_id ||
                       ', "User_role": ' || rec.User_role ||
                       ', "login": "' || rec.login ||
                       '", "pass": "' || rec.pass ||
                       '", "user_name": "' || rec.user_name ||
                       '", "last_name": "' || rec.last_name ||
                       '", "phone_number": "' || rec.phone_number ||
                       '", "pasport": "' || rec.pasport || '"},';
        
        -- �������� ������ � ����

        UTL_FILE.PUT_LINE(v_file, v_json_line);
    END LOOP;

    -- ������� ��������� ������� � ��������� ������
    UTL_FILE.PUT_LINE(v_file, '{}]'); -- ��������� ������ ������, ����� ��������� ������

    -- ��������� ����
    UTL_FILE.FCLOSE(v_file);

    DBMS_OUTPUT.PUT_LINE('���� ������� ������� � MY_DIRECTORY: ' || p_file_name);
EXCEPTION
    WHEN OTHERS THEN
        -- ��������� ���� � ������ ������
        IF UTL_FILE.IS_OPEN(v_file) THEN
            UTL_FILE.FCLOSE(v_file);
        END IF;
        DBMS_OUTPUT.PUT_LINE('������ ��� ������ �����: ' || SQLERRM);
END ExportUsersToJson;
/


CREATE OR REPLACE PROCEDURE ImportUsersFromJson(p_file_name IN VARCHAR2) AS
    v_file UTL_FILE.FILE_TYPE;            -- ���������� �����
    v_json_line VARCHAR2(32767);          -- ���������� ��� ���������� �������� ������
    v_user_id NUMBER;                     -- ���������� ��� User_id
    v_user_role NUMBER;                   -- ���������� ��� User_role
    v_login VARCHAR2(255);                -- ���������� ��� login
    v_pass VARCHAR2(255);                 -- ���������� ��� pass
    v_user_name VARCHAR2(255);            -- ���������� ��� user_name
    v_last_name VARCHAR2(255);            -- ���������� ��� last_name
    v_phone_number VARCHAR2(20);          -- ���������� ��� phone_number
    v_pasport VARCHAR2(20);               -- ���������� ��� pasport
BEGIN
    -- ��������� ���� ��� ������
    v_file := UTL_FILE.FOPEN('MY_DIRECTORY', p_file_name, 'R');

    -- ������ ������ ������ (������ �������)
    UTL_FILE.GET_LINE(v_file, v_json_line); -- ������ ������, ���������� '['

    -- ������ ������, ���� �� ��������� ����� �����
    LOOP
        BEGIN
            UTL_FILE.GET_LINE(v_file, v_json_line); -- ������ ������ ������

            -- ������� ������� � ������� �������� ������
            v_json_line := TRIM(REPLACE(REPLACE(v_json_line, '{', ''), '}', ''));

            -- ��������� ������ �� JSON-������
            v_user_id := TO_NUMBER(REGEXP_SUBSTR(v_json_line, '"User_id":\s*(\d+)', 1, 1, NULL, 1));
            v_user_role := TO_NUMBER(REGEXP_SUBSTR(v_json_line, '"User_role":\s*(\d+)', 1, 1, NULL, 1));
            v_login := REGEXP_SUBSTR(v_json_line, '"login":\s*"([^"]+)"', 1, 1, NULL, 1);
            v_pass := REGEXP_SUBSTR(v_json_line, '"pass":\s*"([^"]+)"', 1, 1, NULL, 1);
            v_user_name := REGEXP_SUBSTR(v_json_line, '"user_name":\s*"([^"]+)"', 1, 1, NULL, 1);
            v_last_name := REGEXP_SUBSTR(v_json_line, '"last_name":\s*"([^"]+)"', 1, 1, NULL, 1);
            v_phone_number := REGEXP_SUBSTR(v_json_line, '"phone_number":\s*"([^"]+)"', 1, 1, NULL, 1);
            v_pasport := REGEXP_SUBSTR(v_json_line, '"pasport":\s*"([^"]+)"', 1, 1, NULL, 1);

            -- ��������� ������ � ������� Users
            INSERT INTO Users (User_id, User_role, login, pass, user_name, last_name, phone_number, pasport)
            VALUES (v_user_id, v_user_role, v_login, v_pass, v_user_name, v_last_name, v_phone_number, v_pasport);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                EXIT; -- ����� �� �����, ���� ������ ������ ���
            WHEN OTHERS THEN
                -- ��������� ������
                DBMS_OUTPUT.PUT_LINE('������ ��� ��������� ������: ' || SQLERRM);
        END;
    END LOOP;

    -- ��������� ����
    UTL_FILE.FCLOSE(v_file);

    DBMS_OUTPUT.PUT_LINE('������ ������� ������������� �� �����: ' || p_file_name);
EXCEPTION
    WHEN OTHERS THEN
        -- ��������� ���� � ������ ������
        IF UTL_FILE.IS_OPEN(v_file) THEN
            UTL_FILE.FCLOSE(v_file);
        END IF;
        DBMS_OUTPUT.PUT_LINE('������ ��� ������� �����: ' || SQLERRM);
END ImportUsersFromJson;
/



CREATE OR REPLACE PROCEDURE Import_Role_From_JSON (
    p_file_name IN VARCHAR2
) AS
    l_json_clob CLOB;
    l_file UTL_FILE.FILE_TYPE;
BEGIN
    -- ������ JSON �� �����
    l_file := UTL_FILE.FOPEN('MY_DIRECTORY', p_file_name, 'r', 32767);
    UTL_FILE.GET_LINE(l_file, l_json_clob);
    UTL_FILE.FCLOSE(l_file);

    -- ������ JSON � ������� ������ � ������� Role
    FOR rec IN (
        SELECT *
        FROM JSON_TABLE(
            l_json_clob,
            '$[*]'
            COLUMNS (
                Role_id NUMBER PATH '$.Role_id',  -- ��������� Role_id, ���� �� ����
                name VARCHAR2(100) PATH '$.name',
                role_level NUMBER PATH '$.role_level'
            )
        )
    ) LOOP
        -- ���������, ���� Role_id ������
        IF rec.Role_id IS NOT NULL THEN
            INSERT INTO Role (Role_id, name, role_level)
            VALUES (rec.Role_id, rec.name, rec.role_level);
        ELSE
            -- ���� Role_id �� ������, ��������� ������ name � role_level
            INSERT INTO Role (name, role_level)
            VALUES (rec.name, rec.role_level);
        END IF;
    END LOOP;
END;
/
CREATE OR REPLACE FUNCTION Export_Users_To_JSON RETURN CLOB IS
    v_json CLOB := '[ ';
    v_first BOOLEAN := TRUE; -- ���� ��� ���������� ��������
    CURSOR user_cursor IS
        SELECT User_id, User_role, login, pass, user_name, last_name, phone_number, pasport FROM Users;
BEGIN
    FOR user_rec IN user_cursor LOOP
        IF NOT v_first THEN
            v_json := v_json || ', '; -- ��������� ������� ����� ����� ��������
        END IF;

        v_json := v_json || JSON_OBJECT(
            'User_id' VALUE user_rec.User_id,
            'User_role' VALUE user_rec.User_role,
            'login' VALUE user_rec.login,
            'pass' VALUE user_rec.pass,
            'user_name' VALUE user_rec.user_name,
            'last_name' VALUE user_rec.last_name,
            'phone_number' VALUE user_rec.phone_number,
            'pasport' VALUE user_rec.pasport
        );

        v_first := FALSE; -- ����� ������ ������ ������������� ����
    END LOOP;

    v_json := v_json || ' ]'; -- ��������� ������

    RETURN v_json;
EXCEPTION
    WHEN OTHERS THEN
        RETURN '������: ' || SQLERRM;
END export_users_to_json;
/

CREATE OR REPLACE PROCEDURE Import_Users_From_JSON (
    p_file_name IN VARCHAR2
) AS
    l_json_clob CLOB;
    l_file UTL_FILE.FILE_TYPE;
BEGIN
    -- ������ JSON �� �����
    l_file := UTL_FILE.FOPEN('MY_DIRECTORY', p_file_name, 'r', 32767);
    UTL_FILE.GET_LINE(l_file, l_json_clob);
    UTL_FILE.FCLOSE(l_file);

    -- ������ JSON � ������� ������ � ������� Users
    FOR rec IN (
        SELECT *
        FROM JSON_TABLE(
            l_json_clob,
            '$[*]'
            COLUMNS (
                User_id NUMBER PATH '$.User_id',  -- ��������� User_id, ���� �� ����
                User_role NUMBER PATH '$.User_role',
                login VARCHAR2(100) PATH '$.login',
                pass VARCHAR2(255) PATH '$.pass',
                user_name VARCHAR2(100) PATH '$.user_name',
                last_name VARCHAR2(100) PATH '$.last_name',
                phone_number VARCHAR2(100) PATH '$.phone_number',
                pasport VARCHAR2(100) PATH '$.pasport'
            )
        )
    ) LOOP
        -- ���������, ���� User_id ������
        IF rec.User_id IS NOT NULL THEN
            INSERT INTO Users (User_id, User_role, login, pass, user_name, last_name, phone_number, pasport)
            VALUES (rec.User_id, rec.User_role, rec.login, rec.pass, rec.user_name, rec.last_name, rec.phone_number, rec.pasport);
        ELSE
            -- ���� User_id �� ������, ��������� ������ ��������� ����
            INSERT INTO Users (User_role, login, pass, user_name, last_name, phone_number, pasport)
            VALUES (rec.User_role, rec.login, rec.pass, rec.user_name, rec.last_name, rec.phone_number, rec.pasport);
        END IF;
    END LOOP;
END;
/


CREATE OR REPLACE PROCEDURE Export_Cash_Accounts_To_JSON (
    p_file_name IN VARCHAR2
) AS
    l_json_clob CLOB;
    l_file UTL_FILE.FILE_TYPE;
BEGIN
    -- ��������� JSON �� ������� Cash_accounts
    SELECT JSON_ARRAYAGG(
               JSON_OBJECT(
                   'Cash_id' VALUE Cash_id,
                   'Cash_owner' VALUE Cash_owner,
                   'balance' VALUE balance,
                   'Cash_name' VALUE Cash_name,
                   'IsBlocked' VALUE IsBlocked,
                   'Creation_date' VALUE TO_CHAR(Creation_date, 'YYYY-MM-DD'),
                   'Currency_id' VALUE Currency_id
               ) RETURNING CLOB
           )
    INTO l_json_clob
    FROM Cash_accounts;

    -- ������ JSON � ����
    l_file := UTL_FILE.FOPEN('MY_DIRECTORY', p_file_name, 'w', 32767);
    UTL_FILE.PUT_LINE(l_file, l_json_clob);
    UTL_FILE.FCLOSE(l_file);
END;
/
CREATE OR REPLACE PROCEDURE Import_Cash_Accounts_From_JSON (
    p_file_name IN VARCHAR2
) AS
    l_json_clob CLOB;
    l_file UTL_FILE.FILE_TYPE;
BEGIN
    -- ������ JSON �� �����
    l_file := UTL_FILE.FOPEN('MY_DIRECTORY', p_file_name, 'r', 32767);
    UTL_FILE.GET_LINE(l_file, l_json_clob);
    UTL_FILE.FCLOSE(l_file);

    -- ������ JSON � ������� ������ � ������� Cash_accounts
    FOR rec IN (
        SELECT *
        FROM JSON_TABLE(
            l_json_clob,
            '$[*]'
            COLUMNS (
                Cash_id VARCHAR2(100) PATH '$.Cash_id',
                Cash_owner NUMBER PATH '$.Cash_owner',
                balance NUMBER PATH '$.balance',
                Cash_name VARCHAR2(100) PATH '$.Cash_name',
                IsBlocked NUMBER PATH '$.IsBlocked',
                Creation_date VARCHAR2(10) PATH '$.Creation_date', -- ������ ��� ������
                Currency_id VARCHAR2(4) PATH '$.Currency_id'
            )
        )
    ) LOOP
        INSERT INTO Cash_accounts (
            Cash_id, Cash_owner, balance, Cash_name, IsBlocked, Creation_date, Currency_id
        )
        VALUES (
            rec.Cash_id, 
            rec.Cash_owner, 
            rec.balance, 
            rec.Cash_name,
            NVL(rec.IsBlocked, 0), 
            NVL(TO_DATE(rec.Creation_date, 'YYYY-MM-DD'), TRUNC(SYSDATE)), 
            rec.Currency_id
        );
    END LOOP;
END;
/


CREATE OR REPLACE PROCEDURE Export_History_To_JSON (
    p_file_name IN VARCHAR2
) AS
    l_json_clob CLOB;
    l_file UTL_FILE.FILE_TYPE;
BEGIN
    -- ��������� JSON �� ������ ������� History
    SELECT JSON_ARRAYAGG(
               JSON_OBJECT(
                   'Operation_id' VALUE Operation_id,
                   'Transactor' VALUE Transactor,
                   'cash_from' VALUE cash_from,
                   'cash_to' VALUE cash_to,
                   'operation' VALUE operation,
                   'amount' VALUE amount,
                   'operation_description' VALUE operation_description
               ) RETURNING CLOB
           )
    INTO l_json_clob
    FROM uncrypt_History;

    -- ������ JSON � ����
    l_file := UTL_FILE.FOPEN('MY_DIRECTORY', p_file_name, 'w', 32767);
    UTL_FILE.PUT_LINE(l_file, l_json_clob);
    UTL_FILE.FCLOSE(l_file);
END;
/



CREATE OR REPLACE PROCEDURE Import_History_From_JSON (
    p_file_name IN VARCHAR2
) AS
    l_json_clob CLOB;
    l_file UTL_FILE.FILE_TYPE;
BEGIN
    -- ������ JSON �� �����
    l_file := UTL_FILE.FOPEN('MY_DIRECTORY', p_file_name, 'r', 32767);
    UTL_FILE.GET_LINE(l_file, l_json_clob);
    UTL_FILE.FCLOSE(l_file);

    -- ������ JSON � ������� ������ � ������� History
    FOR rec IN (
        SELECT *
        FROM JSON_TABLE(
            l_json_clob,
            '$[*]'
            COLUMNS (
                Operation_id NUMBER PATH '$.Operation_id',
                Transactor NUMBER PATH '$.Transactor',
                cash_from VARCHAR2(100) PATH '$.cash_from',
                cash_to VARCHAR2(100) PATH '$.cash_to',
                operation VARCHAR2(100) PATH '$.operation',
                amount VARCHAR2(100) PATH '$.amount',
                operation_description VARCHAR2(1000) PATH '$.operation_description'
            )
        )
    ) LOOP
        INSERT INTO History (Operation_id, Transactor, cash_from, cash_to, operation, amount, operation_description)
        VALUES (rec.Operation_id, rec.Transactor, rec.cash_from, rec.cash_to, rec.operation, rec.amount, rec.operation_description);
    END LOOP;
END;
/


CREATE OR REPLACE PROCEDURE Export_Queue_To_JSON (
    p_file_name IN VARCHAR2
) AS
    l_json_clob CLOB;
    l_file UTL_FILE.FILE_TYPE;
BEGIN
    -- ��������� JSON �� ������ ������� Queue
    SELECT JSON_ARRAYAGG(
               JSON_OBJECT(
                   'Operation_id' VALUE Operation_id,
                   'Transactor' VALUE Transactor,
                   'cash_from' VALUE cash_from,
                   'cash_to' VALUE cash_to,
                   'operation' VALUE operation,
                   'amount' VALUE amount,
                   'operation_description' VALUE operation_description
               ) RETURNING CLOB
           )
    INTO l_json_clob
    FROM uncrypt_Queue;

    -- ������ JSON � ����
    l_file := UTL_FILE.FOPEN('MY_DIRECTORY', p_file_name, 'w', 32767);
    UTL_FILE.PUT_LINE(l_file, l_json_clob);
    UTL_FILE.FCLOSE(l_file);
END;
/


CREATE OR REPLACE PROCEDURE Import_Queue_From_JSON (
    p_file_name IN VARCHAR2
) AS
    l_json_clob CLOB;
    l_file UTL_FILE.FILE_TYPE;
BEGIN
    -- ������ JSON �� �����
    l_file := UTL_FILE.FOPEN('MY_DIRECTORY', p_file_name, 'r', 32767);
    UTL_FILE.GET_LINE(l_file, l_json_clob);
    UTL_FILE.FCLOSE(l_file);

    -- ������ JSON � ������� ������ � ������� Queue
    FOR rec IN (
        SELECT *
        FROM JSON_TABLE(
            l_json_clob,
            '$[*]'
            COLUMNS (
                Operation_id NUMBER PATH '$.Operation_id',
                Transactor NUMBER PATH '$.Transactor',
                cash_from VARCHAR2(100) PATH '$.cash_from',
                cash_to VARCHAR2(100) PATH '$.cash_to',
                operation VARCHAR2(100) PATH '$.operation',
                amount VARCHAR2(100) PATH '$.amount',
                operation_description VARCHAR2(1000) PATH '$.operation_description'
            )
        )
    ) LOOP
        INSERT INTO Queue (Operation_id, Transactor, cash_from, cash_to, operation, amount, operation_description)
        VALUES (rec.Operation_id, rec.Transactor, rec.cash_from, rec.cash_to, rec.operation, rec.amount, rec.operation_description);
    END LOOP;
END;
/












CREATE OR REPLACE PROCEDURE Export_Currencies_To_JSON (
    p_file_name IN VARCHAR2
) AS
    l_json_clob CLOB;
    l_file UTL_FILE.FILE_TYPE;
BEGIN
    -- ��������� JSON �� ������� Currencies
    SELECT JSON_ARRAYAGG(
               JSON_OBJECT(
                   'Currency_id' VALUE Currency_id,
                   'Currency_name' VALUE Currency_name,
                   'Exchange_rate' VALUE Exchange_rate
               ) RETURNING CLOB
           )
    INTO l_json_clob
    FROM Currencies;

    -- ������ JSON � ����
    l_file := UTL_FILE.FOPEN('MY_DIRECTORY', p_file_name, 'w', 32767);
    UTL_FILE.PUT_LINE(l_file, l_json_clob);
    UTL_FILE.FCLOSE(l_file);
END;
/





CREATE OR REPLACE PROCEDURE Import_Currencies_From_JSON (
    p_file_name IN VARCHAR2
) AS
    l_json_clob CLOB;
    l_file UTL_FILE.FILE_TYPE;
BEGIN
    -- ������ JSON �� �����
    l_file := UTL_FILE.FOPEN('MY_DIRECTORY', p_file_name, 'r', 32767);
    UTL_FILE.GET_LINE(l_file, l_json_clob);
    UTL_FILE.FCLOSE(l_file);

    -- ������ JSON � ������� ������ � ������� Currencies
    FOR rec IN (
        SELECT *
        FROM JSON_TABLE(
            l_json_clob,
            '$[*]'
            COLUMNS (
                Currency_id VARCHAR2(4) PATH '$.Currency_id',
                Currency_name VARCHAR2(100) PATH '$.Currency_name',
                Exchange_rate NUMBER PATH '$.Exchange_rate'
            )
        )
    ) LOOP
        INSERT INTO Currencies (
            Currency_id, Currency_name, Exchange_rate
        )
        VALUES (
            rec.Currency_id, rec.Currency_name, rec.Exchange_rate
        );
    END LOOP;
END;
/


CREATE OR REPLACE PROCEDURE Export_Currencies_To_JSON (
    p_file_name IN VARCHAR2
) AS
    l_json_clob CLOB;
    l_file UTL_FILE.FILE_TYPE;
BEGIN
    -- ��������� JSON �� ������� Currencies
    SELECT JSON_ARRAYAGG(
               JSON_OBJECT(
                   'Currency_id' VALUE Currency_id,
                   'Currency_name' VALUE Currency_name,
                   'Exchange_rate' VALUE TO_CHAR(Exchange_rate, 'FM9999990.0000')
               ) RETURNING CLOB
           )
    INTO l_json_clob
    FROM Currencies;

    -- ������ JSON � ����
    l_file := UTL_FILE.FOPEN('MY_DIRECTORY', p_file_name, 'w', 32767);
    UTL_FILE.PUT_LINE(l_file, l_json_clob);
    UTL_FILE.FCLOSE(l_file);
END;
/



CREATE OR REPLACE PROCEDURE Import_Currencies_From_JSON (
    p_file_name IN VARCHAR2
) AS
    l_json_clob CLOB;
    l_file UTL_FILE.FILE_TYPE;
BEGIN
    -- ������ JSON �� �����
    l_file := UTL_FILE.FOPEN('MY_DIRECTORY', p_file_name, 'r', 32767);
    UTL_FILE.GET_LINE(l_file, l_json_clob);
    UTL_FILE.FCLOSE(l_file);

    -- ������ JSON � ������� ������ � ������� Currencies
    FOR rec IN (
        SELECT *
        FROM JSON_TABLE(
            l_json_clob,
            '$[*]'
            COLUMNS (
                Currency_id VARCHAR2(4) PATH '$.Currency_id',
                Currency_name VARCHAR2(100) PATH '$.Currency_name',
                Exchange_rate NUMBER PATH '$.Exchange_rate'
            )
        )
    ) LOOP
        INSERT INTO Currencies (
            Currency_id, Currency_name, Exchange_rate
        )
        VALUES (
            rec.Currency_id, rec.Currency_name, rec.Exchange_rate
        );
    END LOOP;
END;
/

