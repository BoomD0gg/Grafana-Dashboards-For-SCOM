/*
  Check that the Grafana account has read-only access to the two SCOM databases.
  Run on the SCOM SQL Server as a sysadmin AFTER Grant-ReadOnly.sql.
  Replace {{GRAFANA_PRINCIPAL}} with the same account you used there (Find and Replace -> Replace All).
  Expected: sysadmin = 0, a row count for each database, and "write correctly denied" twice.
*/
SELECT IS_SRVROLEMEMBER('sysadmin', N'{{GRAFANA_PRINCIPAL}}') AS is_sysadmin_should_be_0;
GO
USE [OperationsManager];
EXECUTE AS USER = N'{{GRAFANA_PRINCIPAL}}';
SELECT 'OperationsManager read' AS test, COUNT(*) AS rows_visible FROM dbo.ManagedEntityGenericView;
BEGIN TRY
  CREATE TABLE dbo.zz_write_test (i int);
  PRINT 'PROBLEM: this account could write to OperationsManager';
  DROP TABLE dbo.zz_write_test;
END TRY
BEGIN CATCH
  PRINT 'OperationsManager write correctly denied: ' + ERROR_MESSAGE();
END CATCH
REVERT;
GO
USE [OperationsManagerDW];
EXECUTE AS USER = N'{{GRAFANA_PRINCIPAL}}';
SELECT 'OperationsManagerDW read' AS test, COUNT(*) AS rows_visible FROM dbo.vManagedEntity;
BEGIN TRY
  CREATE TABLE dbo.zz_write_test (i int);
  PRINT 'PROBLEM: this account could write to OperationsManagerDW';
  DROP TABLE dbo.zz_write_test;
END TRY
BEGIN CATCH
  PRINT 'OperationsManagerDW write correctly denied: ' + ERROR_MESSAGE();
END CATCH
REVERT;
GO
/*
  If you get  Msg 916 "The server principal ... is not able to access the database ... under the current security context":
  the account's CONNECT permission in that database is denied or missing. Run this in BOTH databases and re-run this check:
      USE [OperationsManager];   GRANT CONNECT TO [{{GRAFANA_PRINCIPAL}}];
      USE [OperationsManagerDW]; GRANT CONNECT TO [{{GRAFANA_PRINCIPAL}}];
  If you get  Msg 15517 "Cannot execute as the database principal because the principal does not exist": run Grant-ReadOnly.sql first.
*/