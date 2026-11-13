# How it works

## The data path

```
SCOM agents ─► management servers ─► OperationsManager DB (current state, alerts, health)
                                  └─► OperationsManagerDW DB (history, performance counters)
                                                │
                                   read-only SQL account
                                                │
                              Grafana ─ Microsoft SQL Server data source ─► dashboards
```

Nothing sits between Grafana and the SCOM databases: no agent, no plugin, no export job.

## Which database for what

| Question the dashboard answers | Source |
|---|---|
| What is the health of this server / service / role **right now**? Open alerts? Unhealthy monitors? | `OperationsManager` views |
| How has CPU, memory, a counter changed **over time**? Availability? Alerts per hour? | `OperationsManagerDW` views |

The performance charts show the counters SCOM actually collects for your environment. The **Counter** drop-down is filled from the warehouse, so it only offers counters that have data — nothing is hard-coded.

## Design choices

- **Read-only.** Only `SELECT` statements. The recommended SQL account cannot write.
- **Bounded queries.** Tables have row limits. Performance charts use 5-minute samples for ranges up to 48 hours and hourly values beyond, so a month-long chart doesn't read millions of rows.
- **Roll-up.** Counters that belong to child objects (a disk, a database, a site) are rolled up to their host so you can filter by server.
- **Drill-down.** Overview dashboards list servers; clicking a name opens that server's detail dashboard with the time range kept.
- **No demo data.** Every number comes from your SCOM.
- **Availability is real elapsed time.** SCOM writes an hourly state row only for hours in which something changed or was not healthy, so a healthy hour has no row. Availability is therefore the time lost divided by the time that actually passed (from when the object was first monitored, or the start of the time range), not by the number of rows. For an application stack, the downtime of its members is combined hour by hour: with "any component down" the longest single member outage in each hour counts (members failing at different times within one hour are not added together), with "all components down" every member has to be down.

## What "validated" means

A dashboard is called validated when it was installed in a test lab, every query ran against real SCOM data, the objects and counts it showed were compared with the servers themselves, and (where possible) a fault was introduced, such as stopping a service, to confirm the dashboard reacted. What was and was not covered for each is in [PACKS.md](PACKS.md).

## Known timing behaviour

SCOM, not the dashboards, decides how fast health changes. Some monitors sample every 15 minutes and need several bad samples, so a stopped service may take 30–45 minutes to turn a role Critical. A role's health also lags its monitors by a few minutes. The dashboards show SCOM's state as soon as SCOM records it.
