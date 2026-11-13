# Dashboards and management packs

All dashboards are version 0.1.4. "Validated" means tested in a lab against real SCOM 2022 data (see [HOW-IT-WORKS.md](HOW-IT-WORKS.md)). Each technology needs its Microsoft management pack imported in SCOM.

| Folder | Dashboards | Management packs to import | Status |
|---|---|---|---|
| `dashboards/scom-core` | SCOM Enterprise Overview, Server Drill-down, Platform Status, Alerts, Alert Details | none (Windows Server MP recommended) | Validated |
| `dashboards/windows-server` | Windows Server - Fleet, Detail | Microsoft.Windows.Server.Library, Server.2016.Monitoring | Validated |
| `dashboards/active-directory` | Active Directory - Overview, DC Detail | Microsoft.Windows.Server.AD.Class.Library, AD.2016.Monitoring | Validated |
| `dashboards/sql-server` | SQL Server - Overview, Instance Detail | Microsoft.SQLServer.Core.Library, Windows.Discovery, Windows.Monitoring | Validated |
| `dashboards/scom-infrastructure` | SCOM Infrastructure - Overview, Agents, Alert Noise | Microsoft.SystemCenter.Library, OperationsManager.Library (built in) | Validated |
| `dashboards/hyper-v` | Hyper-V - Overview, Host Detail | Microsoft.Windows.HyperV.Library, Discovery, Monitoring | Validated (counter panels untested, see below) |
| `dashboards/dns-server` | DNS - Overview, Server Detail | Microsoft.Windows.DNSServer.2016 | Validated |
| `dashboards/dhcp-server` | DHCP - Overview, Server Detail | Microsoft.Windows.DHCPServer.Library, DHCPServer.2016 | Validated |
| `dashboards/iis` | IIS - Overview, Server Detail | Microsoft.Windows.InternetInformationServices.2016 | Validated |
| `dashboards/file-services` | File Services - Overview, Server Detail | Microsoft.Windows.FileServices.2016, FileServer.DFSR.2016 | Validated, fault detection not demonstrated |
| `dashboards/exchange` | Exchange - Overview, Server Detail | Microsoft.Exchange.15 (SC MP for Exchange 2013 and above) | Validated on one Exchange 2019 server |
| `dashboards/untested/remote-access` | Remote Access - Overview, Server Detail | Microsoft.Windows.RemoteAccess.10.0.Monitoring | **Untested** |
| `dashboards/untested/failover-clustering` | Failover Clustering - Overview, Server Detail | Microsoft.Windows.Cluster.Library, Cluster.Management.Monitoring | **Untested** |

## What was checked for the validated dashboards

- Every query runs against real SCOM data without error.
- Object counts and names compared with the servers themselves (zones, scopes, websites, application pools, VMs, databases, health sets and so on), plus service state against role health.
- A fault was introduced (a service or agent stopped on a lab server) and the dashboard shown to raise the matching monitor, role health and alert, then recover. Done for Windows Server (CPU load), Active Directory, SQL Server, SCOM Infrastructure, Hyper-V, DNS, DHCP, IIS and Exchange.
- Every dashboard renders in a real browser without panel errors.

## Known limits

- **File Services:** stopping the Server (LanmanServer) service on a lab server (tried for 10 and again for 55 minutes) did not change the state of SCOM's "Server Service Status" monitor, so SCOM raised nothing and fault detection was not demonstrated. DFS counters exist only on a DFS Replication member. One role showed Critical because of a firewall monitor that was not investigated; the dashboard shows what SCOM reports.
- **Hyper-V:** the performance-counter panels stayed untested until SCOM collected data in the lab.
- **Exchange:** one server, one database, no DAG. SCOM's Exchange service monitor samples every 15 minutes and needs 3 samples, so a stopped service takes 30–45 minutes to show. The mailbox database copy is listed but SCOM gives it no health state in the lab ("Not monitored"). The dashboard lists 15 more health sets than the server's own `Get-HealthReport`; the reason was not established.
- **DNS / DHCP:** one server each. DHCP failover, IPv6 scopes and DNSSEC were not exercised. DHCP scope utilisation is not charted because the management pack exposes it only as monitor state.
- **Remote Access / Failover Clustering:** the lab had no Remote Access servers or clusters. The queries are valid and the dashboards open, but which objects they pick up, and every number, is **unverified**. The class choices come from the management pack's published class names, not from discovered objects. Please report how they work for you ([issue template](../../../issues/new/choose)).
- Management packs not covered: FSRM, Dedup, iSCSI, NFS, Work Folders, Remote Desktop Services, older DNS/IIS versions.
- Alert panels were only exercised with the alerts raised by the fault tests.
- Only SCOM 2022 was validated. SCOM 2019 and 2025 are expected to work but are untested ([COMPATIBILITY.md](COMPATIBILITY.md)).
