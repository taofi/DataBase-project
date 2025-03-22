    

-- =========================                  history                  ==============
CREATE OR REPLACE PROCEDURE AddToHistory (
    p_transactor IN NUMBER,             -- ID ����������� (������������, ������� ��������� ��������)
    p_cash_from IN NUMBER DEFAULT NULL, -- ID �����, � �������� ������������ �������� 
    p_cash_to IN NUMBER DEFAULT NULL,   -- ID �����, �� ������� ������������ �������� 
    p_operation IN VARCHAR2,            -- ��� ��������
    p_amount IN NUMBER DEFAULT NULL,     -- ����� �������� 
    p_operation_description IN VARCHAR2 DEFAULT NULL  -- �������� �������� 
) AS
BEGIN
    
    INSERT INTO History (Transactor, cash_from, cash_to, operation, amount, operation_description)
    VALUES (p_transactor, p_cash_from, p_cash_to, p_operation, p_amount, p_operation_description);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20004, '��������� ������: ' || SQLERRM);
END;
/





-- =====================               ROLE                   =========================


-- �������� ��������� ���������� ���� � ��������� ������ ���� ����������� ������������

CREATE OR REPLACE FUNCTION AddRole (
    p_user_id IN NUMBER,
    p_name IN VARCHAR2,
    p_role_level IN NUMBER
) RETURN VARCHAR2 AS
    v_user_role_level NUMBER;
BEGIN
    IF p_user_id IS NULL OR p_name IS NULL OR p_role_level IS NULL THEN
        RETURN '������: ��������� �� ����� ���� NULL.';
    END IF;

    -- ��������� ������ ���� ����������� ������������
    SELECT r.role_level
    INTO v_user_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

   

    -- �������� ������ ����
    IF v_user_role_level >= 1 THEN
        RETURN '������: ������������ ���� ��� ���������� ��������.';
    END IF;

    -- ���������� ����� ����
    INSERT INTO Role (name, role_level)
    VALUES (p_name, p_role_level);

    -- ���������� ������ � �������
    AddToHistory(
        p_transactor => p_user_id,              
        p_cash_from => NULL,            
        p_cash_to => NULL,               
        p_operation => 'AddRole', 
        p_amount => NULL,              
        p_operation_description => '���� ��������� ' || p_name || ' ������� ' || p_role_level
    );

    COMMIT;
    RETURN '���� ���������';

EXCEPTION
    WHEN OTHERS THEN
        -- ��������� ������ ������
        RETURN '��������� ������: ' || SQLERRM;
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
    -- �������� ������� ���������� �� NULL
    IF p_user_id IS NULL OR p_target_user_id IS NULL OR p_role_id IS NULL THEN
        RETURN '������: ��� ��������� ������ ���� ������.';
    END IF;

    -- ��������� ������ ���� ����������� ������������
    SELECT r.role_level
    INTO v_user_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    -- �������� ������ ����
    IF v_user_role_level < 1 THEN
        RETURN '������: ������������ ���� ��� ��������� ����.';
    END IF;

    -- �������� ������������� ��������� ����
    SELECT COUNT(*)
    INTO v_role_exists
    FROM Role
    WHERE Role_id = p_role_id;

    IF v_role_exists = 0 THEN
        RETURN '������: ��������� ���� �� ����������.';
    END IF;

    -- ��������� ����� ���� ��� �������� ������������
    UPDATE Users
    SET User_role = p_role_id
    WHERE User_id = p_target_user_id;

    -- ��������, ���� �� ��������� ������
    IF SQL%ROWCOUNT = 0 THEN
        RETURN '������: ������� ������������ �� ������.';
    END IF;

    -- �������� ���������
    COMMIT;
    RETURN '���� ������� ��������� ��� ������������ � ID ' || p_target_user_id;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN '��������� ������: ' || SQLERRM;
END;
/

-- ��������� �������� ����
CREATE OR REPLACE FUNCTION DeleteRole (
    p_user_id IN NUMBER,
    p_role_id IN NUMBER
) RETURN VARCHAR2 AS
    v_user_role_level NUMBER;
    v_role_usage_count NUMBER;
    v_role_name VARCHAR2(100);
BEGIN
    IF p_user_id IS NULL OR p_role_id IS NULL THEN
        RETURN '������: ��������� �� ����� ���� NULL.';
    END IF;
    -- ��������� ������ ���� ����������� ������������
    SELECT r.role_level
    INTO v_user_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    -- �������� ������ ����
    IF v_user_role_level >= 1 THEN
        RETURN '������: ������������ ���� ��� �������� ����.';
    END IF;

    -- �������� ������������� ����
    SELECT COUNT(*)
    INTO v_role_usage_count
    FROM Users
    WHERE User_role = p_role_id;

    IF v_role_usage_count > 0 THEN
        RETURN '������: ���� �� ����� ���� �������, ��� ��� ��� ������������ ��������������.';
    END IF;
    
    -- ��������� ����� ����
    SELECT r.name
    INTO v_role_name
    FROM Role r
    WHERE r.Role_id = p_role_id;

    -- �������� ����
    DELETE FROM Role
    WHERE Role_id = p_role_id;

    IF SQL%ROWCOUNT = 0 THEN
        RETURN '������: ���� � ��������� ID �� �������.';
    END IF;

    -- ���������� ������ � �������
    AddToHistory(
        p_transactor => p_user_id,              
        p_cash_from => NULL,            
        p_cash_to => NULL,               
        p_operation => 'DeleteRole', 
        p_amount => NULL,              
        p_operation_description => '���� ������� id:' || p_role_id || ' ��� ' || v_role_name
    );

    COMMIT;
    RETURN '���� ������� �������.';

EXCEPTION
    WHEN OTHERS THEN
        RETURN '��������� ������: ' || SQLERRM;
END;
/

CREATE OR REPLACE FUNCTION GetUserRoleLevel(
    p_user_id IN NUMBER -- ID ������������
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
        -- ���� ������������ �� ������
        RETURN '������: ������������ � ��������� ID �� ������.';
    WHEN OTHERS THEN
        -- ����� ��� ��������� ������
        RETURN '������: ' || SQLERRM;
END GetUserRoleLevel;
/


-- ��������� ��������� �����
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
    -- �������� ������� ���������� �� NULL
    IF p_user_id IS NULL OR p_role_id IS NULL THEN
        RETURN '������: p_role_id � p_user_id ������ ���� ������.';
    END IF;

    -- ��������� ������ ���� ����������� ������������
    SELECT r.role_level
    INTO v_user_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    -- �������� ������ ����
    IF v_user_role_level >= 1 THEN
        RETURN '������: ������������ ���� ��� ��������� ����.';
    END IF;

    -- ��������� �������� �������� ����� � ������ ����
    SELECT name, role_level
    INTO v_current_name, v_current_role_level
    FROM Role
    WHERE Role_id = p_role_id;

    -- ���������� ����
    UPDATE Role
    SET name = COALESCE(p_new_name, v_current_name),
        role_level = CASE 
            WHEN p_new_role_level IS NOT NULL THEN p_new_role_level 
            ELSE v_current_role_level 
        END
    WHERE Role_id = p_role_id;

    IF SQL%ROWCOUNT = 0 THEN
        RETURN '������: ���� � ��������� ID �� �������.';
    END IF;

    -- ���������� ������ � �������
    AddToHistory(
        p_transactor => p_user_id,
        p_cash_from => NULL,
        p_cash_to => NULL,
        p_operation => 'UpdateRole',
        p_amount => NULL,
        p_operation_description => '���� �������� id: ' || p_role_id || 
                                    ', ���: ' || COALESCE(p_new_name, v_current_name) || 
                                    ', �������: ' || COALESCE(p_new_role_level, v_current_role_level)
    );

    COMMIT;
    RETURN '���� ������� ���������.';
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN '��������� ������: ' || SQLERRM;
END;
/




--===================                   USER                    ==================




-- ��������� ��������� ������������
CREATE OR REPLACE FUNCTION UpdateUser (
    p_executor_id IN NUMBER,  -- ID ������������, ������������ ��������
    p_target_id IN NUMBER,     -- ID ������������, ��� ������� ���������� ��������
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
    
    -- �������� �� NULL
    IF p_executor_id IS NULL OR p_target_id IS NULL THEN
        RETURN '������: ��������� �� ����� ���� NULL.';
    END IF;

    v_valid := User_valid(p_new_login, p_new_pass, p_new_user_name, p_new_last_name, p_new_phone_number, p_new_pasport, 2);
    IF v_valid is not null then
        return v_valid;
    end if;


    -- ��������� ������ ���� ������������, ������������ ��������
    SELECT r.role_level
    INTO v_executor_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_executor_id;

    -- ��������� ������ ���� �������� ������������
    SELECT r.role_level
    INTO v_target_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_target_id;

    -- �������� ���� �������
    IF NOT (p_executor_id = p_target_id OR v_executor_role_level < v_target_role_level) THEN
        RETURN '������������ ���� ��� ��������� ����� ������������.';
    END IF;
    
    if p_new_pass is not null then
    v_hashed_pass := RAWTOHEX(DBMS_CRYPTO.HASH(UTL_I18N.STRING_TO_RAW(p_new_pass, 'AL32UTF8'), DBMS_CRYPTO.HASH_MD5));
    end if;
    -- ���������� ������������ � �������������� ������� �������� ��� NULL
    UPDATE Users
    SET login = COALESCE(p_new_login, login),
        pass = COALESCE(v_hashed_pass, pass),
        user_name = COALESCE(p_new_user_name, user_name),
        last_name = COALESCE(p_new_last_name, last_name),
        phone_number = COALESCE(p_new_phone_number, phone_number),
        pasport = COALESCE(p_new_pasport, pasport)
    WHERE User_id = p_target_id;

    IF SQL%ROWCOUNT = 0 THEN
        RETURN '������: ������������ � ��������� ID �� ������.';
    END IF;

    -- ���������� ������ � �������
    AddToHistory(
        p_transactor => p_executor_id,              
        p_cash_from => NULL,            
        p_cash_to => NULL,               
        p_operation => 'UpdateUser', 
        p_amount => NULL,              
        p_operation_description => '������������ ������� id:' || p_target_id || ' ' || COALESCE(p_new_login, '(��� ���������)') || ' ' || COALESCE(p_new_user_name, '(��� ���������)')
    );

    COMMIT;

    RETURN '������������ ������� ��������.';
EXCEPTION
    WHEN VALUE_ERROR THEN
        RETURN '������������ ����� ��� �������� ��������. ��������� ����� ������� ����������.';
    WHEN OTHERS THEN
        RETURN '��������� ������: ' || SQLERRM;
END;
/




-- ��������� �������� ������������
CREATE OR REPLACE FUNCTION DeleteUser (
    p_executor_id IN NUMBER,  -- ID ������������, ������������ ��������
    p_target_id IN NUMBER     -- ID ������������, �������� ����� �������
) RETURN VARCHAR2 AS
    v_executor_role_level NUMBER;
    v_target_role_level NUMBER;
    v_user_login VARCHAR2(100);
BEGIN
    -- �������� �� NULL �������� ����������
    IF p_executor_id IS NULL OR p_target_id IS NULL THEN
        RETURN '������: ��������� �� ����� ���� NULL.';
    END IF;

    -- ��������� ������ ���� ������������, ������������ ��������
    SELECT r.role_level
    INTO v_executor_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_executor_id;

    -- ��������� ������ ���� �������� ������������
    SELECT r.role_level
    INTO v_target_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_target_id;

    -- �������� ������� ���������� ��������
    IF p_executor_id = p_target_id OR v_executor_role_level < v_target_role_level THEN
        -- ��������� ������ ������������
        SELECT r.login
        INTO v_user_login
        FROM Users r
        WHERE r.User_id = p_target_id;

        -- �������� ������������
        DELETE FROM Users
        WHERE User_id = p_target_id;

        IF SQL%ROWCOUNT = 0 THEN
            RETURN '������: ������������ � ��������� ID �� ������.';
        END IF;

        -- ����������� ��������
        AddToHistory(
            p_transactor => p_executor_id,              
            p_cash_from => NULL,            
            p_cash_to => NULL,               
            p_operation => 'DeleteUser', 
            p_amount => NULL,              
            p_operation_description => '������������ ������ id:' || p_target_id || ' login: ' || DecryptData(v_user_login)
        );
        COMMIT;
        RETURN '������������ ������� ������.';
    ELSE
        RETURN '������: ������������ ���� ��� �������� ����� ������������.';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN '������: ' || SQLERRM;
END;
/



--======================               cash                          ==========================
--drop SEQUENCE Cash_id_seq;
--commit;
CREATE SEQUENCE Cash_id_seq
START WITH 1000000000000000 -- ��������� ��������
INCREMENT BY 1              -- ��� ����������
NOCACHE                     -- ��� �����������
NOCYCLE;                    -- �� �����������


CREATE OR REPLACE FUNCTION UpdateInfoCashAccount (
    p_user_id IN NUMBER,           -- ������������� ������������
    p_cash_id IN VARCHAR2,         -- ������������� �����
    p_new_cash_name IN VARCHAR2,   -- ����� ��� ����� (����� ���� NULL)
    p_new_currency_id IN VARCHAR2   -- ����� ������ (����� ���� NULL)
) RETURN VARCHAR2 AS
    v_current_balance VARCHAR2(100); -- ������� ������ � ���� ������
    v_old_currency_id VARCHAR2(4);   -- ������� ������
    v_old_exchange_rate NUMBER;       -- ���� ������ ������
    v_new_exchange_rate NUMBER;       -- ���� ����� ������
    v_role_level NUMBER;              -- ������� ���� ������������
    v_new_balance NUMBER;             -- ����� �������� �������
    v_cash_owner NUMBER;              -- �������� �����
BEGIN
    -- �������� �� NULL ���������
    IF p_user_id IS NULL THEN
        RETURN '������: p_user_id �� ����� ���� NULL.';
    END IF;

    IF p_cash_id IS NULL THEN
        RETURN '������: p_cash_id �� ����� ���� NULL.';
    END IF;

    -- ��������� ������� ���������� � �����
    SELECT Cash_owner, balance, Currency_id
    INTO v_cash_owner, v_current_balance, v_old_currency_id
    FROM Cash_accounts
    WHERE Cash_id = EncryptData(p_cash_id);

    -- �������� ���� �������
    SELECT r.role_level
    INTO v_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    -- �������� ���� �������
    IF v_role_level > 1 AND p_user_id != v_cash_owner THEN
        RETURN '������: ������������ ����.';
    END IF;

    -- ���������� ����� �����
    IF p_new_cash_name IS NOT NULL THEN
        UPDATE Cash_accounts
        SET Cash_name = p_new_cash_name
        WHERE Cash_id = EncryptData(p_cash_id);
    END IF;

    -- ���������� ������
    IF p_new_currency_id IS NOT NULL THEN
        -- ��������� ������ �����
        SELECT Exchange_rate
        INTO v_old_exchange_rate
        FROM Currencies
        WHERE Currency_id = v_old_currency_id;

        SELECT Exchange_rate
        INTO v_new_exchange_rate
        FROM Currencies
        WHERE Currency_id = p_new_currency_id;

        -- ���������� ������ �������
        v_new_balance := ROUND((NVL(TO_NUMBER(REGEXP_REPLACE(DecryptData(v_current_balance), '[^0-9.,]', '')), 0) / v_old_exchange_rate) * v_new_exchange_rate, 2);

        -- ���������� ������� � ������
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
        p_operation_description => '���� ������� id: ' || p_cash_id || 
                                    ' name: ' || NVL(p_new_cash_name, '�� ��������') || 
                                    ' currency: ' || NVL(p_new_currency_id, v_old_currency_id)
    );
    RETURN '���� ������� ��������.';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN '������: ��������� ���� ��� ������ �� �������.';
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
    -- �������� �� NULL ��������
    IF p_executor_id IS NULL THEN
        RETURN '������: p_executor_id �� ����� ���� NULL.';
    END IF;

    IF p_cash_owner IS NULL THEN
        RETURN '������: p_cash_owner �� ����� ���� NULL.';
    END IF;

    IF p_cash_name IS NULL OR TRIM(p_cash_name) IS NULL THEN
        RETURN '������: p_cash_name �� ����� ���� NULL ��� ������.';
    END IF;

    IF p_currency_id IS NULL THEN
        RETURN '������: p_currency_id �� ����� ���� NULL.';
    END IF;

    -- �������� ����� ����������
    IF LENGTH(p_cash_name) > 100 THEN
        RETURN '������: p_cash_name �� ����� ��������� 100 ��������.';
    END IF;

    IF LENGTH(p_currency_id) > 4 THEN
        RETURN '������: p_currency_id �� ����� ��������� 4 �������.';
    END IF;

    -- ��������� ������ ���� �����������
    SELECT r.role_level
    INTO v_executor_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_executor_id;

    -- �������� ���� �������
    IF NOT (p_executor_id = p_cash_owner OR v_executor_role_level < 1) THEN
        RETURN '������������ ����.';
    END IF;

    -- ��������, ��� �������� ����� ����������
    SELECT COUNT(*)
    INTO v_count
    FROM Users
    WHERE User_id = p_cash_owner;

    IF v_count = 0 THEN
        RETURN '������������ � ID ' || p_cash_owner || ' �� ������.';
    END IF;

    -- ��������, ��� ������ ����������
    SELECT COUNT(*)
    INTO v_currency_count
    FROM Currencies
    WHERE Currency_id = p_currency_id;

    IF v_currency_count = 0 THEN
        RETURN '������: ������ � ID ' || p_currency_id || ' �� �������.';
    END IF;

    -- ��������� ������ ����������� Cash_id
    SELECT Cash_id_seq.NEXTVAL INTO v_new_cash_id FROM DUAL;

    -- ������� ����� ������ � ������� Cash_accounts
    INSERT INTO Cash_accounts (Cash_id, Cash_owner, balance, Cash_name, Currency_id)
    VALUES (v_new_cash_id, p_cash_owner, 0, p_cash_name, p_currency_id);

    -- ���������� ������ � �������
    AddToHistory(
        p_transactor => p_cash_owner,              
        p_cash_from => NULL,            
        p_cash_to => NULL,               
        p_operation => 'CreateCashAccount', 
        p_amount => NULL,              
        p_operation_description => '���� ������ id: ' || v_new_cash_id || 
                                    ' name: ' || p_cash_name || 
                                    ' currency: ' || p_currency_id
    );

    COMMIT;

    RETURN '���� ������� ������.';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN '������: ��������� ������������ ��� ������ �� �������.';
    WHEN OTHERS THEN
        RETURN '��������� ������ ��� ���������� �����: ' || SQLERRM;
END;
/

CREATE OR REPLACE PROCEDURE SetBalance (
    p_cash_id IN NUMBER,      
    p_new_balance IN NUMBER
) AS
BEGIN
    
    -- ���������� ������� �����
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
    -- �������� ������������� ������������ � ������ ��� ����
    SELECT r.role_level
    INTO v_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    IF v_role_level > 1 THEN
        RETURN '������: � ��� ������������ ���� ��� ���������� ���� ��������.';
    END IF;

    -- �������� ������������� ����� � ��������� �������� �������
    SELECT balance
    INTO v_current_balance
    FROM uncrypt_cash_accounts
    WHERE Cash_id = p_cash_id;

    -- ���������� ������ �������
    v_new_balance := v_current_balance + p_amount;

    -- �������� �� ������������� ������
    IF v_new_balance < 0 THEN
        RETURN '������: ������ ����� �� ����� ���� �������������. ������� ������: ' || v_current_balance;
    END IF;


    -- ���������� ������� �����
    SetBalance(p_cash_id, v_new_balance);

    AddToHistory(
        p_transactor => p_user_id,              
        p_cash_from => p_cash_id,            
        p_cash_to => NULL,               
        p_operation => 'UpdateAccountBalance', 
        p_amount => p_amount,              
        p_operation_description => '��������� ������� ����� ID ' || p_cash_id || ' �� ����� ' || p_amount || ' ������� ��������. ����� ������: ' || v_new_balance
    );

    -- �������� ���������
    RETURN '������ ����� ID ' || p_cash_id || ' ������� ��������. ����� ������: ' || v_new_balance;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN '������: ���� ��� ������������ �� �������.';
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

    -- ���������� ������ �������
    v_new_balance := v_current_balance + p_amount;

    -- ���������� ������� �����
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
    v_converted_amount NUMBER;      -- ������������ ����� � ������ ����������
    v_is_blocked NUMBER;            -- ���������� ��� �������� ��������� �������� �����
BEGIN
    -- �������� �� NULL ���������
    IF p_user_id IS NULL THEN
        RETURN '������: p_user_id �� ����� ���� NULL.';
    END IF;
    IF p_sender_cash_id IS NULL THEN
        RETURN '������: p_sender_cash_id �� ����� ���� NULL.';
    END IF;
    IF p_receiver_cash_id IS NULL THEN
        RETURN '������: p_receiver_cash_id �� ����� ���� NULL.';
    END IF;
    IF p_amount IS NULL THEN
        RETURN '������: p_amount �� ����� ���� NULL.';
    END IF;

    -- �������� ����� ��������
    IF p_amount <= 0 THEN
        RETURN '������: ����� �������� ������ ���� �������������.';
    END IF;

    -- ��������� ������ ����������� � ��� �������
    SELECT balance, Currency_id
    INTO v_sender_balance, v_sender_currency_id
    FROM uncrypt_cash_accounts
    WHERE Cash_id = p_sender_cash_id;

    -- �������� ������� �����������
    IF v_sender_balance < p_amount THEN
        RETURN '������: ������������ ������� �� ����� �����������. ������� ������: ' || v_sender_balance;
    END IF;

    -- ��������� ���������� � ������� �����
    SELECT Currency_id, IsBlocked
    INTO v_receiver_currency_id, v_is_blocked
    FROM uncrypt_cash_accounts
    WHERE Cash_id = p_receiver_cash_id;

    -- ��������, ������������ �� ������� ����
    IF v_is_blocked = 1 THEN
        RETURN '������: ������� ���� ������������.';
    END IF;

    -- ��������� ������ �����
    SELECT Exchange_rate
    INTO v_sender_exchange_rate
    FROM Currencies
    WHERE Currency_id = v_sender_currency_id;

    SELECT Exchange_rate
    INTO v_receiver_exchange_rate
    FROM Currencies
    WHERE Currency_id = v_receiver_currency_id;

    -- ������� ����� ��� ���������� �� ���� ����������
    v_converted_amount := ROUND((p_amount / v_sender_exchange_rate) * v_receiver_exchange_rate, 2);

    -- ������ ������� � ������� �����������
    UpdateAccountBalanceNoLog(p_sender_cash_id, -p_amount);

    -- ���������� ������� �� ������ ����������
    UpdateAccountBalanceNoLog(p_receiver_cash_id, v_converted_amount);

    -- ���������� �������� � �������
    AddToHistory(
        p_transactor => p_user_id,              
        p_cash_from => p_sender_cash_id,            
        p_cash_to => p_receiver_cash_id,               
        p_operation => 'TransferFunds', 
        p_amount => v_converted_amount,              
        p_operation_description => '������� ' || p_amount || 
                                    ' �� ����� ID ' || p_sender_cash_id || 
                                    ' � ����� ID ' || p_receiver_cash_id
    );

    -- �������� ���������
    COMMIT;
    RETURN '������� ' || p_amount || ' �� ����� ID ' || p_sender_cash_id || 
           ' � ����� ID ' || p_receiver_cash_id || 
           ' �������� �������. ��������: ' || v_converted_amount || 
           ' � ������ ����������.';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN '������: ��������� ���� �� ������.';
    WHEN OTHERS THEN
        RETURN GetCustomErrorMessage(SQLERRM);
END;
/


CREATE OR REPLACE FUNCTION ProcessTransfer (
    p_user_id IN NUMBER,           -- ID ������������, ������������ ��������
    p_sender_cash_id IN NUMBER,    -- ID ����� �����������
    p_receiver_cash_id IN NUMBER,  -- ID ����� ����������
    p_amount IN NUMBER              -- ����� ��������
) RETURN VARCHAR2 AS
    v_role_level NUMBER;           
    v_sender_balance NUMBER;      
    v_receiver_exists NUMBER;
    v_owner_id NUMBER;
    v_result VARCHAR2(4000);       -- ���������� ��� ��������� � ����������
BEGIN
    -- �������� �� NULL ���������
    IF p_user_id IS NULL THEN
        RETURN '������: p_user_id �� ����� ���� NULL.';
    END IF;
    IF p_sender_cash_id IS NULL THEN
        RETURN '������: p_sender_cash_id �� ����� ���� NULL.';
    END IF;
    IF p_receiver_cash_id IS NULL THEN
        RETURN '������: p_receiver_cash_id �� ����� ���� NULL.';
    END IF;
    IF p_amount IS NULL THEN
        RETURN '������: p_amount �� ����� ���� NULL.';
    END IF;

    -- �������� ������ ���� ������������
    SELECT r.role_level
    INTO v_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    -- �������� ������������� ����� � ��������� �������� ������� �����������
    SELECT balance
    INTO v_sender_balance
    FROM uncrypt_cash_accounts
    WHERE Cash_id = p_sender_cash_id;

    IF v_sender_balance < p_amount THEN
        RETURN '������: ������������ ������� �� ����� �����������. ������� ������: ' || v_sender_balance;
    END IF;
    
    
    SELECT COUNT(*)
    INTO v_receiver_exists
    FROM uncrypt_cash_accounts
    WHERE Cash_id = p_receiver_cash_id;

    IF v_receiver_exists = 0 THEN
        RETURN '������: ���� ���������� � ID ' || p_receiver_cash_id || ' �� ������.';
    END IF;

    
    SELECT CASH_OWNER
    INTO v_owner_id
    FROM uncrypt_cash_accounts
    WHERE Cash_id = p_sender_cash_id;
        
    IF v_role_level > 1 and not v_owner_id = p_user_id THEN
        RETURN '������: ��������������� ����';
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
        -- ��������� ������ � ������� Queue
        INSERT INTO Queue (
            Transactor, cash_from, cash_to, operation, amount, operation_description
        ) VALUES (
            p_user_id, p_sender_cash_id, p_receiver_cash_id, 
            'TransferFunds', p_amount,
            '������ �� ������� ' || p_amount || ' �� ����� ID ' || p_sender_cash_id || 
            ' � ����� ID ' || p_receiver_cash_id
        );
        COMMIT;
        RETURN '������� �������� � ������� �� ���������.';
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN '������: ��������� ������������ ��� ���� �� ������.';
    WHEN OTHERS THEN
        RETURN '������: ' || SQLERRM;
END;
/







--=================                 queue                   =============

CREATE OR REPLACE FUNCTION UpdateQueueRow (
    p_user_id IN NUMBER,             
    p_operation_id IN NUMBER,        
    p_new_cash_to IN VARCHAR2,       -- ������� ��� �� VARCHAR2
    p_new_amount IN VARCHAR2          -- ������� ��� �� VARCHAR2
) RETURN VARCHAR2 IS
    v_role_level NUMBER;  
    v_count NUMBER;
    old_cash_from VARCHAR2(100);       
    old_cash_to VARCHAR2(100);          
BEGIN
    IF p_user_id IS NULL THEN
        RETURN '������: id ������������ ������ ���� ������.';
    END IF;
    IF p_operation_id IS NULL THEN
        RETURN '������: id �������� ������ ���� ������.';
    END IF;
    
    -- �������� ������ ���� ������������
    SELECT r.role_level
    INTO v_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    IF v_role_level > 1 THEN
        RETURN '������: � ������������ ������������ ���� ��� ���������� ��������.';
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
        RETURN '������: �������� � ID ' || p_operation_id || ' �� �������.';
    END IF;

    -- ���������� ������
    UPDATE Queue
    SET 
        cash_to = NVL(p_new_cash_to, cash_to),
        amount = NVL(p_new_amount, amount),
        operation_description = '������� ' || NVL(p_new_amount, amount) || ' �� ����� ID ' || old_cash_from || ' � ����� ID ' || NVL(p_new_cash_to, old_cash_to)
    WHERE Operation_id = p_operation_id;

    -- ����������� ��������� � �������
    AddToHistory(
        p_transactor => p_user_id,              
        p_cash_from => NULL,            
        p_cash_to => NULL,               
        p_operation => 'UpdateQueueRow', 
        p_amount => NULL,              
        p_operation_description => '��������� �������� ID ' || p_operation_id
    );

    RETURN '������� ��������� �������� � ID ' || p_operation_id || '.';

EXCEPTION
    WHEN OTHERS THEN
        RETURN '������: ' || SQLERRM;
END;
/




CREATE OR REPLACE FUNCTION ExecuteQueueOperation (
    p_operator_id IN NUMBER,       -- ID ������������, ������������ ��������
    p_operation_id IN NUMBER        -- ID �������� � ������� Queue
) RETURN VARCHAR2 IS

    v_role_level NUMBER;           -- ������� ���� ���������
    v_cash_from NUMBER;            -- ���� �����������
    v_cash_to NUMBER;              -- ���� ����������
    v_amount NUMBER;               -- ����� ��������
    v_operation VARCHAR2(50);      -- ��������
    v_description VARCHAR2(255);   -- �������� ��������
    v_result VARCHAR2(255);        -- ��������� ����������

BEGIN
    -- �������� ������ ���� ���������
    SELECT r.role_level
    INTO v_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_operator_id;

    IF v_role_level > 1 THEN
        RETURN '������: � ��� ������������ ���� ��� ���������� �������� �� �������.';
    END IF;

    -- ��������� ������ �������� �� ������� Queue
    SELECT cash_from, cash_to, amount, operation, operation_description
    INTO v_cash_from, v_cash_to, v_amount, v_operation, v_description
    FROM uncrypt_Queue
    WHERE Operation_id = p_operation_id;

    -- ���������� ��������
    v_result := ProcessTransfer(
        p_user_id => p_operator_id,       -- ������������, ����������� ��������
        p_sender_cash_id => v_cash_from,  -- ���� �����������
        p_receiver_cash_id => v_cash_to,   -- ���� ����������
        p_amount => v_amount                -- ����� ��������
    );

    -- �������� �������� �� ������� Queue ����� ��������� ����������
    DELETE FROM Queue
    WHERE Operation_id = p_operation_id;

    -- ���������� ������ � �������
    AddToHistory(
        p_transactor => p_operator_id,              
        p_cash_from => NULL,            
        p_cash_to => NULL,               
        p_operation => 'ExecuteQueueOperation', 
        p_amount => NULL,              
        p_operation_description => '������������� �������� ID ' || p_operation_id
    );

    COMMIT;

    RETURN '�������� ���������: ' || v_result;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN '������: �������� � ID ' || p_operation_id || ' �� ������� � �������.';
    WHEN OTHERS THEN
        RETURN '������ ���������� ��������: ' || SQLERRM;
END ExecuteQueueOperation;
/




CREATE OR REPLACE FUNCTION DeleteQueueRow(
    p_user_id IN NUMBER,      -- ID ������������, ������������ ��������
    p_operation_id IN NUMBER  -- ID ��������, ������� ����� �������
) RETURN VARCHAR2 IS
    v_user_role_level NUMBER;  -- ������� ���� ������������
    v_result VARCHAR2(1000);   -- ��������� � ����������
BEGIN
    -- �������� ������� ���� ������������
    SELECT r.role_level
    INTO v_user_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    IF v_user_role_level > 1 THEN
        RETURN '������: ������������ ���� ��� ���������� ��������.';
    END IF;

    -- ������� ������ �� ������� Queue
    DELETE FROM Queue
    WHERE Operation_id = p_operation_id;

    -- ���������, ���� �� �������� ��������
    IF SQL%ROWCOUNT = 0 THEN
        v_result := '������: �������� � ID ' || p_operation_id || ' �� �������.';
    ELSE
        v_result := '�������: �������� � ID ' || p_operation_id || ' �������.';
    END IF;

    RETURN v_result;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN '������: ������������ � ID ' || p_user_id || ' �� ������.';
    WHEN OTHERS THEN
        RETURN '������: ' || SQLERRM;
END DeleteQueueRow;
/





-- ===========================                     ��������                     ==============

CREATE OR REPLACE PROCEDURE DeleteQueueByCashId(
    p_cash_id IN VARCHAR2  -- ID �����, �������� � ������� ����� �������
) AS
BEGIN
    -- ������� ������, ��� cash_from ��� cash_to ��������� � p_cash_id
    DELETE FROM Queue
    WHERE cash_from = p_cash_id OR cash_to = p_cash_id;

    -- ���������, ���� �� ������� ������
    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('��� �������� � ��������� cash_id: ' || p_cash_id);
    ELSE
        DBMS_OUTPUT.PUT_LINE('������� ��������: ' || SQL%ROWCOUNT || ' ��� cash_id: ' || p_cash_id);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('������: ' || SQLERRM);
END DeleteQueueByCashId;
/


CREATE OR REPLACE PROCEDURE DeleteHistoryByCashId(
    p_cash_id IN VARCHAR2  -- ID �����, �������� � ������� ����� �������
) AS
BEGIN
    -- ������� ������, ��� cash_from ��� cash_to ��������� � p_cash_id
    DELETE FROM History
    WHERE cash_from = p_cash_id OR cash_to = p_cash_id;

    -- ���������, ���� �� ������� ������
    IF SQL%ROWCOUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('��� �������� � ��������� cash_id: ' || p_cash_id);
    ELSE
        DBMS_OUTPUT.PUT_LINE('������� ��������: ' || SQL%ROWCOUNT || ' ��� cash_id: ' || p_cash_id);
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('������: ' || SQLERRM);
END DeleteHistoryByCashId;
/



CREATE OR REPLACE FUNCTION DeleteCashAccount(
    p_user_id IN NUMBER,   -- ID ������������, ������������ ��������
    p_cash_id IN VARCHAR2  -- ID �����, ������� ����� �������
) RETURN VARCHAR2 AS
    v_user_role_level NUMBER; -- ������� ���� ������������
    v_cash_owner NUMBER;      -- �������� �����
BEGIN
    -- �������� ������� ���� ������������
    SELECT r.role_level
    INTO v_user_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    -- �������� ��������� �����
    SELECT Cash_owner
    INTO v_cash_owner
    FROM Cash_accounts
    WHERE Cash_id = EncryptCashId(p_cash_id);

    -- ��������� ����� �� ��������
    IF v_user_role_level > 1 AND v_cash_owner != p_user_id THEN
        RETURN '������: ������������ ���� ��� �������� �����.';
    END IF;

    -- ������� ������ �� ������� Cash_accounts
    DeleteQueueByCashId(EncryptCashId(p_cash_id));
    DeleteHistoryByCashId(EncryptCashId(p_cash_id));

    DELETE FROM Cash_accounts
    WHERE Cash_id = EncryptCashId(p_cash_id);

    -- ���������, ���� �� ���-�� �������
    IF SQL%ROWCOUNT = 0 THEN
        RETURN '������: ���� � ��������� ID �� ������.';
    END IF;
        commit;

    RETURN '�����: ���� ������� ������.';

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN '������: ��������� ������������ ��� ���� �� ������.';
    WHEN OTHERS THEN
        RETURN '������: ' || SQLERRM;
END DeleteCashAccount;
/



CREATE OR REPLACE FUNCTION DeleteCashAccountsByOwner(
    p_owner_id IN NUMBER  -- ID ��������� ������
) RETURN VARCHAR2 AS
    v_deleted_count NUMBER := 0; -- ���������� ��������� �������
BEGIN
    -- �������� ���� ������, ������������� ���������� ���������
    DELETE FROM Cash_accounts
    WHERE Cash_owner = p_owner_id;

    -- �������� ���������� ��������� �����
    v_deleted_count := SQL%ROWCOUNT;

    -- ��������, ���� �� ���-�� �������
    IF v_deleted_count = 0 THEN
        RETURN '������: ����� ��� ���������� ��������� �� �������.';
    END IF;

    RETURN '�����: ������� ' || v_deleted_count || ' ����(��).';

EXCEPTION
    WHEN OTHERS THEN
        RETURN '������: ' || SQLERRM;
END DeleteCashAccountsByOwner;
/

CREATE OR REPLACE FUNCTION DeleteUser(
    p_executor_id IN NUMBER,  -- ID ������������, ������������ ��������
    p_target_user_id IN NUMBER -- ID ������������, ������� ����� ������
) RETURN VARCHAR2 AS
    v_executor_role_level NUMBER; -- ������� ���� ������������ ������������
    v_target_role_level NUMBER;   -- ������� ���� ���������� ������������
BEGIN
    -- �������� ������� ���� ������������ ������������
    SELECT r.role_level
    INTO v_executor_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_executor_id;

    -- �������� ������� ���� ���������� ������������
    SELECT r.role_level
    INTO v_target_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_target_user_id;

    -- �������� ����: ������� ���� <= 1 ��� ID ���������
    IF v_executor_role_level > 1 AND p_executor_id != p_target_user_id THEN
        RETURN '������: ������������ ���� ��� ���������� ��������.';
    END IF;

    -- ��������: ������ ������� ������������ � ������� ���� < 1
    IF v_target_role_level < 1 THEN
        RETURN '������: ������ ������� ������������ � ������� ������� ����.';
    END IF;

    -- ������� ������������
    DELETE FROM Users
    WHERE User_id = p_target_user_id;

    -- ���������, ���� �� ������� ������
    IF SQL%ROWCOUNT = 0 THEN
        RETURN '������: ������������ � ��������� ID �� ������.';
    END IF;
    commit;

    RETURN '�����: ������������ ������.';

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN '������: ������������ � ��������� ID �� ������.';
    WHEN OTHERS THEN
        RETURN '������: ' || SQLERRM;
END DeleteUser;
/



CREATE OR REPLACE TRIGGER trg_after_delete_cash_accounts
BEFORE DELETE ON Cash_accounts
FOR EACH ROW
BEGIN
    -- ����� ������� ��� �������� ��������� �������� �� Queue
    DeleteQueueByCashId(:OLD.Cash_id);

    -- ����� ������� ��� �������� ������� �� History
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
    v_transactor_id NUMBER := :OLD.User_id; -- ID ���������� ������������
BEGIN
    -- ������� ������ �� ������� History, ��� Transactor ��������� � ��������� User_id
    DELETE FROM History
    WHERE Transactor = v_transactor_id;

    -- ������� ������ �� ������� Queue, ��� Transactor ��������� � ��������� User_id
    DELETE FROM Queue
    WHERE Transactor = v_transactor_id;
END;
/














--=====================                     ����������                        ======================

CREATE OR REPLACE FUNCTION Block_Cash_Account(p_user_id IN NUMBER, p_Cash_id IN VARCHAR2)
RETURN VARCHAR2 IS
    v_user_role_level NUMBER;  -- ���������� ��� �������� ������ ���� ������������
    v_owner_id NUMBER;         -- ���������� ��� �������� �������������� ��������� �����
BEGIN
    -- �������� ������������� ��������� �����
    SELECT Cash_owner
    INTO v_owner_id
    FROM Cash_accounts
    WHERE Cash_id = EncryptData(p_Cash_id);

    -- �������� ������� ���� ������������
    SELECT r.role_level
    INTO v_user_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    -- ��������� ������� ���� � ������������ ��������� �����
    IF v_user_role_level > 1 AND not p_user_id = v_owner_id THEN 
        RETURN '������: ������������ ���� ��� ����������.';
    END IF;

    -- ��������� ������
    UPDATE Cash_accounts
    SET IsBlocked = 1
    WHERE Cash_id = EncryptData(p_Cash_id);

    -- ���������, ��� ��������� ���������
    IF SQL%ROWCOUNT = 0 THEN
        RETURN '������: ������ � ��������� Cash_id �� �������.';
    END IF;
    AddToHistory(
        p_transactor => p_user_id,              
        p_cash_from => NULL,            
        p_cash_to => NULL,               
        p_operation => 'Block_Cash_Account', 
        p_amount => NULL,              
        p_operation_description => '���������� �����  ID ' || p_Cash_id
    );

    COMMIT;

    RETURN '������ ������� �������������.';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN '������: ��������� Cash_id �� ������.';
    WHEN OTHERS THEN
        RETURN '��������� ������: ' || SQLERRM;
END;
/

CREATE OR REPLACE FUNCTION Unblock_Cash_Account(p_user_id IN INT, p_Cash_id IN VARCHAR2)
RETURN VARCHAR2 IS
    v_user_role_level INT;  -- ���������� ��� �������� ������ ���� ������������
BEGIN
    -- �������� ������� ���� ������������
    SELECT r.role_level
    INTO v_user_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    -- ��������� ������� ����
    IF v_user_role_level > 1 THEN
        RETURN '������: ������������ ���� ��� �������������.';
    END IF;

    UPDATE Cash_accounts
    SET IsBlocked = 0
    WHERE Cash_id = EncryptData(p_Cash_id);

    -- ���������, ��� ��������� ���������
    IF SQL%ROWCOUNT = 0 THEN
        RETURN '������: ������ � ��������� Cash_id �� �������.';
    END IF;
AddToHistory(
        p_transactor => p_user_id,              
        p_cash_from => NULL,            
        p_cash_to => NULL,               
        p_operation => 'Unblock_Cash_Account', 
        p_amount => NULL,              
        p_operation_description => '�������������� �����  ID ' || p_Cash_id
    );
    commit;
    RETURN '������ ������� ��������������.';
EXCEPTION
    WHEN OTHERS THEN
        RETURN '��������� ������: ' || SQLERRM;
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
        RAISE v_custom_exception;  -- ��������� ���������������� ����������
    END IF;
EXCEPTION
    WHEN v_custom_exception THEN
        RAISE_APPLICATION_ERROR(-20001, '��������� ���������: ������ �������������.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('��������� ������: ' || SQLERRM); 
END;
/


CREATE OR REPLACE FUNCTION GetCustomErrorMessage(p_error_message VARCHAR2)
RETURN VARCHAR2 IS
    v_start_pos NUMBER;
    v_end_pos NUMBER;
    v_custom_message VARCHAR2(4000);
BEGIN
    -- ���� ������ ��������� �� ������ ORA-20001
    v_start_pos := INSTR(p_error_message, 'ORA-20001');
    
    IF v_start_pos > 0 THEN
        -- ������������� ����� ���������
        v_end_pos := INSTR(p_error_message, CHR(10), v_start_pos); -- ���� ������ ����� ������
        IF v_end_pos = 0 THEN
            v_end_pos := LENGTH(p_error_message) + 1; -- ���� ��� ����� ������, �� �� �����
        END IF;

        -- ��������� ������ ������ ���������
        v_custom_message := SUBSTR(p_error_message, v_start_pos, v_end_pos - v_start_pos);
        
        -- ���������� ��������� � ����������� �������� "������: "
        RETURN TRIM(v_custom_message);
    ELSE
        -- ���� ������ ��������� �� �������, ���������� �������� ���������
        RETURN p_error_message;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        -- � ������ ������ ������ ������� ������ ���������� �������� ���������
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
    -- �������� �� NULL ���������
    IF p_currency_id IS NULL OR p_currency_name IS NULL OR p_exchange_rate IS NULL THEN
        RETURN '������: ��� ��������� (Currency_id, Currency_name, Exchange_rate) ������ ���� ������.';
    END IF;

    -- �������� ����� ����������
    IF LENGTH(p_currency_id) > 4 THEN
        RETURN '������: Currency_id �� ����� ��������� 4 �������.';
    END IF;

    IF LENGTH(p_currency_name) > 100 THEN
        RETURN '������: Currency_name �� ����� ��������� 100 ��������.';
    END IF;

    -- �������� �� ������������ exchange_rate
    IF p_exchange_rate < 0 THEN
        RETURN '������: Exchange_rate �� ����� ���� �������������.';
    END IF;

    -- ��������� ������ ���� ������������
    SELECT r.role_level
    INTO v_user_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    -- �������� ������ ����
    IF not v_user_role_level = 0 THEN
        v_error_message := '������: ������������ ���� ��� ���������� ���� ��������.';
        RETURN v_error_message;
    END IF;

    -- ������� ������ � �������
    INSERT INTO Currencies (Currency_id, Currency_name, Exchange_rate)
    VALUES (p_currency_id, p_currency_name, p_exchange_rate);

    RETURN '������� ��������� ������: ' || p_currency_name;

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RETURN '������: ������ � ID ' || p_currency_id || ' ��� ����������.';
    WHEN OTHERS THEN
        RETURN '������: ' || SQLERRM;
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
    -- �������� ������� ����������
    IF p_user_id IS NULL OR p_currency_id IS NULL THEN
        RETURN '������: p_user_id � p_currency_id �����������.';
    END IF;

    -- ��������� ������ ���� ������������
    SELECT r.role_level
    INTO v_user_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    -- �������� ����
    IF v_user_role_level > 0 THEN
        RETURN '������: ������������ ���� ��� ��������� ������.';
    END IF;

    -- �������� ������� ���������
    IF p_new_currency_name IS NULL AND p_new_exchange_rate IS NULL THEN
        RETURN '������: �� ������� ������ ��� ���������.';
    END IF;

    -- ���������� ������
    UPDATE Currencies
    SET 
        Currency_name = COALESCE(p_new_currency_name, Currency_name),
        Exchange_rate = COALESCE(p_new_exchange_rate, Exchange_rate)
    WHERE Currency_id = p_currency_id;

    IF SQL%ROWCOUNT = 0 THEN
        RETURN '������: ������ � ��������� ID �� �������.';
    END IF;

    RETURN '������ ������� ���������.';
EXCEPTION
    WHEN OTHERS THEN
        RETURN '��������� ������: ' || SQLERRM;
END Update_Currency;
/

CREATE OR REPLACE FUNCTION Delete_Currency(
    p_user_id NUMBER,
    p_currency_id VARCHAR2
) RETURN VARCHAR2 AS
    v_user_role_level NUMBER;
BEGIN
    -- �������� ������� ����������
    IF p_user_id IS NULL OR p_currency_id IS NULL THEN
        RETURN '������: p_user_id � p_currency_id �����������.';
    END IF;

    -- ��������� ������ ���� ������������
    SELECT r.role_level
    INTO v_user_role_level
    FROM Users u
    JOIN Role r ON u.User_role = r.Role_id
    WHERE u.User_id = p_user_id;

    -- �������� ����
    IF v_user_role_level > 0 THEN
        RETURN '������: ������������ ���� ��� �������� ������.';
    END IF;

    -- �������� ������
    DELETE FROM Currencies
    WHERE Currency_id = p_currency_id;

    IF SQL%ROWCOUNT = 0 THEN
        RETURN '������: ������ � ��������� ID �� �������.';
    END IF;

    RETURN '������ ������� �������.';
EXCEPTION
    WHEN OTHERS THEN
        RETURN '��������� ������: ' || SQLERRM;
END Delete_Currency;
/

