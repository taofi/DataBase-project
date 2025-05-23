
CREATE ROLE user_pdb_role;
GRANT CREATE SESSION TO user_pdb_role;
CREATE ROLE admin_pdb_role;

GRANT user_pdb_role TO Client_user;
GRANT user_pdb_role TO Admin_user;
GRANT admin_pdb_role TO Admin_user;


GRANT EXECUTE ON pdbAdmin.Register_User TO user_pdb_role;
GRANT EXECUTE ON pdbAdmin.Authorize_User TO user_pdb_role;
GRANT EXECUTE ON pdbAdmin.UpdateUser TO user_pdb_role;
GRANT EXECUTE ON pdbAdmin.DeleteUser TO user_pdb_role;
GRANT EXECUTE ON pdbAdmin.CreateCashAccount TO user_pdb_role;
GRANT EXECUTE ON pdbAdmin.ProcessTransfer TO user_pdb_role;
GRANT EXECUTE ON pdbAdmin.Get_User_Info TO user_pdb_role;
GRANT EXECUTE ON pdbAdmin.Get_Cash_Accounts TO user_pdb_role;
GRANT EXECUTE ON pdbAdmin.GetUncryptHistory TO user_pdb_role;
GRANT EXECUTE ON pdbAdmin.GetUserRoleLevel TO user_pdb_role;
GRANT EXECUTE ON pdbAdmin.DeleteUser TO user_pdb_role;
GRANT EXECUTE ON pdbAdmin.DeleteCashAccount TO user_pdb_role;
GRANT EXECUTE ON pdbAdmin.Get_Currencies TO user_pdb_role;
GRANT EXECUTE ON pdbAdmin.UpdateInfoCashAccount TO user_pdb_role;
GRANT EXECUTE ON pdbAdmin.Block_Cash_Account TO user_pdb_role;



GRANT EXECUTE ON pdbAdmin.UPDATEACCOUNTBALANCE TO admin_pdb_role;
GRANT EXECUTE ON pdbAdmin.UpdateQueueRow TO admin_pdb_role;
GRANT EXECUTE ON pdbAdmin.ExecuteQueueOperation TO admin_pdb_role;
GRANT EXECUTE ON pdbAdmin.GetUncryptQueue TO admin_pdb_role;
GRANT EXECUTE ON pdbAdmin.DeleteQueueRow TO admin_pdb_role;
GRANT EXECUTE ON pdbAdmin.Get_Cash_Accounts_admin TO admin_pdb_role;
GRANT EXECUTE ON pdbAdmin.Unblock_Cash_Account TO admin_pdb_role;

