CREATE OR REPLACE FUNCTION Is_Valid_Phone (
    p_phone_number IN VARCHAR2
) RETURN VARCHAR2 AS
BEGIN
    IF LENGTH(p_phone_number) != 12 THEN
        RETURN 'Номер недействителен: неверная длина. Длина должна быть равной 12';
    END IF;

    IF SUBSTR(p_phone_number, 1, 3) != '375' THEN
        RETURN 'Номер недействителен: должен начинаться с "375".';
    END IF;

    IF NOT REGEXP_LIKE(p_phone_number, '^375\d{9}$') THEN
        RETURN 'Номер недействителен: должен содержать 9 цифр после "375".';
    END IF;

    RETURN NULL;
EXCEPTION
WHEN VALUE_ERROR THEN
        RETURN 'Недостаточно места для хранения значения. Проверьте длину входных параметров. phone';
    WHEN OTHERS THEN
        RETURN 'Ошибка проверки номера: ' || SQLERRM;
END;
/



CREATE OR REPLACE FUNCTION User_valid (
    p_login IN VARCHAR2,
    p_pass IN VARCHAR2,
    p_name IN VARCHAR2,
    p_last_name IN VARCHAR2,
    p_number IN VARCHAR2,
    p_pasport IN VARCHAR2,
    p_role IN INT
) RETURN VARCHAR2 AS
    v_count NUMBER;
    v_number_valid varchar2(255);
BEGIN
    
    
    v_number_valid := Is_Valid_Phone(p_number);
    IF v_number_valid is not null then
        return v_number_valid;
    end if;
    -- Проверка уникальности логина
    
    SELECT COUNT(*)
    INTO v_count
    FROM Users
    WHERE login = EncryptData(p_login);

    IF v_count > 0 THEN
        RETURN 'Ошибка: Логин уже существует.';
    END IF;
    IF LENGTH(p_pasport) != 7 THEN
        RETURN 'Номер паспорта недействителен: длина доллжна быть равна 7.';
    END IF;
    SELECT COUNT(*)
    INTO v_count
    FROM Users
    WHERE pasport = EncryptData(p_pasport);
    
    IF v_count > 0 THEN
        RETURN 'Ошибка: Данный паспорт уже используется.';
    END IF;
    
    SELECT COUNT(*)
    INTO v_count
    FROM Users
    WHERE phone_number = EncryptData(p_number);
    
    IF v_count > 0 THEN
        RETURN 'Ошибка: Данный номер уже используется.';
    END IF;
    return null;
EXCEPTION
    WHEN VALUE_ERROR THEN
        RETURN 'Недостаточно места для хранения значения. Проверьте длину входных параметров. valid';
    WHEN OTHERS THEN
        RETURN 'Ошибка: ' || SQLERRM;
END;
/


CREATE OR REPLACE FUNCTION Register_User (
    p_login IN VARCHAR2,
    p_pass IN VARCHAR2,
    p_name IN VARCHAR2,
    p_last_name IN VARCHAR2,
    p_number IN VARCHAR2,
    p_pasport IN VARCHAR2,
    p_role IN INT
) RETURN VARCHAR2 AS
    v_valid varchar2(255);
    v_hashed_pass VARCHAR2(255);
BEGIN
    IF p_login IS NULL OR p_pass IS NULL OR p_name IS NULL OR p_last_name IS NULL OR p_number IS NULL OR p_role IS NULL OR p_pasport IS NULL THEN
        RETURN 'Ошибка: Параметры не могут быть NULL.';
    END IF;

    -- Хеширование пароля
    v_hashed_pass := RAWTOHEX(DBMS_CRYPTO.HASH(UTL_I18N.STRING_TO_RAW(p_pass, 'AL32UTF8'), DBMS_CRYPTO.HASH_MD5));
    v_valid := User_valid(p_login, v_hashed_pass, p_name, p_last_name, p_number, p_pasport, p_role);
    IF v_valid IS NOT NULL THEN
        RETURN v_valid;
    END IF;

    INSERT INTO Users (User_role, login, pass, user_name, last_name, phone_number, pasport)
    VALUES (p_role, p_login, v_hashed_pass, p_name, p_last_name, p_number, p_pasport);

    COMMIT;
    RETURN 'Регистрация успешна.';
EXCEPTION
    WHEN VALUE_ERROR THEN
        RETURN 'Недостаточно места для хранения значения. Проверьте длину входных параметров.';
    WHEN OTHERS THEN
        RETURN 'Ошибка: ' || SQLERRM;
END;
/



CREATE OR REPLACE FUNCTION Authorize_User (
    p_login IN VARCHAR2,
    p_password IN VARCHAR2
) RETURN VARCHAR2 AS
    v_user_id NUMBER;
    v_hashed_pass VARCHAR2(255);
BEGIN
    v_hashed_pass := RAWTOHEX(DBMS_CRYPTO.HASH(UTL_I18N.STRING_TO_RAW(p_password, 'AL32UTF8'), DBMS_CRYPTO.HASH_MD5));
    DBMS_OUTPUT.PUT_LINE(EncryptData(p_login));
    DBMS_OUTPUT.PUT_LINE(EncryptData(v_hashed_pass));

    SELECT User_id INTO v_user_id
    FROM Users
    WHERE login = EncryptData(p_login) AND pass = v_hashed_pass;

    RETURN TO_CHAR(v_user_id); 
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Ошибка: Неверный логин или пароль.'; -- Сообщение об ошибке, если пользователь не найден
    WHEN OTHERS THEN
        RETURN 'Ошибка: ' || SQLERRM; -- Возвращаем сообщение об ошибке
END;
/

