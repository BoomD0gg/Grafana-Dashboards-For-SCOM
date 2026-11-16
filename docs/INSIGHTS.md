# Insights dashboards: root cause hints, capacity planning and trends

The `insights` folder has three dashboards that turn the history SCOM already keeps into answers to three questions:

| Dashboard | The question it answers |
|---|---|
| **Insights - Server Timeline** | What happened on these servers, in what order, and where should I start looking for the cause? |
| **Insights - Capacity Planning** | What will run out, and when? Which servers are over-provisioned or struggling? Is SCOM's own database about to fill? |
| **Insights - Trends** | Is the estate getting better or worse? Which alerts and monitors are the noisiest? |

Nothing is installed on your SCOM servers. The dashboards only read the two SCOM databases that the other dashboards already use.

## Server Timeline (root cause hints)

Choose one or more servers at the top and a time range that covers the problem. Pick several when an incident crosses servers, for example a database server and the application servers that use it. The page shows:

- **Which server went Critical first.** One row per selected server, earliest first, with its first critical monitor, the number of critical changes and the alerts. When several servers are involved, the top row is the best place to start.
- **First critical change and First critical monitor.** The earliest time in the range that a monitor on this server went Critical, and which monitor. SCOM's health roll-up means that a failure at the bottom makes the monitors above it change a moment later, so the **earliest** change is usually closest to the cause.
- **CPU and memory graphs with markers.** A red marker is an alert being raised and an orange one is a monitor going Critical, so you can see whether a spike lines up with the trouble.
- **Alerts raised in 5-minute buckets.** A burst of alerts at one moment usually has one cause.
- **Unhealthy now, oldest first.** The monitors that are Warning or Critical right now on this server and what runs on it, oldest first.
- **Timeline.** Alerts raised and closed, monitor health changes, maintenance mode and Windows error events in one table. Sort by Time to read it in order. The **Windows events** drop-down leaves out or adds warning events.

Every row in the timeline and in the unhealthy table says which server it belongs to. Choose only servers you suspect are related: the timeline lists the 500 most recent rows, so a long range with many servers can cut off the oldest events.

**Read it as a lead, not a verdict.** The timeline shows what happened first, which is where to start. It does not prove why. Windows events appear only if a management pack collects them. Short-lived spikes can be missed because SCOM stores a performance value only when it changes, plus hourly.

## Capacity Planning

A straight line is fitted to the daily values over the **History** you choose (14, 30, 60 or 90 days), and the tables show how soon each item reaches the limit you set. The time range at the top reaches 90 days into the future so that the chart can show the projected line.

| Panel | What it tells you |
|---|---|
| **Disks: when will they fill?** | For each disk: used % now, growth in percentage points per day, the days until the **Threshold %** is reached and the date. Soonest first. |
| **The disks that will fill soonest** | History and a dashed projection for up to six disks, against the threshold. |
| **CPU and memory** | Average, 95th percentile (p95) and maximum, and the trend per 30 days. **Constrained** means p95 is at or above **High load %**. **Over-provisioned** means p95 is at or below **Low load %**. |
| **SQL Server databases** | Size, growth per day and when the space already allocated to the database will be used up (SQL Server then grows the file). |
| **SCOM operational database and data warehouse files** | Size, how full each file is, its maximum size and growth setting. A file that cannot grow and is nearly full stops SCOM recording anything. |

**Things to know**
- **It is a baseline, not a prediction.** It knows nothing about planned projects, one-off clean-ups or month-end peaks, and a single large file copy can distort a short history.
- **It needs at least 7 days** of data for each disk or database, and shows "Not enough history" until then.
- **The counters must be collected.** The dashboards use the Windows Server counters (disk free space, processor time, memory used) and the SQL Server database size counters. If a management pack does not collect them, the row is missing.
- **Shared and cluster disks** can appear more than once.
- **Other tools** that model growth in more detail will do better; this is a good first look from data you already have.

## Trends

- **Alerts raised per day** by severity, and **monitors that went Critical per day** (roll-up monitors left out): is the estate getting noisier or less healthy?
- **Average minutes to resolve alerts**, by the day they were raised: are alerts taking longer to deal with?
- **CPU and memory, this period against the previous one**: whether load is higher than before. The previous period of the same length is shifted forward so the lines overlap.
- **Alerts raised most often**, with how many sources and days, and the average time to resolve: fix or tune the top entries first.
- **Monitors that change state most often (flapping)**: a monitor that flips many times per object is generating noise and is the first one to tune.

## How long SCOM keeps the data

| Data | Default retention | Used for |
|---|---|---|
| Alerts | 400 days | Alert trends, timeline |
| Raw monitor state changes | 180 days | Timeline, flapping, critical per day |
| Hourly and daily performance and state | 400 days | Capacity, trends |
| Raw performance samples | 10 days | The CPU and memory graphs on short ranges |

Your SCOM administrator may have changed these.

## What was tested, and what was not

Tested in a small SCOM 2022 lab:
- Every query runs against real data, and the dashboards render without errors.
- The Server Timeline was checked against real outages of lab servers, including two servers stopped a couple of minutes apart (the table put them in the right order): it listed the heartbeat failures, the monitors that changed and the alerts, in order, and the first critical monitor was the earliest change.
- The growth formula was checked against a made-up series with a known answer (a disk growing 2 points a day from 68% reaches 90% in 11 days), and the disk figures were compared with the real volumes.

**Not tested**
- With more than about 9 days of history. The lab is young, so the forecasts there show gentle trends.
- With a SQL account that has only the read-only permissions from the grant script (the queries read file sizes with `sys.database_files` and a SQL Server number table in `master`; both are normally available to any login).
- On a large estate. In the lab each panel takes about 1 to 3 seconds.
- Windows events on a busy estate: the page lists the 500 most recent rows.

## Troubleshooting

**A table says "-" or is empty.** The counter is probably not collected for that server, or the server has less than 7 days of history. Check the time range and History setting.

**The forecast looks wrong for one disk.** Look at the graph: a clean-up or a large copy in the History window bends the line. Shorten or lengthen the **History** setting.

**Other panels are empty or show errors.** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
