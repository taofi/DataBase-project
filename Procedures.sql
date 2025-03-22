    

-- =========================                  history                  ==============
CREATE OR REPLACE PROCEDURE AddToHistory (
    p_transactor IN NUMBER,             -- ID транзактора (пользователя, который выполняет операцию)
    p_cash_from IN NUMBER DEFAULT NULL, -- ID счета, с которого производится операция 
    p_cash_to IN NUMBER DEFAULT NULL,   -- ID счета, на который производится операция 
    p_operation IN VARCHAR2,            -- Тип операции
    p_amount IN NUMBER DEFAULT NULL,     -- Сумма операции 
    p_operation_description IN VARCHAR2 DEFAULT NULL  -- Описание операции 
) AS
BEGIN
    
    INSERT INTO History (Transactor, cash_from, cash_to, operation, amount, operation_description)
    VALUES (p_transactor, p_cash_from, p_cash_to, p_operation, p_amount, p_operation_description);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20004, 'Произошла ошибка: ' || SQLERRM);
END;
/





-- =====================               ROLE                   =========================


-- Создание процедуры добавления роли с проверкой уровня роли вызывающего пользователя

CREATE OR REPLACE FUNCTION AddRole (
    p_user_id IN NUMBER,
    p_name IN VARCHAR2,
    p_role_level IN NUMBER
) RETURN VARCHAR2 AS
    v_user_role_level NUMBER;
BEGIN
    IF p_user_id IS NULL OR p_name IS NULL OR p_role_level IS NULL THEN
        RETURN 'Ошибка: Параметры не могут быть NULL.';
    END IF;

    -- Получение уровня роли вызывающего пользователя
    SELECT r.role_level
    INTO v_user_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

   

    -- Проверка уровня роли
    IF v_user_role_level >= 1 THEN
        RETURN 'Ошибка: Недостаточно прав для выполнения операции.';
    END IF;

    -- Добавление новой роли
    INSERT INTO Role (name, role_level)
    VALUES (p_name, p_role_level);

    -- Добавление записи в историю
    AddToHistory(
        p_transactor => p_user_id,              
        p_cash_from => NULL,            
        p_cash_to => NULL,               
        p_operation => 'AddRole', 
        p_amount => NULL,              
        p_operation_description => 'Роль добавлена ' || p_name || ' уровень ' || p_role_level
    );

    COMMIT;
    RETURN 'роль добавлена';

EXCEPTION
    WHEN OTHERS THEN
        -- Обработка других ошибок
        RETURN 'Произошла ошибка: ' || SQLERRM;
END;
/

CREATE OR REPLACE FUNCTION SetRole (
    p_user_id IN NUMBER,
    p_target_user_id IN NUMBER,
    p_role_id IN NUMBER
) RETURN VARCHAR2 AS
    v_user_role_level NUMBER;
    v_role_exists NUMBER;
BEGIN
    -- Проверка входных параметров на NULL
    IF p_user_id IS NULL OR p_target_user_id IS NULL OR p_role_id IS NULL THEN
        RETURN 'Ошибка: Все параметры должны быть заданы.';
    END IF;

    -- Получение уровня роли вызывающего пользователя
    SELECT r.role_level
    INTO v_user_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    -- Проверка уровня роли
    IF v_user_role_level < 1 THEN
        RETURN 'Ошибка: Недостаточно прав для изменения роли.';
    END IF;

    -- Проверка существования указанной роли
    SELECT COUNT(*)
    INTO v_role_exists
    FROM Role
    WHERE Role_id = p_role_id;

    IF v_role_exists = 0 THEN
        RETURN 'Ошибка: Указанная роль не существует.';
    END IF;

    -- Установка новой роли для целевого пользователя
    UPDATE Users
    SET User_role = p_role_id
    WHERE User_id = p_target_user_id;

    -- Проверка, была ли обновлена запись
    IF SQL%ROWCOUNT = 0 THEN
        RETURN 'Ошибка: Целевой пользователь не найден.';
    END IF;

    -- Успешный результат
    COMMIT;
    RETURN 'Роль успешно обновлена для пользователя с ID ' || p_target_user_id;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Произошла ошибка: ' || SQLERRM;
END;
/

-- Процедура удаления роли
CREATE OR REPLACE FUNCTION DeleteRole (
    p_user_id IN NUMBER,
    p_role_id IN NUMBER
) RETURN VARCHAR2 AS
    v_user_role_level NUMBER;
    v_role_usage_count NUMBER;
    v_role_name VARCHAR2(100);
BEGIN
    IF p_user_id IS NULL OR p_role_id IS NULL THEN
        RETURN 'Ошибка: Параметры не могут быть NULL.';
    END IF;
    -- Получение уровня роли вызывающего пользователя
    SELECT r.role_level
    INTO v_user_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    -- Проверка уровня роли
    IF v_user_role_level >= 1 THEN
        RETURN 'Ошибка: Недостаточно прав для удаления роли.';
    END IF;

    -- Проверка использования роли
    SELECT COUNT(*)
    INTO v_role_usage_count
    FROM Users
    WHERE User_role = p_role_id;

    IF v_role_usage_count > 0 THEN
        RETURN 'Ошибка: Роль не может быть удалена, так как она используется пользователями.';
    END IF;
    
    -- Получение имени роли
    SELECT r.name
    INTO v_role_name
    FROM Role r
    WHERE r.Role_id = p_role_id;

    -- Удаление роли
    DELETE FROM Role
    WHERE Role_id = p_role_id;

    IF SQL%ROWCOUNT = 0 THEN
        RETURN 'Ошибка: Роль с указанным ID не найдена.';
    END IF;

    -- Добавление записи в историю
    AddToHistory(
        p_transactor => p_user_id,              
        p_cash_from => NULL,            
        p_cash_to => NULL,               
        p_operation => 'DeleteRole', 
        p_amount => NULL,              
        p_operation_description => 'Роль удалена id:' || p_role_id || ' имя ' || v_role_name
    );

    COMMIT;
    RETURN 'Роль успешно удалена.';

EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Произошла ошибка: ' || SQLERRM;
END;
/

CREATE OR REPLACE FUNCTION GetUserRoleLevel(
    p_user_id IN NUMBER -- ID пользователя
) RETURN VARCHAR2 IS
    v_user_role_level NUMBER;       
    v_result VARCHAR2(4000);        
BEGIN
    SELECT r.role_level
    INTO v_user_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    v_result := v_user_role_level;
    RETURN v_result;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Если пользователь не найден
        RETURN 'Ошибка: Пользователь с указанным ID не найден.';
    WHEN OTHERS THEN
        -- Ловим все остальные ошибки
        RETURN 'Ошибка: ' || SQLERRM;
END GetUserRoleLevel;
/


-- Процедура изменения ролиъ
CREATE OR REPLACE FUNCTION UpdateRole (
    p_user_id IN NUMBER,
    p_role_id IN NUMBER,
    p_new_name IN VARCHAR2,
    p_new_role_level IN NUMBER
) RETURN VARCHAR2 AS
    v_user_role_level NUMBER;
    v_current_name VARCHAR2(255);
    v_current_role_level NUMBER;
BEGIN
    -- Проверка входных параметров на NULL
    IF p_user_id IS NULL OR p_role_id IS NULL THEN
        RETURN 'Ошибка: p_role_id и p_user_id должны быть заданы.';
    END IF;

    -- Получение уровня роли вызывающего пользователя
    SELECT r.role_level
    INTO v_user_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    -- Проверка уровня роли
    IF v_user_role_level >= 1 THEN
        RETURN 'Ошибка: Недостаточно прав для изменения роли.';
    END IF;

    -- Получение текущего значения имени и уровня роли
    SELECT name, role_level
    INTO v_current_name, v_current_role_level
    FROM Role
    WHERE Role_id = p_role_id;

    -- Обновление роли
    UPDATE Role
    SET name = COALESCE(p_new_name, v_current_name),
        role_level = CASE 
            WHEN p_new_role_level IS NOT NULL THEN p_new_role_level 
            ELSE v_current_role_level 
        END
    WHERE Role_id = p_role_id;

    IF SQL%ROWCOUNT = 0 THEN
        RETURN 'Ошибка: Роль с указанным ID не найдена.';
    END IF;

    -- Добавление записи в историю
    AddToHistory(
        p_transactor => p_user_id,
        p_cash_from => NULL,
        p_cash_to => NULL,
        p_operation => 'UpdateRole',
        p_amount => NULL,
        p_operation_description => 'Роль изменена id: ' || p_role_id || 
                                    ', имя: ' || COALESCE(p_new_name, v_current_name) || 
                                    ', уровень: ' || COALESCE(p_new_role_level, v_current_role_level)
    );

    COMMIT;
    RETURN 'Роль успешно обновлена.';
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Произошла ошибка: ' || SQLERRM;
END;
/




--===================                   USER                    ==================




-- Процедура изменения пользователя
CREATE OR REPLACE FUNCTION UpdateUser (
    p_executor_id IN NUMBER,  -- ID пользователя, выполняющего операцию
    p_target_id IN NUMBER,     -- ID пользователя, над которым происходит операция
    p_new_login IN VARCHAR2,
    p_new_pass IN VARCHAR2,
    p_new_user_name IN VARCHAR2,
    p_new_last_name IN VARCHAR2,
    p_new_phone_number IN VARCHAR2,
    p_new_pasport IN VARCHAR2
) RETURN VARCHAR2 AS
    v_executor_role_level NUMBER;
    v_hashed_pass VARCHAR2(255);
    v_target_role_level NUMBER;
    v_count NUMBER;
    v_valid VARCHAR2(100);
BEGIN
    
    -- Проверка на NULL
    IF p_executor_id IS NULL OR p_target_id IS NULL THEN
        RETURN 'Ошибка: Параметры не могут быть NULL.';
    END IF;

    v_valid := User_valid(p_new_login, p_new_pass, p_new_user_name, p_new_last_name, p_new_phone_number, p_new_pasport, 2);
    IF v_valid is not null then
        return v_valid;
    end if;


    -- Получение уровня роли пользователя, выполняющего операцию
    SELECT r.role_level
    INTO v_executor_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_executor_id;

    -- Получение уровня роли целевого пользователя
    SELECT r.role_level
    INTO v_target_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_target_id;

    -- Проверка прав доступа
    IF NOT (p_executor_id = p_target_id OR v_executor_role_level < v_target_role_level) THEN
        RETURN 'Недостаточно прав для изменения этого пользователя.';
    END IF;
    
    if p_new_pass is not null then
    v_hashed_pass := RAWTOHEX(DBMS_CRYPTO.HASH(UTL_I18N.STRING_TO_RAW(p_new_pass, 'AL32UTF8'), DBMS_CRYPTO.HASH_MD5));
    end if;
    -- Обновление пользователя с использованием текущих значений при NULL
    UPDATE Users
    SET login = COALESCE(p_new_login, login),
        pass = COALESCE(v_hashed_pass, pass),
        user_name = COALESCE(p_new_user_name, user_name),
        last_name = COALESCE(p_new_last_name, last_name),
        phone_number = COALESCE(p_new_phone_number, phone_number),
        pasport = COALESCE(p_new_pasport, pasport)
    WHERE User_id = p_target_id;

    IF SQL%ROWCOUNT = 0 THEN
        RETURN 'Ошибка: Пользователь с указанным ID не найден.';
    END IF;

    -- Добавление записи в историю
    AddToHistory(
        p_transactor => p_executor_id,              
        p_cash_from => NULL,            
        p_cash_to => NULL,               
        p_operation => 'UpdateUser', 
        p_amount => NULL,              
        p_operation_description => 'Пользователь изменен id:' || p_target_id || ' ' || COALESCE(p_new_login, '(без изменений)') || ' ' || COALESCE(p_new_user_name, '(без изменений)')
    );

    COMMIT;

    RETURN 'Пользователь успешно обновлен.';
EXCEPTION
    WHEN VALUE_ERROR THEN
        RETURN 'Недостаточно места для хранения значения. Проверьте длину входных параметров.';
    WHEN OTHERS THEN
        RETURN 'Произошла ошибка: ' || SQLERRM;
END;
/




-- Процедура удаления пользователя
CREATE OR REPLACE FUNCTION DeleteUser (
    p_executor_id IN NUMBER,  -- ID пользователя, выполняющего операцию
    p_target_id IN NUMBER     -- ID пользователя, которого нужно удалить
) RETURN VARCHAR2 AS
    v_executor_role_level NUMBER;
    v_target_role_level NUMBER;
    v_user_login VARCHAR2(100);
BEGIN
    -- Проверка на NULL значения параметров
    IF p_executor_id IS NULL OR p_target_id IS NULL THEN
        RETURN 'Ошибка: Параметры не могут быть NULL.';
    END IF;

    -- Получение уровня роли пользователя, выполняющего операцию
    SELECT r.role_level
    INTO v_executor_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_executor_id;

    -- Получение уровня роли целевого пользователя
    SELECT r.role_level
    INTO v_target_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_target_id;

    -- Проверка условий выполнения операции
    IF p_executor_id = p_target_id OR v_executor_role_level < v_target_role_level THEN
        -- Получение логина пользователя
        SELECT r.login
        INTO v_user_login
        FROM Users r
        WHERE r.User_id = p_target_id;

        -- Удаление пользователя
        DELETE FROM Users
        WHERE User_id = p_target_id;

        IF SQL%ROWCOUNT = 0 THEN
            RETURN 'Ошибка: Пользователь с указанным ID не найден.';
        END IF;

        -- Логирование операции
        AddToHistory(
            p_transactor => p_executor_id,              
            p_cash_from => NULL,            
            p_cash_to => NULL,               
            p_operation => 'DeleteUser', 
            p_amount => NULL,              
            p_operation_description => 'Пользователь удален id:' || p_target_id || ' login: ' || DecryptData(v_user_login)
        );
        COMMIT;
        RETURN 'Пользователь успешно удален.';
    ELSE
        RETURN 'Ошибка: Недостаточно прав для удаления этого пользователя.';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Ошибка: ' || SQLERRM;
END;
/



--======================               cash                          ==========================
--drop SEQUENCE Cash_id_seq;
--commit;
CREATE SEQUENCE Cash_id_seq
START WITH 1000000000000000 -- Начальное значение
INCREMENT BY 1              -- Шаг увеличения
NOCACHE                     -- Без кеширования
NOCYCLE;                    -- Не зацикливать


CREATE OR REPLACE FUNCTION UpdateInfoCashAccount (
    p_user_id IN NUMBER,           -- Идентификатор пользователя
    p_cash_id IN VARCHAR2,         -- Идентификатор счета
    p_new_cash_name IN VARCHAR2,   -- Новое имя счета (может быть NULL)
    p_new_currency_id IN VARCHAR2   -- Новая валюта (может быть NULL)
) RETURN VARCHAR2 AS
    v_current_balance VARCHAR2(100); -- Текущий баланс в виде строки
    v_old_currency_id VARCHAR2(4);   -- Текущая валюта
    v_old_exchange_rate NUMBER;       -- Курс старой валюты
    v_new_exchange_rate NUMBER;       -- Курс новой валюты
    v_role_level NUMBER;              -- Уровень роли пользователя
    v_new_balance NUMBER;             -- Новое значение баланса
    v_cash_owner NUMBER;              -- Владелец счета
BEGIN
    -- Проверка на NULL параметры
    IF p_user_id IS NULL THEN
        RETURN 'Ошибка: p_user_id не может быть NULL.';
    END IF;

    IF p_cash_id IS NULL THEN
        RETURN 'Ошибка: p_cash_id не может быть NULL.';
    END IF;

    -- Получение текущей информации о счете
    SELECT Cash_owner, balance, Currency_id
    INTO v_cash_owner, v_current_balance, v_old_currency_id
    FROM Cash_accounts
    WHERE Cash_id = EncryptData(p_cash_id);

    -- Проверка прав доступа
    SELECT r.role_level
    INTO v_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    -- Проверка прав доступа
    IF v_role_level > 1 AND p_user_id != v_cash_owner THEN
        RETURN 'Ошибка: Недостаточно прав.';
    END IF;

    -- Обновление имени счета
    IF p_new_cash_name IS NOT NULL THEN
        UPDATE Cash_accounts
        SET Cash_name = p_new_cash_name
        WHERE Cash_id = EncryptData(p_cash_id);
    END IF;

    -- Обновление валюты
    IF p_new_currency_id IS NOT NULL THEN
        -- Получение курсов валют
        SELECT Exchange_rate
        INTO v_old_exchange_rate
        FROM Currencies
        WHERE Currency_id = v_old_currency_id;

        SELECT Exchange_rate
        INTO v_new_exchange_rate
        FROM Currencies
        WHERE Currency_id = p_new_currency_id;

        -- Вычисление нового баланса
        v_new_balance := ROUND((NVL(TO_NUMBER(REGEXP_REPLACE(DecryptData(v_current_balance), '[^0-9.,]', '')), 0) / v_old_exchange_rate) * v_new_exchange_rate, 2);

        -- Обновление баланса и валюты
        UPDATE Cash_accounts
        SET balance = TO_CHAR(v_new_balance),
            Currency_id = p_new_currency_id
        WHERE Cash_id = EncryptData(p_cash_id);
    END IF;

    COMMIT;
    AddToHistory(
        p_transactor => p_user_id,              
        p_cash_from => NULL,            
        p_cash_to => NULL,               
        p_operation => 'UpdateInfoCashAccount', 
        p_amount => NULL,              
        p_operation_description => 'Счет изменен id: ' || p_cash_id || 
                                    ' name: ' || NVL(p_new_cash_name, 'не изменено') || 
                                    ' currency: ' || NVL(p_new_currency_id, v_old_currency_id)
    );
    RETURN 'Счет успешно обновлен.';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Ошибка: Указанный счет или валюта не найдены.';
    WHEN OTHERS THEN
        RETURN GetCustomErrorMessage(SQLERRM);
END;
/


CREATE OR REPLACE FUNCTION CreateCashAccount (
    p_executor_id IN NUMBER,  
    p_cash_owner IN NUMBER,          
    p_cash_name IN VARCHAR2,
    p_currency_id IN VARCHAR2
) RETURN VARCHAR2 AS
    v_executor_role_level NUMBER;
    v_new_cash_id NUMBER;
    v_count NUMBER;
    v_currency_count NUMBER;
BEGIN
    -- Проверка на NULL значения
    IF p_executor_id IS NULL THEN
        RETURN 'Ошибка: p_executor_id не может быть NULL.';
    END IF;

    IF p_cash_owner IS NULL THEN
        RETURN 'Ошибка: p_cash_owner не может быть NULL.';
    END IF;

    IF p_cash_name IS NULL OR TRIM(p_cash_name) IS NULL THEN
        RETURN 'Ошибка: p_cash_name не может быть NULL или пустым.';
    END IF;

    IF p_currency_id IS NULL THEN
        RETURN 'Ошибка: p_currency_id не может быть NULL.';
    END IF;

    -- Проверка длины параметров
    IF LENGTH(p_cash_name) > 100 THEN
        RETURN 'Ошибка: p_cash_name не может превышать 100 символов.';
    END IF;

    IF LENGTH(p_currency_id) > 4 THEN
        RETURN 'Ошибка: p_currency_id не может превышать 4 символа.';
    END IF;

    -- Получение уровня роли исполнителя
    SELECT r.role_level
    INTO v_executor_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_executor_id;

    -- Проверка прав доступа
    IF NOT (p_executor_id = p_cash_owner OR v_executor_role_level < 1) THEN
        RETURN 'Недостаточно прав.';
    END IF;

    -- Проверка, что владелец счета существует
    SELECT COUNT(*)
    INTO v_count
    FROM Users
    WHERE User_id = p_cash_owner;

    IF v_count = 0 THEN
        RETURN 'Пользователь с ID ' || p_cash_owner || ' не найден.';
    END IF;

    -- Проверка, что валюта существует
    SELECT COUNT(*)
    INTO v_currency_count
    FROM Currencies
    WHERE Currency_id = p_currency_id;

    IF v_currency_count = 0 THEN
        RETURN 'Ошибка: Валюта с ID ' || p_currency_id || ' не найдена.';
    END IF;

    -- Генерация нового уникального Cash_id
    SELECT Cash_id_seq.NEXTVAL INTO v_new_cash_id FROM DUAL;

    -- Вставка новой записи в таблицу Cash_accounts
    INSERT INTO Cash_accounts (Cash_id, Cash_owner, balance, Cash_name, Currency_id)
    VALUES (v_new_cash_id, p_cash_owner, 0, p_cash_name, p_currency_id);

    -- Добавление записи в историю
    AddToHistory(
        p_transactor => p_cash_owner,              
        p_cash_from => NULL,            
        p_cash_to => NULL,               
        p_operation => 'CreateCashAccount', 
        p_amount => NULL,              
        p_operation_description => 'Счет создан id: ' || v_new_cash_id || 
                                    ' name: ' || p_cash_name || 
                                    ' currency: ' || p_currency_id
    );

    COMMIT;

    RETURN 'Счет успешно создан.';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Ошибка: Указанный пользователь или валюта не найдены.';
    WHEN OTHERS THEN
        RETURN 'Произошла ошибка при добавлении счета: ' || SQLERRM;
END;
/

CREATE OR REPLACE PROCEDURE SetBalance (
    p_cash_id IN NUMBER,      
    p_new_balance IN NUMBER
) AS
BEGIN
    
    -- Обновление баланса счета
    UPDATE Cash_accounts
    SET balance = p_new_balance
    WHERE Cash_id = EncryptData(TO_CHAR(p_cash_id));
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, SQLERRM);
END;
/


CREATE OR REPLACE FUNCTION UpdateAccountBalance( 
    p_user_id IN NUMBER,      
    p_cash_id IN NUMBER,      
    p_amount IN NUMBER
) RETURN VARCHAR2 AS
    v_role_level NUMBER;     
    v_current_balance NUMBER; 
    v_new_balance NUMBER;   
BEGIN
    -- Проверка существования пользователя и уровня его роли
    SELECT r.role_level
    INTO v_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    IF v_role_level > 1 THEN
        RETURN 'Ошибка: У вас недостаточно прав для выполнения этой операции.';
    END IF;

    -- Проверка существования счета и получения текущего баланса
    SELECT balance
    INTO v_current_balance
    FROM uncrypt_cash_accounts
    WHERE Cash_id = p_cash_id;

    -- Вычисление нового баланса
    v_new_balance := v_current_balance + p_amount;

    -- Проверка на отрицательный баланс
    IF v_new_balance < 0 THEN
        RETURN 'Ошибка: Баланс счета не может быть отрицательным. Текущий баланс: ' || v_current_balance;
    END IF;


    -- Обновление баланса счета
    SetBalance(p_cash_id, v_new_balance);

    AddToHistory(
        p_transactor => p_user_id,              
        p_cash_from => p_cash_id,            
        p_cash_to => NULL,               
        p_operation => 'UpdateAccountBalance', 
        p_amount => p_amount,              
        p_operation_description => 'Изменение баланса счета ID ' || p_cash_id || ' на сумму ' || p_amount || ' успешно обновлен. Новый баланс: ' || v_new_balance
    );

    -- Успешный результат
    RETURN 'Баланс счета ID ' || p_cash_id || ' успешно обновлен. Новый баланс: ' || v_new_balance;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Ошибка: Счет или пользователь не найдены.';
    WHEN OTHERS THEN
        RETURN GetCustomErrorMessage(SQLERRM);
END;
/



   
   
CREATE OR REPLACE PROCEDURE UpdateAccountBalanceNoLog (
    p_cash_id IN NUMBER,      
    p_amount IN NUMBER
) AS
    v_current_balance NUMBER; 
    v_new_balance NUMBER;   
BEGIN
    
    SELECT balance
    INTO v_current_balance
    FROM uncrypt_cash_accounts
    WHERE Cash_id = p_cash_id;

    -- Вычисление нового баланса
    v_new_balance := v_current_balance + p_amount;

    -- Обновление баланса счета
    SetBalance(p_cash_id, v_new_balance);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001, SQLERRM);
END;
/

CREATE OR REPLACE FUNCTION TransferFunds (
    p_user_id IN NUMBER,           
    p_sender_cash_id IN NUMBER,   
    p_receiver_cash_id IN NUMBER,  
    p_amount IN NUMBER               
) RETURN VARCHAR2 AS
    v_sender_balance NUMBER;       
    v_sender_currency_id VARCHAR2(4);
    v_receiver_currency_id VARCHAR2(4);
    v_sender_exchange_rate NUMBER;
    v_receiver_exchange_rate NUMBER;
    v_converted_amount NUMBER;      -- Переведенная сумма в валюте получателя
    v_is_blocked NUMBER;            -- Переменная для проверки состояния целевого счета
BEGIN
    -- Проверка на NULL параметры
    IF p_user_id IS NULL THEN
        RETURN 'Ошибка: p_user_id не может быть NULL.';
    END IF;
    IF p_sender_cash_id IS NULL THEN
        RETURN 'Ошибка: p_sender_cash_id не может быть NULL.';
    END IF;
    IF p_receiver_cash_id IS NULL THEN
        RETURN 'Ошибка: p_receiver_cash_id не может быть NULL.';
    END IF;
    IF p_amount IS NULL THEN
        RETURN 'Ошибка: p_amount не может быть NULL.';
    END IF;

    -- Проверка суммы перевода
    IF p_amount <= 0 THEN
        RETURN 'Ошибка: Сумма перевода должна быть положительной.';
    END IF;

    -- Получение валюты отправителя и его баланса
    SELECT balance, Currency_id
    INTO v_sender_balance, v_sender_currency_id
    FROM uncrypt_cash_accounts
    WHERE Cash_id = p_sender_cash_id;

    -- Проверка баланса отправителя
    IF v_sender_balance < p_amount THEN
        RETURN 'Ошибка: Недостаточно средств на счете отправителя. Текущий баланс: ' || v_sender_balance;
    END IF;

    -- Получение информации о целевом счете
    SELECT Currency_id, IsBlocked
    INTO v_receiver_currency_id, v_is_blocked
    FROM uncrypt_cash_accounts
    WHERE Cash_id = p_receiver_cash_id;

    -- Проверка, заблокирован ли целевой счет
    IF v_is_blocked = 1 THEN
        RETURN 'Ошибка: Целевой счет заблокирован.';
    END IF;

    -- Получение курсов валют
    SELECT Exchange_rate
    INTO v_sender_exchange_rate
    FROM Currencies
    WHERE Currency_id = v_sender_currency_id;

    SELECT Exchange_rate
    INTO v_receiver_exchange_rate
    FROM Currencies
    WHERE Currency_id = v_receiver_currency_id;

    -- Рассчет суммы для зачисления на счет получателя
    v_converted_amount := ROUND((p_amount / v_sender_exchange_rate) * v_receiver_exchange_rate, 2);

    -- Снятие средств с баланса отправителя
    UpdateAccountBalanceNoLog(p_sender_cash_id, -p_amount);

    -- Добавление средств на баланс получателя
    UpdateAccountBalanceNoLog(p_receiver_cash_id, v_converted_amount);

    -- Добавление операции в историю
    AddToHistory(
        p_transactor => p_user_id,              
        p_cash_from => p_sender_cash_id,            
        p_cash_to => p_receiver_cash_id,               
        p_operation => 'TransferFunds', 
        p_amount => v_converted_amount,              
        p_operation_description => 'Перевод ' || p_amount || 
                                    ' от счета ID ' || p_sender_cash_id || 
                                    ' к счету ID ' || p_receiver_cash_id
    );

    -- Успешный результат
    COMMIT;
    RETURN 'Перевод ' || p_amount || ' от счета ID ' || p_sender_cash_id || 
           ' к счету ID ' || p_receiver_cash_id || 
           ' выполнен успешно. Получено: ' || v_converted_amount || 
           ' в валюте получателя.';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Ошибка: Указанный счет не найден.';
    WHEN OTHERS THEN
        RETURN GetCustomErrorMessage(SQLERRM);
END;
/


CREATE OR REPLACE FUNCTION ProcessTransfer (
    p_user_id IN NUMBER,           -- ID пользователя, выполняющего операцию
    p_sender_cash_id IN NUMBER,    -- ID счета отправителя
    p_receiver_cash_id IN NUMBER,  -- ID счета получателя
    p_amount IN NUMBER              -- Сумма перевода
) RETURN VARCHAR2 AS
    v_role_level NUMBER;           
    v_sender_balance NUMBER;      
    v_receiver_exists NUMBER;
    v_owner_id NUMBER;
    v_result VARCHAR2(4000);       -- Переменная для сообщения о результате
BEGIN
    -- Проверка на NULL параметры
    IF p_user_id IS NULL THEN
        RETURN 'Ошибка: p_user_id не может быть NULL.';
    END IF;
    IF p_sender_cash_id IS NULL THEN
        RETURN 'Ошибка: p_sender_cash_id не может быть NULL.';
    END IF;
    IF p_receiver_cash_id IS NULL THEN
        RETURN 'Ошибка: p_receiver_cash_id не может быть NULL.';
    END IF;
    IF p_amount IS NULL THEN
        RETURN 'Ошибка: p_amount не может быть NULL.';
    END IF;

    -- Проверка уровня роли пользователя
    SELECT r.role_level
    INTO v_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    -- Проверка существования счета и получения текущего баланса отправителя
    SELECT balance
    INTO v_sender_balance
    FROM uncrypt_cash_accounts
    WHERE Cash_id = p_sender_cash_id;

    IF v_sender_balance < p_amount THEN
        RETURN 'Ошибка: Недостаточно средств на счете отправителя. Текущий баланс: ' || v_sender_balance;
    END IF;
    
    
    SELECT COUNT(*)
    INTO v_receiver_exists
    FROM uncrypt_cash_accounts
    WHERE Cash_id = p_receiver_cash_id;

    IF v_receiver_exists = 0 THEN
        RETURN 'Ошибка: Счет получателя с ID ' || p_receiver_cash_id || ' не найден.';
    END IF;

    
    SELECT CASH_OWNER
    INTO v_owner_id
    FROM uncrypt_cash_accounts
    WHERE Cash_id = p_sender_cash_id;
        
    IF v_role_level > 1 and not v_owner_id = p_user_id THEN
        RETURN 'Ошибка: недостаточность прав';
    END IF;
    
    IF v_role_level <= 1 OR p_amount <= v_sender_balance / 3 THEN
        v_result := TransferFunds(
            p_user_id => p_user_id,
            p_sender_cash_id => p_sender_cash_id,
            p_receiver_cash_id => p_receiver_cash_id,
            p_amount => p_amount
        );
        RETURN v_result;
    ELSE
        -- Занесение данных в таблицу Queue
        INSERT INTO Queue (
            Transactor, cash_from, cash_to, operation, amount, operation_description
        ) VALUES (
            p_user_id, p_sender_cash_id, p_receiver_cash_id, 
            'TransferFunds', p_amount,
            'Запрос на перевод ' || p_amount || ' от счета ID ' || p_sender_cash_id || 
            ' к счету ID ' || p_receiver_cash_id
        );
        COMMIT;
        RETURN 'Перевод добавлен в очередь на обработку.';
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Ошибка: Указанный пользователь или счет не найден.';
    WHEN OTHERS THEN
        RETURN 'Ошибка: ' || SQLERRM;
END;
/







--=================                 queue                   =============

CREATE OR REPLACE FUNCTION UpdateQueueRow (
    p_user_id IN NUMBER,             
    p_operation_id IN NUMBER,        
    p_new_cash_to IN VARCHAR2,       -- Изменен тип на VARCHAR2
    p_new_amount IN VARCHAR2          -- Изменен тип на VARCHAR2
) RETURN VARCHAR2 IS
    v_role_level NUMBER;  
    v_count NUMBER;
    old_cash_from VARCHAR2(100);       
    old_cash_to VARCHAR2(100);          
BEGIN
    IF p_user_id IS NULL THEN
        RETURN 'Ошибка: id пользователя должен быть указан.';
    END IF;
    IF p_operation_id IS NULL THEN
        RETURN 'Ошибка: id Операции должен быть указан.';
    END IF;
    
    -- Проверка уровня роли пользователя
    SELECT r.role_level
    INTO v_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    IF v_role_level > 1 THEN
        RETURN 'Ошибка: У пользователя недостаточно прав для выполнения операции.';
    END IF;

    SELECT COUNT(*)
    INTO v_count
    FROM uncrypt_Queue
    WHERE Operation_id = p_operation_id;
    
    SELECT cash_from
    INTO old_cash_from
    FROM uncrypt_Queue
    WHERE Operation_id = p_operation_id;

    SELECT cash_to
    INTO old_cash_to
    FROM uncrypt_Queue
    WHERE Operation_id = p_operation_id;

    
    IF v_count = 0 THEN
        RETURN 'Ошибка: Операция с ID ' || p_operation_id || ' не найдена.';
    END IF;

    -- Обновление строки
    UPDATE Queue
    SET 
        cash_to = NVL(p_new_cash_to, cash_to),
        amount = NVL(p_new_amount, amount),
        operation_description = 'Перевод ' || NVL(p_new_amount, amount) || ' от счета ID ' || old_cash_from || ' к счету ID ' || NVL(p_new_cash_to, old_cash_to)
    WHERE Operation_id = p_operation_id;

    -- Логирование изменения в истории
    AddToHistory(
        p_transactor => p_user_id,              
        p_cash_from => NULL,            
        p_cash_to => NULL,               
        p_operation => 'UpdateQueueRow', 
        p_amount => NULL,              
        p_operation_description => 'Изменение операции ID ' || p_operation_id
    );

    RETURN 'Успешно обновлена операция с ID ' || p_operation_id || '.';

EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Ошибка: ' || SQLERRM;
END;
/




CREATE OR REPLACE FUNCTION ExecuteQueueOperation (
    p_operator_id IN NUMBER,       -- ID пользователя, выполняющего операцию
    p_operation_id IN NUMBER        -- ID операции в таблице Queue
) RETURN VARCHAR2 IS

    v_role_level NUMBER;           -- Уровень роли оператора
    v_cash_from NUMBER;            -- Счет отправителя
    v_cash_to NUMBER;              -- Счет получателя
    v_amount NUMBER;               -- Сумма перевода
    v_operation VARCHAR2(50);      -- Операция
    v_description VARCHAR2(255);   -- Описание операции
    v_result VARCHAR2(255);        -- Результат выполнения

BEGIN
    -- Проверка уровня роли оператора
    SELECT r.role_level
    INTO v_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_operator_id;

    IF v_role_level > 1 THEN
        RETURN 'Ошибка: У вас недостаточно прав для выполнения операций из очереди.';
    END IF;

    -- Получение данных операции из таблицы Queue
    SELECT cash_from, cash_to, amount, operation, operation_description
    INTO v_cash_from, v_cash_to, v_amount, v_operation, v_description
    FROM uncrypt_Queue
    WHERE Operation_id = p_operation_id;

    -- Выполнение перевода
    v_result := ProcessTransfer(
        p_user_id => p_operator_id,       -- Пользователь, выполняющий операцию
        p_sender_cash_id => v_cash_from,  -- Счет отправителя
        p_receiver_cash_id => v_cash_to,   -- Счет получателя
        p_amount => v_amount                -- Сумма перевода
    );

    -- Удаление операции из таблицы Queue после успешного выполнения
    DELETE FROM Queue
    WHERE Operation_id = p_operation_id;

    -- Добавление записи в историю
    AddToHistory(
        p_transactor => p_operator_id,              
        p_cash_from => NULL,            
        p_cash_to => NULL,               
        p_operation => 'ExecuteQueueOperation', 
        p_amount => NULL,              
        p_operation_description => 'Подтверждение операции ID ' || p_operation_id
    );

    COMMIT;

    RETURN 'Операция выполнена: ' || v_result;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Ошибка: Операция с ID ' || p_operation_id || ' не найдена в очереди.';
    WHEN OTHERS THEN
        RETURN 'Ошибка выполнения операции: ' || SQLERRM;
END ExecuteQueueOperation;
/




CREATE OR REPLACE FUNCTION DeleteQueueRow(
    p_user_id IN NUMBER,      -- ID пользователя, выполняющего операцию
    p_operation_id IN NUMBER  -- ID операции, которую нужно удалить
) RETURN VARCHAR2 IS
    v_user_role_level NUMBER;  -- Уровень роли пользователя
    v_result VARCHAR2(1000);   -- Сообщение о результате
BEGIN
    -- Получаем уровень роли пользователя
    SELECT r.role_level
    INTO v_user_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    IF v_user_role_level > 1 THEN
        RETURN 'Ошибка: Недостаточно прав для выполнения операции.';
    END IF;

    -- Удаляем строку из таблицы Queue
    DELETE FROM Queue
    WHERE Operation_id = p_operation_id;

    -- Проверяем, было ли удаление успешным
    IF SQL%ROWCOUNT = 0 THEN
        v_result := 'Ошибка: Операция с ID ' || p_operation_id || ' не найдена.';
    ELSE
        v_result := 'Успешно: Операция с ID ' || p_operation_id || ' удалена.';
    END IF;

    RETURN v_result;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Ошибка: Пользователь с ID ' || p_user_id || ' не найден.';
    WHEN OTHERS THEN
        RETURN 'Ошибка: ' || SQLERRM;
END DeleteQueueRow;
/





-- ===========================                     удаление                     ==============

CREATE OR REPLACE PROCEDURE DeleteQueueByCashId(
    p_cash_id IN VARCHAR2  -- ID счета, операции с которым нужно удалить
) AS
BEGIN
    -- Удаляем строки, где cash_from или cash_to совпадает с p_cash_id
    DELETE FROM Queue
    WHERE cash_from = p_cash_id OR cash_to = p_cash_id;

    -- Проверяем, были ли удалены строки
    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Нет операций с указанным cash_id: ' || p_cash_id);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Удалено операций: ' || SQL%ROWCOUNT || ' для cash_id: ' || p_cash_id);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: ' || SQLERRM);
END DeleteQueueByCashId;
/


CREATE OR REPLACE PROCEDURE DeleteHistoryByCashId(
    p_cash_id IN VARCHAR2  -- ID счета, операции с которым нужно удалить
) AS
BEGIN
    -- Удаляем строки, где cash_from или cash_to совпадает с p_cash_id
    DELETE FROM History
    WHERE cash_from = p_cash_id OR cash_to = p_cash_id;

    -- Проверяем, были ли удалены строки
    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Нет операций с указанным cash_id: ' || p_cash_id);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Удалено операций: ' || SQL%ROWCOUNT || ' для cash_id: ' || p_cash_id);
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: ' || SQLERRM);
END DeleteHistoryByCashId;
/



CREATE OR REPLACE FUNCTION DeleteCashAccount(
    p_user_id IN NUMBER,   -- ID пользователя, выполняющего удаление
    p_cash_id IN VARCHAR2  -- ID счета, который нужно удалить
) RETURN VARCHAR2 AS
    v_user_role_level NUMBER; -- Уровень роли пользователя
    v_cash_owner NUMBER;      -- Владелец счета
BEGIN
    -- Получаем уровень роли пользователя
    SELECT r.role_level
    INTO v_user_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    -- Получаем владельца счета
    SELECT Cash_owner
    INTO v_cash_owner
    FROM Cash_accounts
    WHERE Cash_id = EncryptCashId(p_cash_id);

    -- Проверяем права на удаление
    IF v_user_role_level > 1 AND v_cash_owner != p_user_id THEN
        RETURN 'Ошибка: Недостаточно прав для удаления счета.';
    END IF;

    -- Удаляем запись из таблицы Cash_accounts
    DeleteQueueByCashId(EncryptCashId(p_cash_id));
    DeleteHistoryByCashId(EncryptCashId(p_cash_id));

    DELETE FROM Cash_accounts
    WHERE Cash_id = EncryptCashId(p_cash_id);

    -- Проверяем, было ли что-то удалено
    IF SQL%ROWCOUNT = 0 THEN
        RETURN 'Ошибка: Счет с указанным ID не найден.';
    END IF;
        commit;

    RETURN 'Успех: Счет успешно удален.';

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Ошибка: Указанный пользователь или счет не найден.';
    WHEN OTHERS THEN
        RETURN 'Ошибка: ' || SQLERRM;
END DeleteCashAccount;
/



CREATE OR REPLACE FUNCTION DeleteCashAccountsByOwner(
    p_owner_id IN NUMBER  -- ID владельца счетов
) RETURN VARCHAR2 AS
    v_deleted_count NUMBER := 0; -- Количество удаленных записей
BEGIN
    -- Удаление всех счетов, принадлежащих указанному владельцу
    DELETE FROM Cash_accounts
    WHERE Cash_owner = p_owner_id;

    -- Получаем количество удаленных строк
    v_deleted_count := SQL%ROWCOUNT;

    -- Проверка, было ли что-то удалено
    IF v_deleted_count = 0 THEN
        RETURN 'Ошибка: Счета для указанного владельца не найдены.';
    END IF;

    RETURN 'Успех: Удалено ' || v_deleted_count || ' счет(ов).';

EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Ошибка: ' || SQLERRM;
END DeleteCashAccountsByOwner;
/

CREATE OR REPLACE FUNCTION DeleteUser(
    p_executor_id IN NUMBER,  -- ID пользователя, выполняющего удаление
    p_target_user_id IN NUMBER -- ID пользователя, который будет удален
) RETURN VARCHAR2 AS
    v_executor_role_level NUMBER; -- Уровень роли исполняющего пользователя
    v_target_role_level NUMBER;   -- Уровень роли удаляемого пользователя
BEGIN
    -- Получаем уровень роли исполняющего пользователя
    SELECT r.role_level
    INTO v_executor_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_executor_id;

    -- Получаем уровень роли удаляемого пользователя
    SELECT r.role_level
    INTO v_target_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_target_user_id;

    -- Проверка прав: уровень роли <= 1 или ID совпадают
    IF v_executor_role_level > 1 AND p_executor_id != p_target_user_id THEN
        RETURN 'Ошибка: Недостаточно прав для выполнения операции.';
    END IF;

    -- Проверка: нельзя удалить пользователя с уровнем роли < 1
    IF v_target_role_level < 1 THEN
        RETURN 'Ошибка: Нельзя удалить пользователя с высоким уровнем роли.';
    END IF;

    -- Удаляем пользователя
    DELETE FROM Users
    WHERE User_id = p_target_user_id;

    -- Проверяем, была ли удалена строка
    IF SQL%ROWCOUNT = 0 THEN
        RETURN 'Ошибка: Пользователь с указанным ID не найден.';
    END IF;
    commit;

    RETURN 'Успех: Пользователь удален.';

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Ошибка: Пользователь с указанным ID не найден.';
    WHEN OTHERS THEN
        RETURN 'Ошибка: ' || SQLERRM;
END DeleteUser;
/



CREATE OR REPLACE TRIGGER trg_after_delete_cash_accounts
BEFORE DELETE ON Cash_accounts
FOR EACH ROW
BEGIN
    -- Вызов функции для удаления связанных операций из Queue
    DeleteQueueByCashId(:OLD.Cash_id);

    -- Вызов функции для удаления записей из History
    DeleteHistoryByCashId(:OLD.Cash_id);
END;
/

CREATE OR REPLACE TRIGGER BeforeDeleteUser
BEFORE DELETE ON Users
FOR EACH ROW
BEGIN

    DBMS_OUTPUT.PUT_LINE(DeleteCashAccountsByOwner(:OLD.User_id));

END;
/

CREATE OR REPLACE TRIGGER trg_delete_user_history_queue
BEFORE DELETE ON Users
FOR EACH ROW
DECLARE
    v_transactor_id NUMBER := :OLD.User_id; -- ID удаляемого пользователя
BEGIN
    -- Удаляем записи из таблицы History, где Transactor совпадает с удаляемым User_id
    DELETE FROM History
    WHERE Transactor = v_transactor_id;

    -- Удаляем записи из таблицы Queue, где Transactor совпадает с удаляемым User_id
    DELETE FROM Queue
    WHERE Transactor = v_transactor_id;
END;
/














--=====================                     Блокировка                        ======================

CREATE OR REPLACE FUNCTION Block_Cash_Account(p_user_id IN NUMBER, p_Cash_id IN VARCHAR2)
RETURN VARCHAR2 IS
    v_user_role_level NUMBER;  -- Переменная для хранения уровня роли пользователя
    v_owner_id NUMBER;         -- Переменная для хранения идентификатора владельца счета
BEGIN
    -- Получаем идентификатор владельца счета
    SELECT Cash_owner
    INTO v_owner_id
    FROM Cash_accounts
    WHERE Cash_id = EncryptData(p_Cash_id);

    -- Получаем уровень роли пользователя
    SELECT r.role_level
    INTO v_user_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    -- Проверяем уровень роли и соответствие владельца счета
    IF v_user_role_level > 1 AND not p_user_id = v_owner_id THEN 
        RETURN 'Ошибка: недостаточно прав для блокировки.';
    END IF;

    -- Блокируем запись
    UPDATE Cash_accounts
    SET IsBlocked = 1
    WHERE Cash_id = EncryptData(p_Cash_id);

    -- Проверяем, что изменение применено
    IF SQL%ROWCOUNT = 0 THEN
        RETURN 'Ошибка: запись с указанным Cash_id не найдена.';
    END IF;
    AddToHistory(
        p_transactor => p_user_id,              
        p_cash_from => NULL,            
        p_cash_to => NULL,               
        p_operation => 'Block_Cash_Account', 
        p_amount => NULL,              
        p_operation_description => 'Блокировка счета  ID ' || p_Cash_id
    );

    COMMIT;

    RETURN 'Запись успешно заблокирована.';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Ошибка: указанный Cash_id не найден.';
    WHEN OTHERS THEN
        RETURN 'Произошла ошибка: ' || SQLERRM;
END;
/

CREATE OR REPLACE FUNCTION Unblock_Cash_Account(p_user_id IN INT, p_Cash_id IN VARCHAR2)
RETURN VARCHAR2 IS
    v_user_role_level INT;  -- Переменная для хранения уровня роли пользователя
BEGIN
    -- Получаем уровень роли пользователя
    SELECT r.role_level
    INTO v_user_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    -- Проверяем уровень роли
    IF v_user_role_level > 1 THEN
        RETURN 'Ошибка: недостаточно прав для разблокировки.';
    END IF;

    UPDATE Cash_accounts
    SET IsBlocked = 0
    WHERE Cash_id = EncryptData(p_Cash_id);

    -- Проверяем, что изменение применено
    IF SQL%ROWCOUNT = 0 THEN
        RETURN 'Ошибка: запись с указанным Cash_id не найдена.';
    END IF;
AddToHistory(
        p_transactor => p_user_id,              
        p_cash_from => NULL,            
        p_cash_to => NULL,               
        p_operation => 'Unblock_Cash_Account', 
        p_amount => NULL,              
        p_operation_description => 'Разблокировака счета  ID ' || p_Cash_id
    );
    commit;
    RETURN 'Запись успешно разблокирована.';
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Произошла ошибка: ' || SQLERRM;
END;
/




CREATE OR REPLACE TRIGGER Block_Modifications_If_IsBlocked
BEFORE INSERT OR UPDATE OR DELETE ON Cash_accounts
FOR EACH ROW
DECLARE
    v_custom_exception EXCEPTION;
BEGIN
    IF :OLD.IsBlocked = 1 AND 
       (UPDATING('balance') OR UPDATING('Cash_name') OR UPDATING('Cash_owner') OR UPDATING('Currency_id')) THEN
        RAISE v_custom_exception;  -- Поднимаем пользовательское исключение
    END IF;
EXCEPTION
    WHEN v_custom_exception THEN
        RAISE_APPLICATION_ERROR(-20001, 'Изменение запрещено: запись заблокирована.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Произошла ошибка: ' || SQLERRM); 
END;
/


CREATE OR REPLACE FUNCTION GetCustomErrorMessage(p_error_message VARCHAR2)
RETURN VARCHAR2 IS
    v_start_pos NUMBER;
    v_end_pos NUMBER;
    v_custom_message VARCHAR2(4000);
BEGIN
    -- Ищем начало сообщения об ошибке ORA-20001
    v_start_pos := INSTR(p_error_message, 'ORA-20001');
    
    IF v_start_pos > 0 THEN
        -- Устанавливаем конец сообщения
        v_end_pos := INSTR(p_error_message, CHR(10), v_start_pos); -- ищем символ новой строки
        IF v_end_pos = 0 THEN
            v_end_pos := LENGTH(p_error_message) + 1; -- если нет новой строки, то до конца
        END IF;

        -- Извлекаем только нужное сообщение
        v_custom_message := SUBSTR(p_error_message, v_start_pos, v_end_pos - v_start_pos);
        
        -- Возвращаем результат с добавлением префикса "Ошибка: "
        RETURN TRIM(v_custom_message);
    ELSE
        -- Если нужное сообщение не найдено, возвращаем исходное сообщение
        RETURN p_error_message;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- В случае ошибок внутри функции просто возвращаем исходное сообщение
        RETURN p_error_message;
END;
/






--==============================            Currency                   ====================           
CREATE OR REPLACE FUNCTION Insert_Currency(
    p_user_id NUMBER,
    p_currency_id VARCHAR2,
    p_currency_name VARCHAR2,
    p_exchange_rate NUMBER
) RETURN VARCHAR2 IS
    v_user_role_level NUMBER;
    v_error_message VARCHAR2(4000);
BEGIN
    -- Проверка на NULL параметры
    IF p_currency_id IS NULL OR p_currency_name IS NULL OR p_exchange_rate IS NULL THEN
        RETURN 'Ошибка: Все параметры (Currency_id, Currency_name, Exchange_rate) должны быть заданы.';
    END IF;

    -- Проверка длины параметров
    IF LENGTH(p_currency_id) > 4 THEN
        RETURN 'Ошибка: Currency_id не может превышать 4 символа.';
    END IF;

    IF LENGTH(p_currency_name) > 100 THEN
        RETURN 'Ошибка: Currency_name не может превышать 100 символов.';
    END IF;

    -- Проверка на допустимость exchange_rate
    IF p_exchange_rate < 0 THEN
        RETURN 'Ошибка: Exchange_rate не может быть отрицательным.';
    END IF;

    -- Получение уровня роли пользователя
    SELECT r.role_level
    INTO v_user_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    -- Проверка уровня роли
    IF not v_user_role_level = 0 THEN
        v_error_message := 'Ошибка: недостаточно прав для выполнения этой операции.';
        RETURN v_error_message;
    END IF;

    -- Вставка валюты в таблицу
    INSERT INTO Currencies (Currency_id, Currency_name, Exchange_rate)
    VALUES (p_currency_id, p_currency_name, p_exchange_rate);

    RETURN 'Успешно добавлена валюта: ' || p_currency_name;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RETURN 'Ошибка: валюта с ID ' || p_currency_id || ' уже существует.';
    WHEN OTHERS THEN
        RETURN 'Ошибка: ' || SQLERRM;
END Insert_Currency;
/





CREATE OR REPLACE FUNCTION Update_Currency(
    p_user_id NUMBER,
    p_currency_id VARCHAR2,
    p_new_currency_name VARCHAR2 DEFAULT NULL,
    p_new_exchange_rate NUMBER DEFAULT NULL
) RETURN VARCHAR2 AS
    v_user_role_level NUMBER;
BEGIN
    -- Проверка входных параметров
    IF p_user_id IS NULL OR p_currency_id IS NULL THEN
        RETURN 'Ошибка: p_user_id и p_currency_id обязательны.';
    END IF;

    -- Получение уровня роли пользователя
    SELECT r.role_level
    INTO v_user_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    -- Проверка роли
    IF v_user_role_level > 0 THEN
        RETURN 'Ошибка: Недостаточно прав для изменения записи.';
    END IF;

    -- Проверка наличия изменений
    IF p_new_currency_name IS NULL AND p_new_exchange_rate IS NULL THEN
        RETURN 'Ошибка: Не указаны данные для изменения.';
    END IF;

    -- Обновление записи
    UPDATE Currencies
    SET 
        Currency_name = COALESCE(p_new_currency_name, Currency_name),
        Exchange_rate = COALESCE(p_new_exchange_rate, Exchange_rate)
    WHERE Currency_id = p_currency_id;

    IF SQL%ROWCOUNT = 0 THEN
        RETURN 'Ошибка: Валюта с указанным ID не найдена.';
    END IF;

    RETURN 'Валюта успешно обновлена.';
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Произошла ошибка: ' || SQLERRM;
END Update_Currency;
/

CREATE OR REPLACE FUNCTION Delete_Currency(
    p_user_id NUMBER,
    p_currency_id VARCHAR2
) RETURN VARCHAR2 AS
    v_user_role_level NUMBER;
BEGIN
    -- Проверка входных параметров
    IF p_user_id IS NULL OR p_currency_id IS NULL THEN
        RETURN 'Ошибка: p_user_id и p_currency_id обязательны.';
    END IF;

    -- Получение уровня роли пользователя
    SELECT r.role_level
    INTO v_user_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    -- Проверка роли
    IF v_user_role_level > 0 THEN
        RETURN 'Ошибка: Недостаточно прав для удаления записи.';
    END IF;

    -- Удаление записи
    DELETE FROM Currencies
    WHERE Currency_id = p_currency_id;

    IF SQL%ROWCOUNT = 0 THEN
        RETURN 'Ошибка: Валюта с указанным ID не найдена.';
    END IF;

    RETURN 'Валюта успешно удалена.';
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Произошла ошибка: ' || SQLERRM;
END Delete_Currency;
/

