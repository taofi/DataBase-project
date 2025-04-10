1. Установка oracle на docker 
docker run -d -e ORACLE_PWD="root" --name testdb -p 5500:5500  -p 8080:8080 -p 1521:1521 container-registry.oracle.com/database/express:21.3.0-xe

Данные для подключения 
username sys
password root
hostname localhost
port 1521
sid XE

2. создание pdb 
CREATE PLUGGABLE DATABASE PDB
  ADMIN USER pdbAdmin IDENTIFIED BY oracle
  ROLES = (dba)
  DEFAULT TABLESPACE opdbtblsp
    DATAFILE '/opt/oracle/oradata/XE/PDB/PDB.dbf' SIZE 250M AUTOEXTEND ON
  FILE_NAME_CONVERT = ('/opt/oracle/oradata/XE/pdbseed/',
                   '/opt/oracle/oradata/XE/PDB/')
  STORAGE (MAXSIZE 2G)
  PATH_PREFIX = '/opt/oracle/oradata/XE/PDB/';
  

  ALTER PLUGGABLE DATABASE PDB OPEN;
  
  ALTER PLUGGABLE DATABASE PDB SAVE STATE;
GRANT EXECUTE ON SYS.DBMS_CRYPTO TO PUBLIC;

3. настройка 
подключение к Pdb как sys
данные для подключения
username sys
password root
hostname localhost
port 1521
service name pdb



