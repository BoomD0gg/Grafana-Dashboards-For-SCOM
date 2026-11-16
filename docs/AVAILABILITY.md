# Availability dashboards

The `availability` folder shows how available your **application stacks** are. A stack is a **SCOM group** (for example "Web servers" or "Payroll system") or a **SCOM distributed application**. The dashboards show whether each stack is up now, its availability against an SLA target, how much downtime it had and which component caused it.

| Dashboard | What it is for |
|---|---|
| **Availability - Overview** | Every stack in one table, with state, availability against the SLA target, downtime and a daily status strip. Select a stack name to open its detail. |
| **Availability - Stack Detail** | One stack: daily availability against the SLA line, the status of each component over time, outages by hour, and the open alerts on its servers. |
| **Availability - Monthly Report** | Availability and downtime month by month, with the worst days. |

## What you need

Nothing extra is installed on your SCOM servers or agents. You need:

1. **The two SQL connections** the other dashboards use, with read access to both `OperationsManagerDW` (all the availability figures) and `OperationsManager` (the open-alerts table). If your other dashboards work, this is already done.
2. **At least one stack** in SCOM, described below.
3. **Servers that are monitored.** Each member of a stack needs a SCOM agent (or be otherwise monitored), as normal Windows computers are. A server SCOM cannot see produces no availability data.

### Create a stack

In the SCOM console, go to *Authoring → Groups → Create a new Group*:

1. Give the group a name that means something to your business, for example `Payroll system`.
2. For the management pack, **create a new one for your own groups** (for example `My stacks`) rather than using the Default Management Pack. It must be an **unsealed** management pack, which is what any new one is.
3. Under *Explicit Members*, add the **Windows Computers** (or other objects) that make up the stack. You can use dynamic rules instead.
4. Finish. SCOM adds the group to its data warehouse within a short time (sometimes up to an hour), after which it appears in the **Stack** drop-down.

A distributed application works the same way: its components count as the stack's members.

The dashboards use the **availability** state of each member. History starts when the member was first monitored, so a stack you create today still shows its members' past hours.

## The drop-downs at the top

| Drop-down | What it does |
|---|---|
| **Stacks** | **All groups and applications** (the default) lists every group and distributed application that has monitored members, including the groups management packs ship. **My stacks** lists only the ones you created yourself (those in an unsealed management pack). |
| **Stack** | Choose one or more stacks. The Overview and Report take several, the Stack Detail takes one. |
| **Stack is down when** | **Any component down**: one failed member makes the stack unavailable for that time (use this when every member is needed). **All components down**: the stack is unavailable only when every member is down (use this for redundant stacks, such as a load-balanced pair). |
| **SLA target %** | The target the **Meets SLA** column and the dashed line compare against. |
| **Planned maintenance** | **Exclude** (the default) leaves time in maintenance mode out of the measured time. **Count as downtime** counts it as unavailable. |

The time range at the top decides the period measured. The default is the last 30 days (6 months on the Monthly Report).

## How the figures are calculated

- A stack's availability is calculated from its members' hourly availability states, because SCOM does not store availability for plain groups.
- **Availability = 1 − downtime ÷ measured time.** The measured time is the real elapsed time, from when the members were first monitored (or the start of the time range) to now.
- Where several members fail within the same hour, the **longest single member outage** counts. Failures at different times within one hour are not added together, so real downtime can be a little longer than shown.
- Time when SCOM could not reach a server's agent counts as unavailable. The by-hour table shows it as **Not reporting**.
- SCOM writes each hour's figures shortly after the hour ends, so an outage still in progress shows in the stack's **Current state** quickly but may take up to an hour to appear in the downtime and by-hour table.

More background: [HOW-IT-WORKS.md](HOW-IT-WORKS.md).

## What was tested, and what was not

Tested in a small lab with groups of Windows computers, including a real outage: a server's agent was stopped for 27 minutes and the dashboards showed exactly 27 minutes of downtime, and the stack turned Critical while it lasted. **Distributed applications and nested groups were not exercised.** If you use them, please [open an issue](../../../issues/new/choose) and say what you see.

## Troubleshooting

**"No stacks found", or the Stack drop-down only shows "(no stacks found)".**
- With **Stacks** on **My stacks**, this is normal until you have created a group in your own management pack. Choose **All groups and applications**, or create a stack as above.
- A group created recently may not have reached the data warehouse yet. Give it up to an hour.
- A group whose members are not monitored by SCOM has nothing to measure and is left out.

**The page starts on "My stacks" even though the default is "All groups and applications".** You are either on an older copy of the dashboard (re-import the `availability` folder with Overwrite) or opened it from a saved link or bookmark. Grafana stores the drop-down choices in the address, so an old link brings the old choice. Open the dashboard from the Dashboards list instead.

**An SQL error such as "Incorrect syntax near ')'".** This came from an older version (before 0.2.1) when the Stack drop-down was empty. Re-import the `availability` folder from the latest release.

**The page is slow.** With every group selected, the dashboard works through all the members of all those groups. On a large SCOM, with big built-in groups, choose **My stacks** or select fewer stacks.

**A stack shows 100% but you know there were problems.** Check that the members are monitored and that the time range covers the period. Availability only counts time SCOM measured. A stack is also only as good as its members' availability monitors: a problem SCOM has no monitor for cannot show up here.

**Other panels are empty or show errors.** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
