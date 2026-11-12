# Viewing dashboards without logging in, and single sign-on

Out of the box, Grafana asks everyone to log in. This page covers three ways to change that:

1. **Anonymous access** — anyone who can reach Grafana sees the dashboards with no login (good for a wall display).
2. **Kiosk mode** — a clean full-screen view for a wallboard.
3. **Single sign-on** — people sign in with their company identity.

> **Read the security section first.** Anonymous access is easy to switch on and easy to get wrong.

---

## Security: what anonymous access really allows

This was tested on Grafana 13.3 with Windows authentication data sources. An anonymous visitor with the **Viewer** role:

| Can | Cannot |
|---|---|
| Open and refresh every dashboard | Create, edit or delete dashboards (HTTP 403) |
| Use the server and counter drop-downs, drill-downs and time picker | Use the admin APIs, list users, change settings (HTTP 403) |
| Open the kiosk URL | Use Explore |
| **Run their own `SELECT` queries through the data source** | See the Grafana version |
| See the list of configured data sources | |

The important line is the bold one: a Viewer, anonymous or not, can send **any read query** through the data source, not only the queries on the dashboards. That means **anyone who can reach your Grafana URL can read anything your read-only SQL account can read — the whole SCOM database** (server names, alerts, monitors, configuration). The list of configured data sources is also visible to them and may show connection details such as the SQL server's address.

So:

- **Only enable anonymous access on a Grafana that is reachable from trusted networks only.** Use a firewall, a VPN, or an internal-only address. Never expose it to the Internet.
- Keep the SQL account **read-only** ([`Grant-ReadOnly.sql`](../deploy/sql/Grant-ReadOnly.sql)). This is the safety net that limits the damage.
- If you cannot restrict the network, use SSO (below) instead.

---

## 1. Enable anonymous access

You edit Grafana's settings file, add a few lines, and restart Grafana.

### Windows (tested)

1. Open `C:\Program Files\GrafanaLabs\grafana\conf\` (or wherever Grafana is installed).
2. Create a file named **`custom.ini`** if it does not exist (do **not** edit `defaults.ini` — upgrades overwrite it). Add:
   ```ini
   [auth.anonymous]
   enabled = true
   org_name = Main Org.
   org_role = Viewer
   hide_version = true
   ```
3. Restart the Grafana service from an elevated PowerShell or the Services app (the service is called **Grafana**):
   ```powershell
   Restart-Service Grafana
   ```

### Linux

1. Edit `/etc/grafana/grafana.ini` and add or uncomment the same `[auth.anonymous]` section.
2. Restart: `sudo systemctl restart grafana-server`.

### Docker

Set environment variables on the container: `GF_AUTH_ANONYMOUS_ENABLED=true`, `GF_AUTH_ANONYMOUS_ORG_ROLE=Viewer`, `GF_AUTH_ANONYMOUS_HIDE_VERSION=true`.

*(Linux and Docker follow Grafana's documented settings; they were not tested here.)*

### What the settings mean

| Setting | Meaning |
|---|---|
| `enabled = true` | Turns anonymous access on. |
| `org_name` | The organisation visitors land in. `Main Org.` is Grafana's default. Use the organisation that holds your dashboards. |
| `org_role = Viewer` | What visitors may do. **Keep this `Viewer`.** Never use `Editor` or `Admin`. |
| `hide_version = true` | Hides Grafana's version from logged-out visitors. |

### Check it works

Open a private/incognito browser window and go to `http://<your-grafana>:3000/d/scom-core-overview` (or the address of any imported dashboard). It should open without a login page. Logged-in users still log in as normal and keep their own permissions.

### Switch it off again

Remove the `[auth.anonymous]` section (or set `enabled = false`) and restart Grafana.

---

## 2. A wallboard (kiosk mode)

Add `?kiosk` to a dashboard address to hide the menus and show only the panels:

```
http://<your-grafana>:3000/d/scom-core-overview/x?kiosk
```

Useful extras: `&refresh=1m` refreshes every minute, and `&from=now-6h&to=now` sets the time range. For a screen that rotates through several dashboards, create a **Playlist** in Grafana (*Dashboards → Playlists*) and start it in kiosk mode. *(The kiosk URL was tested; playlists were not.)*

Note: in Grafana 13 the filter drop-downs and the dashboard menus at the top stay visible in kiosk mode (the screenshots in this project were taken that way). Grafana has options to hide them (for example &_dash.hideVariables&_dash.hideLinks&_dash.hideTimePicker — these are Grafana features that were **not tested** here). Anonymous visitors can still change the filters, but nothing they change is saved.

---

## 3. Single sign-on options

The free (open-source) Grafana supports these. The dashboards do not care which you choose. **None of them was tested with these dashboards** — they are Grafana features described in Grafana's own documentation.

| Method | Good for | Notes |
|---|---|---|
| **LDAP / Active Directory** (`[auth.ldap]`) | On-premises Active Directory | People sign in with their domain username and password — one set of credentials, not true single sign-on. AD groups map to Grafana roles. |
| **OAuth / OpenID Connect** (`[auth.azuread]`, `[auth.generic_oauth]`) | Microsoft Entra ID (Azure AD), Okta, Keycloak, Google, GitHub | Real single sign-on. Groups or app roles map to Grafana roles. |
| **Auth proxy** (`[auth.proxy]`) | Seamless Windows sign-in | A reverse proxy (for example IIS or nginx with Windows/Kerberos authentication) authenticates the person and passes their name to Grafana. They open the link and are already signed in. |
| **SAML** | — | **Not available in the free edition** (Grafana Enterprise or Cloud only). |

Suggested setup for most SCOM sites:

1. Create an AD or Entra group such as `Grafana-SCOM-Viewers` and map it to the Grafana **Viewer** role. Everyone in it gets read-only access.
2. Keep **Admin** for a small group.
3. Use Grafana **folder permissions** to hide dashboards from people who should not see them. Remember the caveat above: a Viewer can still query the data source directly, so folder permissions control what people *see in the interface*, not what the SQL account can read.

Grafana's documentation for each method: [grafana.com/docs/grafana/latest/setup-grafana/configure-security/](https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/).

---

## 4. Public dashboards (not recommended for these dashboards)

Grafana can share a single dashboard through a public link with no login. These dashboards rely on **drop-down filters and drill-down links**, which public dashboards do not support, so most would not work properly. Use anonymous access on a restricted network instead.
