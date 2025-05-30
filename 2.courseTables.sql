-- �������� ������� Role
drop table Role;
drop table History;
drop table Queue;
drop table Cash_accounts;
drop table Users;


CREATE TABLE Role (
    Role_id NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    name  VARCHAR2(100) NOT NULL,
    role_level NUMBER NOT NULL
);


-- �������� ������� Users

CREATE TABLE Users (
    User_id NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    User_role NUMBER REFERENCES Role(Role_id),
    login VARCHAR2(100) UNIQUE NOT NULL,
    pass VARCHAR2(255) NOT NULL,
    user_name VARCHAR2(100) NOT NULL,
    last_name VARCHAR2(100) NOT NULL,
    phone_number VARCHAR2(100) UNIQUE NOT NULL,
    pasport VARCHAR2(100) UNIQUE NOT NULL
);

--�������� ������� Currencies
CREATE TABLE Currencies (
    Currency_id VARCHAR2(4) PRIMARY KEY,  -- ID ������, �������� 4 �������
    Currency_name VARCHAR2(100) NOT NULL,  -- �������� ������
    Exchange_rate NUMBER(10, 4) NOT NULL   -- ���� ������, ����� ���� �������
);
-- �������� ������� Cash_accounts

CREATE TABLE Cash_accounts (
    Cash_id VARCHAR2(100) PRIMARY KEY,
    Cash_owner NUMBER REFERENCES Users(User_id) NOT NULL,
    balance VARCHAR2(100) NOT NULL,
    Cash_name VARCHAR2(100) NOT NULL,
    IsBlocked NUMBER(1) DEFAULT 0,
    Creation_date DATE DEFAULT TRUNC(SYSDATE), 
    Currency_id VARCHAR2(4) REFERENCES Currencies(Currency_id) 
);




-- �������� ������� History


CREATE TABLE History (
    Operation_id NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    Transactor NUMBER REFERENCES Users(User_id),
    cash_from VARCHAR2(100) REFERENCES Cash_accounts(Cash_id), 
    cash_to VARCHAR2(100) REFERENCES Cash_accounts(Cash_id),    
    operation VARCHAR2(100),
    amount VARCHAR2(100),
    operation_description VARCHAR2(1000)
);

-- �������� ������� Queue

CREATE TABLE Queue (
    Operation_id NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    Transactor NUMBER REFERENCES Users(User_id),
    cash_from VARCHAR2(100) REFERENCES Cash_accounts(Cash_id), 
    cash_to VARCHAR2(100) REFERENCES Cash_accounts(Cash_id),    
    operation VARCHAR2(100),
    amount VARCHAR2(100),
    operation_description VARCHAR2(1000)
);



