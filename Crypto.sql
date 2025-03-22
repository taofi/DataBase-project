

--drop table EncryptionKeys;
CREATE TABLE EncryptionKeys (
    Key_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    Key_value RAW(32) NOT NULL
);

--INSERT INTO EncryptionKeys (Key_value) VALUES (UTL_RAW.CAST_TO_RAW('128lsabd1ujosd91'));

-- Обновление ключа шифрования в таблице EncryptionKeys



CREATE OR REPLACE FUNCTION EncryptData (
    p_data IN VARCHAR2
) RETURN RAW IS
    v_key RAW(32);
    v_encrypted_data RAW(2000); -- Размер должен быть достаточным для хранения зашифрованных данных
BEGIN
    SELECT Key_value INTO v_key FROM EncryptionKeys WHERE Key_id = 1;

    v_encrypted_data := DBMS_CRYPTO.ENCRYPT(
        src => UTL_RAW.CAST_TO_RAW(p_data),
        typ => DBMS_CRYPTO.ENCRYPT_AES128 + DBMS_CRYPTO.CHAIN_CBC + DBMS_CRYPTO.PAD_PKCS5,
        key => v_key
    );

    RETURN v_encrypted_data;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'Ошибка при шифровании: ' || SQLERRM);
END;
/


CREATE OR REPLACE FUNCTION DecryptData (
    p_encrypted_data IN RAW
) RETURN VARCHAR2 IS
    v_key RAW(32);
    v_decrypted_data RAW(2000); 
BEGIN
    SELECT Key_value INTO v_key FROM EncryptionKeys WHERE Key_id = 1;

    -- Дешифрование данных
    v_decrypted_data := DBMS_CRYPTO.DECRYPT(
        src => p_encrypted_data,
        typ => DBMS_CRYPTO.ENCRYPT_AES128 + DBMS_CRYPTO.CHAIN_CBC + DBMS_CRYPTO.PAD_PKCS5,
        key => v_key
    );

    RETURN UTL_RAW.CAST_TO_VARCHAR2(v_decrypted_data);
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Ошибка при дешифровании: ' || SQLERRM);
END;
/




CREATE OR REPLACE FUNCTION EncryptCashId (
    p_cash_id IN NUMBER
) RETURN VARCHAR2 IS
    v_encrypted_id VARCHAR2(100);
BEGIN
    v_encrypted_id := EncryptData(TO_CHAR(p_cash_id));
    RETURN v_encrypted_id;
END;
/
CREATE OR REPLACE FUNCTION DecryptCashId (
    p_encrypted_cash_id IN VARCHAR2
) RETURN NUMBER IS
    v_cash_id NUMBER;
BEGIN
    v_cash_id := TO_NUMBER(DecryptData(p_encrypted_cash_id));
    RETURN v_cash_id;
END;
/

--=============               user                  ====================



CREATE OR REPLACE TRIGGER trg_encrypt_user_data
BEFORE INSERT OR UPDATE ON Users
FOR EACH ROW
BEGIN
    IF :OLD.login IS NULL OR :OLD.login != :NEW.login THEN
        :NEW.login := EncryptData(:NEW.login);  -- Шифрование login
    END IF;

    IF :OLD.user_name IS NULL OR :OLD.user_name != :NEW.user_name THEN
        :NEW.user_name := EncryptData(:NEW.user_name);  -- Шифрование user_name
    END IF;

    IF :OLD.last_name IS NULL OR :OLD.last_name != :NEW.last_name THEN
        :NEW.last_name := EncryptData(:NEW.last_name);  -- Шифрование last_name
    END IF;

    IF :OLD.phone_number IS NULL OR :OLD.phone_number != :NEW.phone_number THEN
        :NEW.phone_number := EncryptData(:NEW.phone_number);  -- Шифрование phone_number
    END IF;
    IF :OLD.pasport IS NULL OR :OLD.pasport != :NEW.pasport THEN
        :NEW.pasport := EncryptData(:NEW.pasport);  -- Шифрование phone_number
    END IF;
END;
/



CREATE OR REPLACE VIEW UsersView AS
SELECT 
    User_id,
    User_role,
    DecryptData(login) AS login,
    pass AS pass,
    DecryptData(user_name) AS user_name,
    DecryptData(last_name) AS last_name,
    DecryptData(phone_number) AS phone_number,
    DecryptData(pasport) AS pasport
FROM Users;





--==============                cash                   ===============


CREATE OR REPLACE TRIGGER trg_encrypt_cash_accounts
BEFORE INSERT OR UPDATE ON Cash_accounts
FOR EACH ROW
BEGIN
    IF :OLD.Cash_id IS NULL OR :OLD.Cash_id != :NEW.Cash_id THEN
            :NEW.Cash_id := EncryptCashId(:NEW.Cash_id);
    END IF;

    IF :OLD.balance IS NULL OR :OLD.balance != :NEW.balance THEN
           :NEW.balance := EncryptData(To_char(:NEW.balance)); -- Шифрование balance
    END IF;
    IF :OLD.Cash_name IS NULL OR :OLD.Cash_name != :NEW.Cash_name THEN
            :NEW.Cash_name := EncryptData(:NEW.Cash_name);      -- Шифрование Cash_name
    END IF;
END;
/

CREATE OR REPLACE VIEW uncrypt_cash_accounts AS
SELECT 
    DecryptCashId(Cash_id) AS Cash_id,    -- Дешифровка Cash_id
    Cash_owner,
    NVL(TO_NUMBER(REGEXP_REPLACE(DecryptData(balance), '[^0-9.,]', '')), 0) AS balance,  -- Дешифруем balance, заменяем запятую на точку и преобразуем в NUMBER, NULL становится 0
    DecryptData(Cash_name) AS Cash_name,  -- Дешифруем Cash_name
    IsBlocked,
    Creation_date, 
    Currency_id 
FROM 
    Cash_accounts;

    
    
    
    
    
--===============    history             ================


CREATE OR REPLACE TRIGGER trg_encrypt_history
BEFORE INSERT OR UPDATE ON History
FOR EACH ROW
BEGIN
    :NEW.cash_from := EncryptData(:NEW.cash_from);  -- Шифрование cash_from
    :NEW.cash_to := EncryptData(:NEW.cash_to);      -- Шифрование cash_to
    :NEW.operation := EncryptData(:NEW.operation);    -- Шифрование operation
    :NEW.amount := EncryptData(TO_CHAR(:NEW.amount)); -- Шифрование amount, преобразуем в строку
    :NEW.operation_description := EncryptData(:NEW.operation_description); -- Шифрование operation_description
END;
/
CREATE OR REPLACE TRIGGER trg_encrypt_history
BEFORE INSERT OR UPDATE ON History
FOR EACH ROW
BEGIN
    IF :OLD.cash_from IS NULL OR :OLD.cash_from != :NEW.cash_from THEN
        :NEW.cash_from := EncryptData(:NEW.cash_from);  -- Шифрование cash_from
    END IF;

    IF :OLD.cash_to IS NULL OR :OLD.cash_to != :NEW.cash_to THEN
        :NEW.cash_to := EncryptData(:NEW.cash_to);      -- Шифрование cash_to
    END IF;

    IF :OLD.operation IS NULL OR :OLD.operation != :NEW.operation THEN
        :NEW.operation := EncryptData(:NEW.operation);    -- Шифрование operation
    END IF;

    IF :OLD.amount IS NULL OR TO_CHAR(:OLD.amount) != TO_CHAR(:NEW.amount) THEN
        :NEW.amount := EncryptData(TO_CHAR(:NEW.amount)); -- Шифрование amount, преобразуем в строку
    END IF;

    IF :OLD.operation_description IS NULL OR :OLD.operation_description != :NEW.operation_description THEN
        :NEW.operation_description := EncryptData(:NEW.operation_description); -- Шифрование operation_description
    END IF;
END;
/



CREATE OR REPLACE VIEW uncrypt_History AS
SELECT 
    Operation_id,
    Transactor,
    DecryptData(cash_from) AS cash_from,                   -- Дешифровка cash_from
    DecryptData(cash_to) AS cash_to,                       -- Дешифровка cash_to
    DecryptData(operation) AS operation,                   -- Дешифровка operation
    DecryptData(amount) AS amount,              -- Дешифровка amount, преобразуем обратно в число
    DecryptData(operation_description) AS operation_description -- Дешифровка operation_description
FROM 
    History;
/
--===================               queue                     ====================






CREATE OR REPLACE TRIGGER trg_encrypt_Queue
BEFORE INSERT OR UPDATE ON Queue
FOR EACH ROW
BEGIN
    IF :OLD.cash_from IS NULL OR :OLD.cash_from != :NEW.cash_from THEN
        :NEW.cash_from := EncryptData(:NEW.cash_from);  -- Шифрование cash_from
    END IF;

    IF :OLD.cash_to IS NULL OR :OLD.cash_to != :NEW.cash_to THEN
        :NEW.cash_to := EncryptData(:NEW.cash_to);      -- Шифрование cash_to
    END IF;

    IF :OLD.operation IS NULL OR :OLD.operation != :NEW.operation THEN
        :NEW.operation := EncryptData(:NEW.operation);    -- Шифрование operation
    END IF;

    IF :OLD.amount IS NULL OR TO_CHAR(:OLD.amount) != TO_CHAR(:NEW.amount) THEN
        :NEW.amount := EncryptData(TO_CHAR(:NEW.amount)); -- Шифрование amount, преобразуем в строку
    END IF;

    IF :OLD.operation_description IS NULL OR :OLD.operation_description != :NEW.operation_description THEN
        :NEW.operation_description := EncryptData(:NEW.operation_description); -- Шифрование operation_description
    END IF;
END;
/


CREATE OR REPLACE VIEW uncrypt_Queue AS
SELECT 
    Operation_id,
    Transactor,
    DecryptData(cash_from) AS cash_from,                   -- Дешифровка cash_from
    DecryptData(cash_to) AS cash_to,                       -- Дешифровка cash_to
    DecryptData(operation) AS operation,                   -- Дешифровка operation
        NVL(TO_NUMBER(REGEXP_REPLACE(DecryptData(amount), '[^0-9.,]', '')), 0) AS amount,   -- Дешифровка amount, преобразуем обратно в число
    DecryptData(operation_description) AS operation_description -- Дешифровка operation_description
FROM 
    Queue;
/
