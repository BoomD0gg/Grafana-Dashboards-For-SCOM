# Security Policy

## Supported release

Security fixes are targeted at the latest release.

## Reporting a vulnerability

Do not publish exploitable security problems as public GitHub issues. Use GitHub's **Private vulnerability reporting** (Security tab of this repository) if it is enabled, or contact the repository owner privately.

Include:
- the dashboard and version affected;
- your Grafana and SCOM versions;
- steps to reproduce;
- the potential impact.

Remove server names, domain names, addresses and any credentials from anything you send.

## Security model

- The dashboards run **read-only `SELECT` queries** through a Grafana Microsoft SQL Server data source. They do not write to SCOM and do not use the SCOM SDK or console.
- The recommended SQL account has `db_datareader` on `OperationsManager` and `OperationsManagerDW` and is denied writes ([`deploy/sql/Grant-ReadOnly.sql`](deploy/sql/Grant-ReadOnly.sql)).
- No passwords, tokens or connection strings are stored in these files. Data source credentials live in your own Grafana configuration.
- Anyone who can open a dashboard can see the SCOM data it shows. Anyone with the Viewer role can also run queries through the data source. Restrict who can reach Grafana and who has accounts. See [docs/ACCESS.md](docs/ACCESS.md).

## Downloads

Only files from this repository's `main` branch or its GitHub Releases are official. Review dashboard JSON before importing it into a production Grafana, as with any shared dashboard.
