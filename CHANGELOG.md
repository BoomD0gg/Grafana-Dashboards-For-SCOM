# Changelog

## 0.6.0 - SCCM (Configuration Manager)

### Added
- **SCCM** (new folder `sccm`, six dashboards) reads the Configuration Manager **site database** through a read-only SQL data source: **Overview**, **Client Health**, **Software Updates**, **Deployments**, **Site Health** and **Hardware Inventory**. Most have a Collection drop-down. See [SCCM.md](docs/SCCM.md) for how to create the read-only login.
  - Tested on one primary site (version 5.00.9106) with 20 clients: client counts, activity and versions, site system roles, components, status messages, hardware inventory and update scan results were shown from real data.
  - **Not tested:** application, task sequence and software update deployments (the lab had none, so those panels show "No deployments"), failing or inactive clients (all were healthy), a central administration site, secondary sites and large estates.
- **SCCM Monitoring (SCOM)** (new folder `sccm-monitoring`, three dashboards) shows the Configuration Manager servers as SCOM sees them: **Overview**, **Performance** and **Server Detail**, built from the Microsoft Configuration Manager (MECM) management pack.
  - Tested on one primary site with the site database on a separate server (management pack 5.0.2303.2, SCOM 2022). With two services stopped on the site server, SCOM turned the management point, site server, site and hierarchy Critical about 18 minutes later and raised two alerts, and the dashboard showed it. Recovery took between 10 and 31 minutes. The service monitors for the two stopped services did not turn unhealthy themselves.
  - The management pack collects very little performance data by default (only the SMSExec process); most of its other performance collection rules are disabled, and several monitors are disabled and show as Not monitored.
- The two folders are independent: use either one or both.

### Changed
- **Sorting by severity.** Clicking the header of a Health, Status or Severity column used to sort alphabetically, which put Warning after Healthy. The queries now return a severity rank and the dashboards still show the word in its colour, so sorting a column puts Critical first, then Warning. This applies to every folder. The numbers and layout are unchanged. The timeline in Insights keeps its text Severity column, because it mixes alerts, health changes and events. The unhealthy monitors tables also now list Critical above Warning.

## 0.5.0 - Failover Clustering validated, and a Version column

### Changed
- **Failover Clustering is now validated** and moves out of the untested folder to `dashboards/failover-clustering`. It was rebuilt after being tested on a real two-node cluster: the earlier version looked for objects SCOM does not create and showed nothing. **Failover Clustering - Overview** and **Node Detail** (renamed from Server Detail) now show the cluster nodes (node, Cluster Service and agent heartbeat), the clusters, their cluster groups, unhealthy monitors and open alerts. The drop-down lists the cluster nodes. The performance panels were removed because the management pack collects no counters.
  - Tested on a two-node Windows Server 2025 cluster: a stopped cluster service turned the node red, raised alerts and was listed in the unhealthy monitors; a powered-off node turned its agent heartbeat red; a clustered role taken offline turned its cluster group and the cluster red and raised an alert.
  - A node that has been down for a while stops being listed by SCOM as a cluster Node object, so the node list also includes every host that runs a Cluster Service and a failed node stays visible.
  - Not tested: cluster disks and Cluster Shared Volumes, cluster resources and networks, several clusters, Windows Server 2016 and 2019 clusters.
  - Re-import the `failover-clustering` folder. If you imported the earlier version from `untested/failover-clustering`, delete that old folder afterwards.
- **A Version column on the home page.** Each folder now has a version: the release in which that folder last changed. When it goes up, re-import that folder.

## 0.4.0 - Insights, and Hyper-V performance dashboards

### Added
- **Hyper-V performance dashboards**, inside the existing `hyper-v` folder: **Hyper-V Performance - Host** (CPU, memory, storage, network, virtual switches and VM capacity) and **Hyper-V Performance - Virtual Machines** (a table of every VM, then CPU, memory, disk and network graphs for the VMs you pick; click a VM name to graph it). They read the counters of the **Hyper-V Performance (Community)** management pack and are empty without it. Tested on a lab host with two nearly idle VMs. See [HYPERV-PERFORMANCE.md](docs/HYPERV-PERFORMANCE.md).
- **Insights** (new folder `insights`, three dashboards), built from data SCOM already stores:
  - **Insights - Server Timeline**: what happened on one or several servers, in order (choose several when an incident crosses servers; a table shows which server went critical first): alerts raised and closed, monitor health changes, maintenance mode and Windows error events, with the first critical change, the monitors that are unhealthy now (oldest first), CPU and memory graphs marked with alerts and critical changes, and alerts in 5-minute buckets. A starting point for root cause analysis, not proof of cause.
  - **Insights - Capacity Planning**: disks with growth per day and days until a threshold you choose, a chart with a projected line, CPU and memory against high and low load limits (constrained or over-provisioned), SQL Server database growth, and the files of SCOM's own operational database and data warehouse (size, how full, whether they can grow).
  - **Insights - Trends**: alerts per day, monitors going critical per day, time to resolve alerts, CPU and memory against the previous period, the alerts raised most often and the monitors that change state most often (flapping).
  - Forecasts are a straight-line baseline and need at least 7 days of history. See [INSIGHTS.md](docs/INSIGHTS.md) for how they work, what was tested and what was not.
## 0.3.0 - SCOM architecture diagram

### Added
- **An architecture diagram of SCOM itself** at the top of **SCOM Infrastructure - Overview**: the management server, its operational database and data warehouse, its agents, resource pools and web console, with each box coloured by its health and each link coloured by the worst signal SCOM has for it, so a failed component or link stands out. Choose the management server in the new drop-down at the top. A box or line is grey where SCOM has no health data for it.
  - In lab testing a stopped agent turned the agents link amber and named the missing agent (SCOM takes about five minutes to notice, then raises a heartbeat alert), and a stopped Data Access service turned the management server to operational database link red. Not tested: a data warehouse link failure, a resource pool failure, several management servers and gateways.
  - A table under the diagram, **Management servers and resource pools**, lists every management server and gateway: health, how many agents report to it and how many are not reporting, its resource pools, and the state of its links to the operational database and the data warehouse.
  - The diagram has a fixed layout and draws the management server chosen in the drop-down. Gateways and the reporting server are not drawn. Only a single management server has been tested.
  - The database boxes show health only if the SQL Server on Windows management pack is imported.

### Documentation
- New guide [AVAILABILITY.md](docs/AVAILABILITY.md): what a stack is, how to create one in the SCOM console, the drop-downs, how the figures are calculated, what was tested and troubleshooting for the Availability dashboards.

## 0.2.1 - availability dashboards: no stacks no longer shows an error

### Fixed
- **The Availability dashboards showed an SQL error ("Incorrect syntax near ')'") when no stack was selected**, which happened when SCOM had no groups of your own yet. They now show "No stacks found". The Stacks and servers drop-downs always contain at least one entry.

### Changed
- **The Stacks drop-down now starts on "All groups and applications"** (it used to start on "My stacks"), so the dashboard shows data straight away. Choose "My stacks" to list only the groups and distributed applications you created yourself. With every group selected the page works through all the members of all of those groups, so on a large SCOM it can take a while to load (about 5 seconds in the 18-server test lab with 17 stacks); if it is slow, choose "My stacks" or select fewer stacks.
## 0.2.0 - Availability dashboards, and a fix to the availability percentage

### Added
- **Availability** (new folder `availability`, three dashboards): the availability of your **application stacks**, meaning SCOM groups and distributed applications.
  - **Availability - Overview**: every stack with its current state, availability against an SLA target you choose, downtime, and a daily status strip. Select a stack to open its detail.
  - **Availability - Stack Detail**: one stack with its availability and daily trend against the SLA line, the state of each component over time, the components table, outages and degradations, and the open alerts on the stack's servers.
  - **Availability - Monthly Report**: availability and downtime month by month against the SLA target.
  - Choose whether a stack is down when **any** component is down or only when **all** are (for redundant stacks), and whether planned maintenance is left out or counted as downtime.
  - A stack's availability is calculated from the hourly availability states SCOM keeps for its members, because SCOM does not store availability for plain groups.

### Fixed
- **The Availability % on the SCOM Enterprise Overview and the Server Drill-down was wrong, and too low, for any computer that had been unhealthy.** SCOM writes an hourly state row only for hours in which the state changed or was not healthy; healthy hours have no row at all. The old query divided the downtime by the number of rows instead of by the time that had actually passed, so a computer with some downtime could show a very low percentage (in the test lab, 6% where the real figure was 88%). The measured time is now the real elapsed time, from when the computer was first monitored (or the start of the time range) to now. If you used the old figures for reporting, re-check them. The Hours measured column now shows the real hours.

### Documentation
- **Updating** in [INSTALLATION.md](docs/INSTALLATION.md) now covers three ways to update: file provisioning (copy the new files), a PowerShell script that overwrites every dashboard in one go, and a manual import.

## 0.1.4 - zooming into older periods

### Fixed
- **Performance graphs are no longer empty when you zoom into a short period that is older than SCOM keeps raw samples.** Up to now a window of 48 hours or less always read the raw samples, which SCOM deletes after its retention period (a matter of days, set in your data warehouse grooming settings), so zooming from a long range into, say, a 3-hour window three weeks back showed "No data" even though hourly averages still existed. The graphs now fall back to the hourly averages when there are no raw samples in the window. Ranges with raw data behave exactly as before. This affects every performance graph in all technology packs.

### Notes
- Drag across any graph to zoom the whole dashboard to that period (standard Grafana). The shortest useful window is about 5 minutes, because SCOM stores samples every 5 minutes at best.
## 0.1.3 - alerts page, alert details, and alerts repeated in several languages

### Added
- **SCOM Alerts** (new, in `scom-core`): every alert on one page. Choose *Open*, *Closed* or *All*, filter by severity, server and alert name, and select an alert to see its details. Closed alerts are those resolved inside the time range (SCOM grooms closed alerts after its retention period, 7 days by default).
- **SCOM Alert Details** (new, in `scom-core`): what the SCOM console shows for one alert: summary (severity, priority, status, source, path, raised/modified/resolved times, owner, ticket, custom fields), the description with its parameters filled in, the **alert context** (every field that triggered the alert), the history (state changes, owner, comments) and the product knowledge from the management pack.
- **Every "Active alerts" table now links through to the alert details**: select an alert name on the overview, the server pages and every technology page.
- Because the new pages and the links live in `scom-core`, import `scom-core` first.

### Fixed
- **Alerts appeared several times, in different languages, and alert counts were too high.** Some management packs (for example the Virtual Machine Manager / PRO packs) ship translations of their alert text, and SCOM stores one row per language for every alert. The dashboards counted and listed every language row, so one alert showed up once per language (for example "PRO Hyper-V VM Memory Pressure" in English, Chinese, Czech, German, Spanish...) and the *Open alerts* tiles were multiplied. Every alert query now keeps exactly **one row per alert**, preferring English and falling back to the first available language.
- Monitor names in the *Unhealthy monitors* tables also prefer English now (they could appear in a random language).
- Tested by simulating three languages for every alert on the test SCOM: all 24 affected queries returned exactly the same result as on single-language data, while the old queries returned three times as many rows.
- To update: import the new `.json` files over the old ones (choose **Overwrite**), or replace the files if you use file provisioning.

## 0.1.2 - find the SCOM data sources automatically

### Changed
- **No more mapping at import.** Each dashboard now has two data source drop-downs (*SCOM Data Warehouse*, *SCOM Operational DB*) that list the SQL Server connections in Grafana and pick the right ones by name, instead of asking you to choose them at every import. If your connections are named differently, choose them from the drop-downs.
- Tested with connections that have different names and ids from the lab's own: all 28 dashboards imported with no mapping, chose them automatically and rendered with no errors.

### Added
- Import everything at once with Grafana file provisioning: [docs/INSTALLATION.md](docs/INSTALLATION.md) and `deploy/dashboards-provisioning/scom-dashboards.yaml.example` (tested on Windows, Grafana 13.3: 28 dashboards in 12 folders).
- To update from 0.1.1: import the new files over the old ones (choose **Overwrite**).

## 0.1.1 - chart gaps

### Added
- A page for every validated dashboard folder (`dashboards/<folder>/README.md`) with a screenshot of each dashboard, the panels it contains, the management packs it needs and its known limits. Screenshots come from a small test lab with server, domain and database names masked.

### Fixed
- **Performance charts showed gaps where nothing was missing.** Many SCOM performance rules use *optimized collection*: a sample is stored only when the value changes meaningfully, and the last value is stored again at least once an hour. Quiet counters (for example disk latency) therefore have no new samples for up to about 55 minutes, and the charts drew holes. Charts now connect gaps of up to 65 minutes. A genuine outage longer than that still shows as a break.
- To update, import the new `.json` over the old one into the same folder and choose **Overwrite**.

## 0.1.0 — first release

### Dashboards
- **Validated on SCOM 2022 (24 dashboards):** SCOM Enterprise Overview, Server Drill-down and Platform Status; Windows Server; Active Directory; SQL Server; Exchange; Hyper-V; IIS; DNS Server; DHCP Server; File Services; SCOM Infrastructure.
- **Untested (4 dashboards):** Remote Access and Failover Clustering, in `dashboards/untested/`. No matching servers were available to test them.

### Setup files
- `deploy/sql/Grant-ReadOnly.sql` — read-only SQL access for Grafana.
- `deploy/grafana-provisioning/` — example data source provisioning files (Windows authentication, tested; SQL authentication, not tested).

### Known limits
See [docs/PACKS.md](docs/PACKS.md) and [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md). In short: SCOM 2019 and 2025 are not tested; File Services fault detection was not demonstrated; Exchange was tested on a single server; Remote Access and Failover Clustering are untested.
