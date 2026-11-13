# Installation

You need about 20 minutes and four things: a read-only SQL account, two Grafana data sources, the dashboards, and the Microsoft management packs for the technologies you want.

## 1. Import the management packs into SCOM

Each technology dashboard reads data produced by Microsoft's management pack for that technology ([PACKS.md](PACKS.md) lists them). Without the management pack the dashboard opens but is empty. The enterprise overview (`scom-core`) needs none.

Two things to know:

- **SQL Server and Exchange** need **agent proxy** enabled on the SCOM agents of those servers, otherwise SCOM does not discover their objects. In the SCOM console: *Administration → Agent Managed → (agent) → Properties → Security → Allow this agent to act as a proxy*.
- After importing a management pack, allow some minutes (sometimes longer) for discovery and the first performance samples.

## 2. Create read-only SQL access

Edit [`deploy/sql/Grant-ReadOnly.sql`](../deploy/sql/Grant-ReadOnly.sql) (one placeholder: the account Grafana will use) and run it on the SCOM SQL Server as a sysadmin. It gives `db_datareader` on `OperationsManager` and `OperationsManagerDW`, explicitly denies writes, and grants nothing else. Then run [`deploy/sql/Verify-ReadOnly.sql`](../deploy/sql/Verify-ReadOnly.sql) to confirm the account can read both databases and cannot write.

- Grafana on a **domain-joined Windows host**: use Windows authentication with the Grafana host's computer account or a dedicated service account. This is the method that was tested.
- Grafana on **Linux or not domain-joined**: use a SQL login. This works with the same script but was **not tested**.

Use a SQL Server certificate that your Grafana host trusts, and keep encryption on. Don't switch certificate checking off.

### Windows authentication: run Grafana as the SQL account

With Windows authentication Grafana connects to SQL Server as **whoever the Grafana Windows service runs as**. There are two ways to set that up:

- **Computer account (simplest):** leave the Grafana service on its default (*Local System*). When SQL Server is on a **different** server, Local System shows up to SQL Server as the Grafana server's computer account (`DOMAIN\GRAFANASERVER$`). Use that name in the grant script. Nothing else to do.
- **Dedicated service account (recommended if SQL Server is on the same server as Grafana, or for tighter control):** create a domain account such as `DOMAIN\svc-grafana-ro`, use it in the grant script, and make the Grafana service run as it:
  1. *Services → Grafana → Properties → Log On → This account*, enter the account and its password.
  2. Give the account write access to Grafana's data folder and read access to its configuration. In an **elevated PowerShell** (default install path shown; change it if yours differs):
     ```powershell
     $acct = 'DOMAIN\svc-grafana-ro'
     $g    = 'C:\Program Files\GrafanaLabs\grafana'
     icacls "$g\data" /grant "${acct}:(OI)(CI)M" /T
     icacls "$g\conf" /grant "${acct}:(OI)(CI)RX" /T
     Stop-Service Grafana -Force -ErrorAction SilentlyContinue
     Get-Process grafana, nssm -ErrorAction SilentlyContinue | Stop-Process -Force
     Start-Service Grafana
     ```
  3. Check `Get-Service Grafana` says **Running**, then open `http://localhost:3000`.

  Set the account's password to never expire (or use a group-managed service account) and deny it interactive and Remote Desktop logon in group policy. After a Grafana upgrade, check that the service still runs as this account.
## 3. Add the two Grafana data sources

In Grafana: *Connections → Data sources → Add data source → Microsoft SQL Server*. Create **two**, using the same SQL host and authentication from step 2:

| Suggested name | Database |
|---|---|
| **SCOM Data Warehouse** | `OperationsManagerDW` |
| **SCOM Operational DB** | `OperationsManager` |

In the **Authentication** drop-down choose **Windows Authentication** (Grafana on Windows; it connects as the account the Grafana service runs as, see above) or **SQL Server Authentication** (a SQL login). Do **not** choose the "Windows AD: ..." options: those are Kerberos methods for Grafana on Linux and fail on Windows with "unable to load krb5 config". Click **Save & test** on each.

**The names matter a little.** Every dashboard has two drop-downs at the top left, *SCOM Data Warehouse* and *SCOM Operational DB*, that list your SQL Server connections and **choose the right one automatically by name**:

- the Data Warehouse connection is the one whose name contains **Warehouse** or **DW**;
- the Operational one is the one whose name contains **Operational**, **Operations** or **SCOM** (and not Warehouse or DW).

Use the suggested names and nothing needs setting up. If your connections have other names, the dashboard still works: choose the right connection from each drop-down (use *Save dashboard → Save current variable values as dashboard default* so it remembers).

Prefer configuration files? [`deploy/grafana-provisioning/`](../deploy/grafana-provisioning) has examples that create both data sources (Windows authentication, SQL authentication).

## 4. Import the dashboards

**One at a time:** *Dashboards → New → Import → Upload dashboard JSON file*, pick a folder for it, and click **Import**. There is nothing to map. Make one Grafana folder per technology (for example "SCOM - IIS") and put that technology's dashboards in it. Start with everything in [`dashboards/scom-core/`](../dashboards/scom-core) because the other dashboards link back to it, then import the technologies you use.

**All at once (recommended if you want everything):** use Grafana's file provisioning:

1. Copy the repository's `dashboards` folder to the Grafana server, for example to `C:\SCOMDashboards` (Windows) or `/var/lib/grafana/scom-dashboards` (Linux). Delete any technology folders you don't want. The `README.md` and `.png` files in the folders are ignored by Grafana.
2. Copy [`deploy/dashboards-provisioning/scom-dashboards.yaml.example`](../deploy/dashboards-provisioning/scom-dashboards.yaml.example) into Grafana's `provisioning/dashboards/` folder (`C:\Program Files\GrafanaLabs\grafana\conf\provisioning\dashboards\` on Windows, `/etc/grafana/provisioning/dashboards/` on Linux), rename it to `scom-dashboards.yaml`, and set `path:` to the folder from step 1.
3. Restart Grafana. Every dashboard appears, with one Grafana folder per technology named after the directories (`windows-server`, `sql-server`, ...). Changes you make to the files are picked up automatically every 30 seconds.

This was tested on Windows with Grafana 13.3: all 28 dashboards appeared in their folders and rendered without errors. Linux paths follow Grafana's documentation but were not tested.

Each dashboard has a **Technology packs** drop-down at the top left that lists every imported dashboard, so you can switch between them. Server names in tables link to the matching detail dashboard, so import both the overview and the detail dashboard of a technology.

> Grafana's **Dashboards** page can take a few minutes to list newly imported folders (the search index updates in the background). The dashboards are there already: open one directly or use the Technology packs drop-down, then refresh the page later.

## 5. Check it works

1. Open **SCOM Platform Status** (`scom-core`). It shows the detected SCOM version and whether the Windows Server, Active Directory and SQL Server management packs are present.
2. Open **SCOM Enterprise Overview**. You should see your monitored computers and their health.
3. If a panel is empty or shows an error, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

## Updating

Each new version is published on the [Releases page](../../../releases) as `scom-grafana-dashboards-vX.Y.Z.zip`, with the changes listed in [CHANGELOG.md](../CHANGELOG.md). Download the zip, unzip it, and use one of these. If you edited a dashboard in place, your edit is replaced. *Save as* a copy under a different name first.

**Option 1: file provisioning (easiest, nothing to run).** If you set up provisioning in step 4, copy the new `.json` files over the old ones in the folder you pointed it at. Grafana picks them up within 30 seconds. Nothing else to do.

**Option 2: one script (Windows PowerShell).** Unzip the release into a folder, set `$Root` to it, and run this. It asks for a Grafana admin login, creates any missing folders, and overwrites the dashboards already there, `scom-core` first. Every line should say `success`; a failure shows `FAILED` and the reason.

<details>
<summary>Show the update script</summary>

```powershell
$Root = 'C:\Temp\Grafana'          # the unzipped release (contains scom-core, windows-server, ...)
$Url  = 'http://localhost:3000'    # your Grafana address

$cred = Get-Credential -Message 'Grafana admin login'
$pair = '{0}:{1}' -f $cred.UserName, $cred.GetNetworkCredential().Password
$h = @{ Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($pair)) }

# The ForEach-Object unrolls the list. Without it, Windows PowerShell 5.1 treats several folders as one.
$folders = @(Invoke-RestMethod "$Url/api/folders" -Headers $h | ForEach-Object { $_ })

$dirs = Get-ChildItem $Root -Directory | Sort-Object { if ($_.Name -eq 'scom-core') { 0 } else { 1 } }, Name

foreach ($dir in $dirs) {
    $f = $folders | Where-Object { $_.title -eq $dir.Name } | Select-Object -First 1
    if (-not $f) {
        $f = Invoke-RestMethod "$Url/api/folders" -Method Post -Headers $h -ContentType 'application/json' `
             -Body (@{ title = $dir.Name } | ConvertTo-Json)
    }
    foreach ($file in Get-ChildItem $dir.FullName -Filter *.json -Recurse) {
        $raw  = Get-Content $file.FullName -Raw -Encoding UTF8
        $body = '{"dashboard":' + $raw + ',"folderUid":"' + $f.uid + '","overwrite":true}'
        try {
            $r = Invoke-RestMethod "$Url/api/dashboards/db" -Method Post -Headers $h `
                 -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($body))
            '{0,-8} {1,-45} {2}' -f $r.status, $file.Name, $dir.Name
        } catch {
            '{0,-8} {1,-45} {2}  {3}' -f 'FAILED', $file.Name, $dir.Name, $_.ErrorDetails.Message
        }
    }
}
```

The folders are matched by name, so keep the folder names from the release (`windows-server`, `sql-server`, ...). If you used different folder names, the script creates new folders instead of updating the old ones. Only dashboards with the same uid are overwritten. If you see the same dashboard in two folders, delete the old copy. The script needs Windows PowerShell 5.1 or PowerShell 7 and a Grafana **admin** login, and the login is not stored.

</details>

**Option 3: by hand.** Import the newer `.json` over the old one into the **same folder** and choose **Overwrite** (*Dashboards → New → Import*). Do `scom-core` first.

## Removing

Delete the dashboards (or the folder) in Grafana. If you used file provisioning, remove the `scom-dashboards.yaml` file and the copied folder, then restart Grafana. Nothing is installed anywhere else.
