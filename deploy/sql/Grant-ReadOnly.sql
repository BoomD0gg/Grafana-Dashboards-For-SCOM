/*
  Read-only access for Grafana to the two SCOM databases.
  Run on the SCOM SQL Server as a sysadmin. Review before running.

  ONE thing to change: replace {{GRAFANA_PRINCIPAL}} with the account Grafana uses to connect to SQL Server.
  It appears many times in this script and is always the same value, so use Find and Replace (Ctrl+H) -> Replace All.
  It is NOT your personal username. Examples:
    Grafana on a domain-joined Windows server, running as a normal service (most common):
        the Grafana server's COMPUTER account, with a trailing $   ->   CONTOSO\GRAFANA01$
    Grafana running as a dedicated domain account                   ->   CONTOSO\svc-grafana-scom
    Grafana on Linux / not domain-joined (SQL authentication)       ->   a SQL login name such as grafana_scom_ro
        For SQL authentication: create the login with a strong password first, outside this script, and delete the
        CREATE LOGIN line below (it creates a Windows login).

  The account gets db_datareader and is explicitly denied writes, on OperationsManager and OperationsManagerDW only.
  It gets nothing else (no server roles, no other databases).
*/
USE [master];
IF SUSER_ID(N'{{GRAFANA_PRINCIPAL}}') IS NULL CREATE LOGIN [{{GRAFANA_PRINCIPAL}}] FROM WINDOWS;   -- SQL auth: create the SQL login instead
GO
USE [OperationsManagerDW];
IF USER_ID(N'{{GRAFANA_PRINCIPAL}}') IS NULL CREATE USER [{{GRAFANA_PRINCIPAL}}] FOR LOGIN [{{GRAFANA_PRINCIPAL}}];
GRANT CONNECT TO [{{GRAFANA_PRINCIPAL}}];
ALTER ROLE db_datareader ADD MEMBER [{{GRAFANA_PRINCIPAL}}];
ALTER ROLE db_denydatawriter ADD MEMBER [{{GRAFANA_PRINCIPAL}}];
GO
USE [OperationsManager];
IF USER_ID(N'{{GRAFANA_PRINCIPAL}}') IS NULL CREATE USER [{{GRAFANA_PRINCIPAL}}] FOR LOGIN [{{GRAFANA_PRINCIPAL}}];
GRANT CONNECT TO [{{GRAFANA_PRINCIPAL}}];
ALTER ROLE db_datareader ADD MEMBER [{{GRAFANA_PRINCIPAL}}];
ALTER ROLE db_denydatawriter ADD MEMBER [{{GRAFANA_PRINCIPAL}}];
GO
