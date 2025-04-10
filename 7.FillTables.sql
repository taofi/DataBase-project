INSERT INTO Role (name, role_level) VALUES ('head admin', 0);
SELECT * FROM ROLE;
SELECT LENGTH(Key_value) AS key_length FROM EncryptionKeys WHERE Key_id = 1;
UPDATE EncryptionKeys 
SET Key_value = UTL_RAW.CAST_TO_RAW('16IoRaeSsS1gsd5!') 
WHERE Key_id = 1;
select * from Role;
select * from Users;
select * from Currencies;


commit;

--============= ����� ������������ =========
BEGIN
    DBMS_OUTPUT.PUT_LINE(l_json_clob);

END;
/




GRANT READ, WRITE ON DIRECTORY MY_DIRECTORY TO PDBADMIN;  -- ��� ������ ������������

BEGIN

    ExportUsersToJson('users2.json');
END;
/

BEGIN
    ImportUsersFromJson('users2.json');
END;
/


EXECUTE Export_Role_To_JSON('Role.json');
EXECUTE Export_Currencies_To_JSON('Currencies.json');
EXECUTE Export_Cash_Accounts_To_JSON('Cash.json');
EXECUTE Export_History_To_JSON('history.json');
EXECUTE Export_Queue_To_JSON('Queue.json');

EXECUTE Import_Role_To_JSON('Role.json');
EXECUTE Import_Users_To_JSON('Users.json');
EXECUTE Import_Cash_Accounts_To_JSON('Cash.json');
EXECUTE Import_Currencies_To_JSON('Currencies.json');
EXECUTE Import_History_To_JSON('history.json');
EXECUTE Import_Queue_To_JSON('Queue.json');

SELECT * FROM Users WHERE Login = EncryptData('admin');
BEGIN
    
    DBMS_OUTPUT.PUT_LINE(Authorize_User('admin', 'admin'));
END;
/
BEGIN
    Generate_Users();
END;
/
-- ���������� ������
select * from Currencies;
begin
    DBMS_OUTPUT.PUT_LINE(Insert_Currency(1, 'BYN', '����������� �����', 3.2));
    DBMS_OUTPUT.PUT_LINE(Insert_Currency(1, 'USD', '������', 1));
end;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE(AddRole(1, 'admin', 1));
    DBMS_OUTPUT.PUT_LINE(AddRole(1, 'user', 2));
END;
/
BEGIN
    DBMS_OUTPUT.PUT_LINE(DeleteCashAccount(1, '1000000000000006'));
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE(AddRole(1, 'test', 4));
END;
/
BEGIN
    DBMS_OUTPUT.PUT_LINE(UpdateRole(2, 1, 'head admin', 0));
END;
/
BEGIN
       DBMS_OUTPUT.PUT_LINE(pdbAdmin.Register_User('login2', 'pass', 'name', 'last_name', '375018910391', 'RF12345', 3));

END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE(pdbAdmin.Register_User('admin', 'admin', 'admin', 'last_name', '375018110391', '2s0952a', 1));

    DBMS_OUTPUT.PUT_LINE(pdbAdmin.Register_User('admin2', 'pass', 'admin', 'last_name', '375048110391', '2s4952a', 2));
    DBMS_OUTPUT.PUT_LINE(pdbAdmin.Register_User('login1', 'pass', 'admin', 'last_name', '375418110391', '2s0452a', 3));

END;
/

BEGIN
pdbAdmin.AddToHistory(
        p_transactor => 2,              
        p_cash_from => NULL,            
        p_cash_to => NULL,               
        p_operation => 'UpdateUser', 
        p_amount => NULL,              
        p_operation_description => '������������ ������� id:' || 2 || ' ' 
    );
    END;
    /


select * from Role;


DECLARE
    v_message VARCHAR2(255);
BEGIN
    AddRole(1, 'user', 3, v_message);
    DBMS_OUTPUT.PUT_LINE(v_message);
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE(addrole(2, 'test', -1));
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE(UpdateRole(2, 2, 'admin', 1));
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE(UpdateRole(2, 1, 'head admin', 0));
END;
/


select * from Users;
select * from UsersView;

select * from Role;

DECLARE
    v_message VARCHAR2(255);
BEGIN
    UpdateUser(0, 10, 'login1', 'asd', 'ff', 'last_name', '123123', v_message);
    DBMS_OUTPUT.PUT_LINE(v_message);
END;
/

DECLARE
    v_message VARCHAR2(255);
BEGIN
    DeleteUser(1, 7,  v_message);
    DBMS_OUTPUT.PUT_LINE(v_message);
END;
/


select * from uncrypt_history;
select * from history;


BEGIN
    
    DBMS_OUTPUT.PUT_LINE(DeleteUser(2, 2));
END;
/

select * from Cash_accounts;
    SELECT Cash_id_seq.NEXTVAL FROM DUAL;
select * from uncrypt_cash_accounts;
begin
DBMS_OUTPUT.PUT_LINE(Unblock_Cash_Account(1,'1000000000000018' ));
end;
/


begin 

    DBMS_OUTPUT.PUT_LINE(UpdateInfoCashAccount(1, '1000000000000018', 'newname', null));

end;
/

BEGIN
    
    DBMS_OUTPUT.PUT_LINE(ProcessTransfer(1, 1000000000000018, 1000000000000019, 200));
END;
/
select * from UsersView;




BEGIN
    DBMS_OUTPUT.PUT_LINE(Block_Cash_Account(EncryptData('1000000000000009')));
END;
/

-- ������������� ������
BEGIN
    DBMS_OUTPUT.PUT_LINE(Unblock_Cash_Account(EncryptData('1000000000000009')));
END;
/

BEGIN
    
    DBMS_OUTPUT.PUT_LINE(CreateCashAccount(1, 1, 'name2', 'BYN'));
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE(UpdateAccountBalance(1, 1000000000000009 , 1500));
END;
/



select * from Queue;
select * from uncrypt_Queue;

BEGIN
    DBMS_OUTPUT.PUT_LINE(UpdateQueueRow(2, 2, null, null)); 
END;
/






BEGIN
    DBMS_OUTPUT.PUT_LINE(ExecuteQueueOperation(1,1)); -- �������� ��������� ����������
END;
/








DECLARE
    v_cursor SYS_REFCURSOR;          -- ���������� �������
    v_cash_id INT;                   -- ���������� ��� �������� �������������� �����
    v_balance NUMBER;                -- ���������� ��� �������� �������
    v_cash_name VARCHAR2(255);       -- ���������� ��� �������� �������� �����
    v_error_message VARCHAR2(255);   -- ���������� ��� �������� ��������� �� ������
BEGIN
    -- ����� ������� � ��������� ����������
    v_cursor := Get_Cash_Accounts(1, 2, v_error_message);  -- ������ ���������������

    -- �������� �� ������� ������
    IF v_error_message IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('������: ' || v_error_message);
    ELSE
        -- ��������� �������
        LOOP
            FETCH v_cursor INTO v_cash_id, v_balance, v_cash_name, ;
            EXIT WHEN v_cursor%NOTFOUND;  -- ����� �� �����, ���� ��� ������ �������

            -- ����� ������
            DBMS_OUTPUT.PUT_LINE('Cash ID: ' || v_cash_id || 
                                 ', Balance: ' || v_balance || 
                                 ', Cash Name: ' || v_cash_name);
        END LOOP;

        CLOSE v_cursor;  -- �������� ������� ����� ���������
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('�������������� ������: ' || SQLERRM);
END;
/



DECLARE
    v_cursor SYS_REFCURSOR;
    v_error_message VARCHAR2(4000);
    v_user_id NUMBER;
    v_login VARCHAR2(100);
    v_user_name VARCHAR2(100);
    v_last_name VARCHAR2(100);
    v_phone_number VARCHAR2(100);
    v_pasport VARCHAR2(100);
BEGIN
    -- ����� �������
    v_cursor := Get_User_Info(1, 2, v_error_message);

    -- �������� �� ������� ������
    IF v_error_message IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('������: ' || v_error_message);
    ELSE
        -- ��������� �������
        LOOP
            FETCH v_cursor INTO v_user_id, v_login, v_user_name, v_last_name, v_phone_number, v_pasport;
            EXIT WHEN v_cursor%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE('ID: ' || v_user_id || ', �����: ' || v_login || 
                                 ', ���: ' || v_user_name || ', �������: ' || v_last_name ||
                                 ', �������: ' || v_phone_number || ', �������: ' || v_pasport);
        END LOOP;
        CLOSE v_cursor;
    END IF;
END;
/



DECLARE
    v_cursor SYS_REFCURSOR;
    v_result VARCHAR2(4000);
    v_operation_id NUMBER;
    v_transactor NUMBER;
    v_cash_from VARCHAR2(100);
    v_cash_to VARCHAR2(100);
    v_operation VARCHAR2(100);
    v_amount VARCHAR2(100);
    v_operation_description VARCHAR2(1000);
BEGIN
    -- ����� ������� � �����������
    v_cursor := pdbAdmin.GetUncryptHistory(
        p_requester_id => 2,  -- ID ������������, ������� ����������� ������
        p_target_user_id => NULL, -- ID ������������, ��� ������� ���������� (NULL = ��� �������)
        result => v_result  -- ��������� � ����������
    );

    -- ����� ���������� �������
    DBMS_OUTPUT.PUT_LINE('Result: ' || v_result);

    -- �������� � ��������� �������
    IF v_cursor%ISOPEN THEN
        LOOP
            FETCH v_cursor INTO 
                v_operation_id, v_transactor, v_cash_from, v_cash_to,
                v_operation, v_amount, v_operation_description;
            EXIT WHEN v_cursor%NOTFOUND;

            -- ����� ����� �������
            DBMS_OUTPUT.PUT_LINE('Operation ID: ' || v_operation_id);
            DBMS_OUTPUT.PUT_LINE('Transactor: ' || v_transactor);
            DBMS_OUTPUT.PUT_LINE('Cash From: ' || v_cash_from);
            DBMS_OUTPUT.PUT_LINE('Cash To: ' || v_cash_to);
            DBMS_OUTPUT.PUT_LINE('Operation: ' || v_operation);
            DBMS_OUTPUT.PUT_LINE('Amount: ' || v_amount);
            DBMS_OUTPUT.PUT_LINE('Description: ' || v_operation_description);
            DBMS_OUTPUT.PUT_LINE('---------------------------------');
        END LOOP;
        CLOSE v_cursor;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
END;
/



DECLARE
    v_cursor SYS_REFCURSOR;
    v_error_msg VARCHAR2(4000);
    v_role_row Role%ROWTYPE;
BEGIN
    -- ����� �������
    v_cursor := GetRole(p_user_id => 2, p_error_msg => v_error_msg);

    IF v_error_msg IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('������: ' || v_error_msg);
    ELSE
        -- ������ ������ �� �������
        LOOP
            FETCH v_cursor INTO v_role_row;
            EXIT WHEN v_cursor%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE('Role_id: ' || v_role_row.Role_id || ', Name: ' || v_role_row.name || ', Role_level: ' || v_role_row.role_level);
        END LOOP;
    END IF;

    CLOSE v_cursor;
END;
/




DECLARE
    v_cursor SYS_REFCURSOR;            -- ���������� ��� �������� �������
    v_cash_id VARCHAR2(100);           -- ���������� ��� �������� Cash_id
    v_balance NUMBER;                  -- ���������� ��� �������� �������
    v_cash_name VARCHAR2(100);         -- ���������� ��� �������� ����� �����
    v_is_blocked NUMBER;               -- ���������� ��� �������� ������� ����������
    v_creation_date DATE;              -- ���������� ��� �������� ���� ��������
    v_currency_id VARCHAR2(4);         -- ���������� ��� �������� ID ������
    v_error_message VARCHAR2(4000);    -- ���������� ��� �������� ��������� �� ������
    v_requester_id INT := 1;           -- ������������� �������������� ������������
    v_target_user_id INT := 2;         -- ������������� ������������, ���������� � ������� ����� ��������
BEGIN
    -- ����� �������
    v_cursor := Get_Cash_Accounts(v_requester_id, v_target_user_id, v_error_message);

    -- �������� �� ������� ������
    IF v_error_message IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('������: ' || v_error_message);
    ELSE
        -- ���������� ������ �� �������
        LOOP
            FETCH v_cursor INTO v_cash_id, v_balance, v_cash_name, v_is_blocked, v_creation_date, v_currency_id;
            EXIT WHEN v_cursor%NOTFOUND;

            -- ����� ���������� � ������
            DBMS_OUTPUT.PUT_LINE('Cash ID: ' || v_cash_id);
            DBMS_OUTPUT.PUT_LINE('������: ' || v_balance);
            DBMS_OUTPUT.PUT_LINE('��� �����: ' || v_cash_name);
            DBMS_OUTPUT.PUT_LINE('������ ����������: ' || v_is_blocked);
            DBMS_OUTPUT.PUT_LINE('���� ��������: ' || v_creation_date);
            DBMS_OUTPUT.PUT_LINE('ID ������: ' || v_currency_id);
            DBMS_OUTPUT.PUT_LINE('------------------------');
        END LOOP;

        -- �������� �������
        CLOSE v_cursor;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('��������� ������: ' || SQLERRM);
        IF v_cursor%ISOPEN THEN
            CLOSE v_cursor;
        END IF;
END;
/
select * from cash_accounts;




DECLARE
    v_cursor SYS_REFCURSOR;
    v_error_message VARCHAR2(1000);
    v_cash_id VARCHAR2(100);
    v_cash_owner NUMBER;
    v_balance VARCHAR2(100);
    v_cash_name VARCHAR2(100);
    v_is_blocked NUMBER;
    v_creation_date DATE;
    v_currency_id VARCHAR2(4);
BEGIN
    -- ����� �������
    v_cursor := Get_Cash_Accounts_admin(1,  NULL, v_error_message);

    -- �������� �� ������� ��������� �� ������
    IF v_error_message IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('������: ' || v_error_message);
    ELSE
        -- ������� ���������
        DBMS_OUTPUT.PUT_LINE('Cash ID | Owner ID | Balance | Cash Name | Is Blocked | Creation Date | Currency ID');
        DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------------');

        -- ���� ��� ���������� ������ �� �������
        LOOP
            FETCH v_cursor INTO v_cash_id, v_cash_owner, v_balance, v_cash_name, v_is_blocked, v_creation_date, v_currency_id;
            EXIT WHEN v_cursor%NOTFOUND; -- ����� �� �����, ���� ��� ������ �������

            -- ����� ������
            DBMS_OUTPUT.PUT_LINE(v_cash_id || ' | ' || 
                                 v_cash_owner || ' | ' || 
                                 v_balance || ' | ' || 
                                 v_cash_name || ' | ' || 
                                 v_is_blocked || ' | ' || 
                                 TO_CHAR(v_creation_date, 'DD-MON-YYYY') || ' | ' || 
                                 v_currency_id);
        END LOOP;

        -- ��������� ������
        CLOSE v_cursor;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('��������� ������: ' || SQLERRM);
        -- ��������� ������ � ������ ������
        IF v_cursor%ISOPEN THEN
            CLOSE v_cursor;
        END IF;
END;

/

DECLARE
    v_users SYS_REFCURSOR;
    v_user_id NUMBER;
    v_user_role VARCHAR2(100);
    v_login VARCHAR2(100);
    v_user_name VARCHAR2(100);
    v_last_name VARCHAR2(100);
    v_phone_number VARCHAR2(100);
    v_pasport VARCHAR2(100);
BEGIN
    -- ��������� ������� � �������������� ��� ����������
    v_users := GetUsers(NULL);  -- �������� NULL ��� ��������� ���� �������������

    -- �������� �� ����������� �������
    LOOP
        FETCH v_users INTO v_user_id, v_user_role, v_login, v_user_name, v_last_name, v_phone_number, v_pasport;
        EXIT WHEN v_users%NOTFOUND;
        -- ��������� ������ (��������, ����� �� �����)
        DBMS_OUTPUT.PUT_LINE('User ID: ' || v_user_id || ', Name: ' || v_user_name);
    END LOOP;

    -- �������� �������
    CLOSE v_users;
END;
/