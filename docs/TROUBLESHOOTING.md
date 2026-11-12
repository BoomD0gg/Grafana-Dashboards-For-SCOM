# Troubleshooting

## Panels say "Datasource ... was not found", or nothing loads and the two drop-downs at the top left are empty
The dashboard could not find a SQL Server connection for the Data Warehouse or the Operational database.
- Make sure you have **two Microsoft SQL Server data sources**, and that *Save & test* succeeds on both.
- Dashboards choose them by name: the Data Warehouse connection should contain **Warehouse** or **DW**; the Operational one **Operational**, **Operations** or **SCOM** (not Warehouse/DW). Otherwise open the **SCOM Data Warehouse** and **SCOM Operational DB** drop-downs at the top left and choose the right connection yourself.
- If the message names a fixed id such as `scom-om`, the file did not come from this repository's `dashboards/` folder. Import the files from there instead.

## SQL error 916 "The server principal ... is not able to access the database ... under the current security context"
The Grafana account exists, but its **CONNECT** permission in that database is denied or missing. In both `OperationsManager` and `OperationsManagerDW` run `GRANT CONNECT TO [<your account>];` (the grant script now does this), then run [`Verify-ReadOnly.sql`](../deploy/sql/Verify-ReadOnly.sql) again. Error 15517 ("principal does not exist") means the grant script has not been run yet.

## The Grafana service shows "Paused", or the page does not load, after I changed its Log On account
- **Give it a minute or two.** The first start under a new account takes noticeably longer than usual while Grafana sets up its files and plugins. "Connection refused" in the browser during that time is normal. Keep refreshing for a couple of minutes before assuming it has failed.
- **"Paused" means Grafana crashed at startup.** Grafana's Windows service is wrapped by a helper (NSSM); if Grafana exits straight away it stops retrying and shows **Paused**, and *Resume* fails with "Windows could not resume the service". The usual reason is that the new account cannot write to Grafana's `data` folder (a default install gives ordinary accounts read-only access there). Grant it write access as shown in [INSTALLATION.md](INSTALLATION.md#windows-authentication-run-grafana-as-the-sql-account), stop the stuck service (`Stop-Service Grafana -Force`, then end any leftover `grafana` / `nssm` processes) and start it again.
- **Still failing?** Read the last lines of `...\grafana\data\log\grafana.log` for the reason, and the service wrapper's messages in *Event Viewer → Windows Logs → Application* (source `nssm`). A line such as "Failed to write output for service Grafana to file grafana-service.log … The handle is invalid" only means the wrapper cannot write its own console log (it tries to put it in the Grafana program folder). It does not stop Grafana. If you want that log, point it at the data folder: `Set-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\Grafana\Parameters -Name AppStdout -Value 'C:\Program Files\GrafanaLabs\grafana\data\log\grafana-service.log'` (same for `AppStderr`) and restart the service.
## Save & test says "Unable to load krb5 config ... /etc/krb5.conf: The system cannot find the path specified"
The data source's **Authentication** is set to one of the Kerberos options ("Windows AD: Username + password", "Keytab", "Credential cache"). Those are for Grafana on Linux. On Windows choose **Windows Authentication** (Grafana then connects as the account its service runs as) or **SQL Server Authentication**, then click **Save & test** again.

## Panels show a red corner / error
Hover the corner to read the message.
- **Login failed / permission denied:** the Grafana SQL account lacks read access. Re-check [`Grant-ReadOnly.sql`](../deploy/sql/Grant-ReadOnly.sql) on **both** databases.
- **Cannot connect / TLS error:** check the SQL host, port 1433, firewall, and that the SQL Server certificate is trusted by the Grafana host.
- **Invalid object name:** the data source points at the wrong database. The "Data Warehouse" data source must use `OperationsManagerDW` and the "Operational DB" one `OperationsManager`.

## Panels are empty ("No data")
- The technology's **management pack is not imported**, or was imported only a few minutes ago. Allow time for discovery.
- **SQL Server or Exchange:** enable **agent proxy** on those servers' agents (see [INSTALLATION.md](INSTALLATION.md), step 1), then restart the agent service so discovery runs again.
- The **Server** (or Instance / Host) drop-down at the top has nothing selected. Pick **All** or a server.
- The time range is too short for the data. Performance charts need collected samples; try *Last 6 hours* or longer.
- No performance counters for that technology are collected in your SCOM (some management packs collect state only).

## I imported the dashboards but the Dashboards page doesn't list the folders
Grafana updates its search index in the background; new folders can take a few minutes to appear. Open a dashboard directly or use the **Technology packs** menu at the top left, then refresh the page later.

## The "Technology packs" menu shows nothing, or links are dead
The menu lists the dashboards you have imported. Import the others you need. Server links go to the matching detail dashboard, which must also be imported.

## A health state looks wrong
The dashboards show what SCOM records. Role health lags its monitors by a few minutes, and some monitors take 30–45 minutes to change (they sample every 15 minutes and need several samples). Compare with the SCOM console's Health Explorer for the same object.

## Server names look odd or duplicated
Some management packs create more than one object per server (for example several health sets or counters). The detail dashboards group them by server; the overview tables list each object.

## Still stuck?
[Open an issue](../../../issues/new/choose) with the dashboard name, Grafana and SCOM versions, and the panel's error text. Remove server names, domain names and addresses first.
