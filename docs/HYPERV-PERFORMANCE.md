# Hyper-V performance dashboards

The `hyper-v` folder has two performance dashboards next to the health dashboards:

| Dashboard | What it shows |
|---|---|
| **Hyper-V Performance - Host** | How one Hyper-V host is doing: CPU, memory, storage, network, virtual switches and VM capacity. |
| **Hyper-V Performance - Virtual Machines** | A table of every VM on the chosen hosts, then CPU, memory, disk and network graphs for the VMs you pick. |

They read the performance counters collected by the **Hyper-V Performance (Community)** management pack (performance objects named `Community Hyper-V ...`). **Without that management pack imported in SCOM these two dashboards are empty.** The other Hyper-V dashboards (Overview, Host Detail) use Microsoft's Hyper-V management pack and do not need it. The dashboards only read the SCOM Data Warehouse; nothing is installed on your hosts or SCOM servers by them.

Allow time after importing the management pack: SCOM needs a few collection cycles (every 5 minutes for most counters) before graphs fill, and the hourly data that long time ranges use arrives later.

## Host dashboard

Choose a host at the top.

- **Headline numbers:** running and total VMs, the ratio of virtual processors to the host's logical processors, how busy the CPUs are, and memory used and free.
- **CPU:** where the time goes (guest VMs, hypervisor overhead, the host operating system), balance across logical processors, and how long virtual processors wait for a real one. Rising waiting time means VMs are queueing for CPU.
- **Memory:** physical and committed memory, memory in MB, paging, and Dynamic Memory pressure.
- **Storage:** latency, operations per second, throughput and queue length per physical disk.
- **Network:** throughput and utilisation per adapter, and a table with link speed, utilisation and the errors and discards seen.
- **Volumes:** size and free space of each volume the management pack collects, with a warning under 20 percent free and critical under 10 percent.
- **Virtual switches and capacity:** switch throughput and dropped packets, VMs by state, virtual processors against logical processors, and memory assigned to VMs against memory installed.

## Virtual Machines dashboard

- **Hyper-V host** (top left) lists the hosts that have data. Several can be chosen.
- The **table** lists every VM on the chosen hosts, busiest CPU first: virtual processors, whether Dynamic Memory is on, CPU average and maximum, memory, disk operations, throughput, latency and queue, and network packets and drops. **Click a VM name to graph only that VM.**
- **Graph these VMs** (top) decides which VMs are drawn in the graphs below the table. It starts with one VM so the graphs stay readable; choose more when you want to compare. The headline numbers and the table always cover every VM on the chosen hosts.
- **Graphs:** CPU per VM, the busiest virtual processor per VM (a VM can be short of CPU while its average looks fine), waiting for a processor, memory assigned, memory demand and pressure (Dynamic Memory VMs), disk operations, throughput, latency and queue per virtual disk, network packets and drops per adapter, network throughput and virtual disk errors.

## What the figures mean

- CPU for a VM is a percentage of the CPU that VM has been given, not of the whole host.
- "CPU max" in the table is the highest 5-minute average (or hourly average on ranges over 48 hours), not an instant peak.
- The processor waiting time is shown in nanoseconds, as Microsoft documents the counter. The management pack's own catalogue says the unit is not independently verified. VM disk latency is shown in the counter's own unit, also not independently verified: use it to compare disks with each other and to spot steps up over time.
- Error and discard counts on adapters, and error counts on virtual disks, are totals since the adapter or disk started. A rising line matters more than a high one.
- Raw samples are kept by SCOM for 10 days by default, so ranges up to 48 hours use 5-minute values and longer ranges use hourly averages.

## What was tested, and what was not

Tested in a small SCOM 2022 lab with a Hyper-V host running two virtual machines:
- Every query runs against real data from the management pack and the dashboards render without errors.
- The host and VM figures were compared with the management pack's own collection results.

**Not tested**
- Under load. The lab host and VMs were nearly idle, so the colour thresholds and the busy-host graphs were not seen at high values.
- Counters the lab's version of the management pack does not collect: VM memory demand and pressure, and VM network throughput in bytes. Those three panels show "Not collected" until they have data.
- SCOM 2019 and 2025, a SQL account with only read permissions, and an estate with many hosts or VMs.
- Two VMs with the same name on different hosts are drawn as one line in the graphs.

## Troubleshooting

**The graphs are empty.** Check that the management pack is imported and its collection rules are enabled, and that the host appears in the **Hyper-V host** drop-down. If the drop-down shows "(no hosts found)" there is no data from the management pack yet.

**A VM is missing from the table.** The table lists VMs with data in the time range. A VM that was off, or created after the range started, may have none.

**Other panels are empty or show errors.** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
