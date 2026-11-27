# SCCM (Configuration Manager) dashboards

Two separate folders cover Configuration Manager. You can use either one or both.

| Folder | Reads | What it is for |
|---|---|---|
| `dashboards/sccm` (**SCCM**) | the Configuration Manager **site database** | Everything about the estate Configuration Manager manages: clients and their health, site systems and components, software update compliance, application and task sequence deployments, hardware inventory. |
| `dashboards/sccm-monitoring` (**SCCM Monitoring (SCOM)**) | **SCOM** (the MECM management pack) | How the Configuration Manager servers themselves are doing: roles, server components, monitors, alerts, and server performance. |

The two do not depend on each other. They answer different questions: SCOM tells you a server or service is unhealthy, the site database tells you what that means for the clients.

## SCCM (site database)

### What you need

- A **read-only SQL Server data source** in Grafana pointing at the site database (`CM_<site code>`). The dashboards find it by name if it contains "SCCM", "ConfigMgr" or "Configuration Manager"; otherwise pick it in the **SCCM Database** drop-down at the top left of each dashboard.
- Nothing needs importing in SCOM.

### Create the read-only login

Create a login for Grafana and give it read access to the site database only. With Windows authentication (the Grafana server's computer account), on the SQL Server that hosts the site database:

```sql
CREATE LOGIN [DOMAIN\GRAFANA-SERVER$] FROM WINDOWS WITH DEFAULT_DATABASE = [CM_ABC];
USE [CM_ABC];
CREATE USER [DOMAIN\GRAFANA-SERVER$] FOR LOGIN [DOMAIN\GRAFANA-SERVER$];
ALTER ROLE db_datareader ADD MEMBER [DOMAIN\GRAFANA-SERVER$];
```

Replace `DOMAIN\GRAFANA-SERVER$` with the account Grafana runs as and `CM_ABC` with your site database. A SQL login with the same two grants works too. Every query in the pack is a single `SELECT` against the `v_` views; nothing is written.

In Grafana add a **Microsoft SQL Server** data source with that host, the site database and the authentication you chose. If SQL Server's certificate is not trusted by Grafana, fix the certificate rather than turning verification off.

### The dashboards

| Dashboard | What it shows |
|---|---|
| **SCCM - Overview** | Devices, clients, active and inactive clients, site systems and components not healthy, the site, every site system role with its status and free space, clients by client version and by operating system. |
| **SCCM - Client Health** | Every device of a collection with its health, whether its client is active, the last health check, and when it last sent a policy request, heartbeat, hardware inventory and software inventory. Worst first. |
| **SCCM - Software Updates** | Updates in the catalog, updates needed and devices missing them, needed updates by severity, update deployments with compliance, the devices missing the most updates, and the latest updates released. |
| **SCCM - Deployments** | Application, program, script and task sequence deployments with succeeded, in progress and failed counts, and task sequence steps that failed. |
| **SCCM - Site Health** | Site systems and components in trouble, error and warning status messages per hour, the components that produced the most errors, and the latest error messages. |
| **SCCM - Hardware Inventory** | Devices by manufacturer, model and operating system, RAM, fixed disks with the least free space, and when each device last sent a hardware inventory. |

Most dashboards have a **Collection** drop-down at the top. It lists the device collections of the site; the numbers and tables cover the devices in the one you choose.

### What was tested

Tested on one primary site (version 5.00.9106) with its database on a separate SQL Server and 20 Windows Server 2025 clients:

- Every query runs through Grafana against the real site database, and every dashboard opens without panel errors.
- The client count matches the 20 clients that were installed, and all of them show as active with one client version. The site, its system roles and its components are listed with the status the site reports. Hardware inventory (models, memory, disks) and software update scan results (needed updates by severity, devices missing updates) were present once the clients had run their cycles, and are shown. The numbers were read from the database views and not compared one by one with the Configuration Manager console.

### What was not tested

- **Application, program, script, task sequence and software update deployments.** The lab had none, so those panels open and show "No deployments" or "No update deployments". Their layout follows the views' columns but no real deployment has been shown.
- **Failing clients.** All lab clients were healthy and active, so Critical and Warning rows in Client Health have not been seen with real data.
- A central administration site or secondary sites, internet-based and workgroup clients, large estates and query speed on a large database.
- Times in the status message panels follow the SQL Server clock; the lab ran on UTC.
- Some columns stay empty until the client health summary runs after a client is first installed (for example "Last policy request"); the hardware inventory date falls back to the inventory itself.

## SCCM Monitoring (SCOM)

### What you need

- The **Microsoft Configuration Manager (MCM/MECM) management pack** (Kevin Holman's MECM MP, tested at 5.0.2303.2) imported in SCOM, with the Configuration Manager servers monitored by SCOM agents. Allow time after the import for SCOM to discover the site.
- The Windows Server operating system management pack for the server processor, memory and disk panels.
- The two SCOM data sources used by the other folders (data warehouse and operational database).

### The dashboards

| Dashboard | What it shows |
|---|---|
| **SCCM Monitoring - Overview** | Servers, roles and server components not healthy, agents not healthy, open alerts; a table of the Configuration Manager servers (click one for detail); the site and its roles; the server components; unhealthy monitors; open alerts. |
| **SCCM Monitoring - Performance** | Processor time, available memory and disk free space of the selected servers, and the processor time and memory of the site server process (SMSExec). |
| **SCCM Monitoring - Server Detail** | One server: its roles, components, processor and memory, monitors and alerts. |

### What was tested

Tested on one primary site with the site database on a separate server, on SCOM 2022 with MECM management pack 5.0.2303.2:

- Every query runs against real SCOM data without error and every dashboard opens without panel errors.
- The roles (site server, management point, distribution point, software update point, service connection point, SQL Server, SMS Provider, content drive) and the 20 server components are listed with their health.
- A fault was introduced on the site server: the SMS VSS writer service and the client service (CcmExec) were stopped and kept from restarting. About 18 minutes later SCOM turned the management point Critical (role availability and HTTP request monitors), which rolled up to the site server, the primary site and the hierarchy, and raised two Critical alerts. The Overview dashboard showed the server as Critical, two roles not healthy, two open alerts, and the two monitors in the unhealthy monitors table. After the services were restarted SCOM took between 10 and 31 minutes to show the management point healthy again, although it was answering requests normally much earlier. The management pack's monitors need several consecutive samples, so expect delays of this size both ways.

### What was not tested

- **The management pack collects very little performance data by default.** Only the SMSExec processor and memory counters are on; the rest of the management pack's performance collection rules (message queues, inbox backlogs, the Configuration Manager counters) are disabled. The dashboards show them only if you enable those rules, and no override was made in the lab.
- Several of the management pack's monitors are disabled by default (for example the IIS and WSUS service monitors on the site roles) and show as **Not monitored**.
- A central administration site, secondary sites, several management points or distribution points, and distribution points on their own servers.
- The service monitors for the SMS VSS writer and for the client service did not turn unhealthy during the fault test above (about 20 minutes); only the management point checks did. A stopped service is therefore not guaranteed to show as a monitor of its own.
- Configuration Manager component errors that the management pack does not monitor (such as errors in the status messages) do not appear in SCOM. The **SCCM - Site Health** dashboard shows those from the site database.
