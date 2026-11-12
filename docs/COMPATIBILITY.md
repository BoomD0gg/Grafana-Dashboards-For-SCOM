# Compatibility

| Component | Tested | Notes |
|---|---|---|
| SCOM | **2022** (10.22) | The only version available for testing. |
| SCOM 2019 / 2025 | **Not tested** | Expected to work: the dashboards read the standard `OperationsManager` and `OperationsManagerDW` views (`ManagedEntityGenericView`, `StateView`, `AlertView`, `vManagedEntity`, `Perf.vPerfRaw` and so on), which have the same shape on these versions. The Platform Status dashboard shows the detected SCOM version. If something breaks, please open an issue with the failing panel's error. |
| Grafana OSS | 13.3.0 | Declared for 11 and later. Versions below 13 were not tested. Only the built-in Microsoft SQL Server data source and core panels are used. |
| Data source authentication | Windows authentication | SQL authentication is supported by Grafana and the provided script, but was **not tested**. |
| SCOM database server | SQL Server 2022 | TLS with a CA-issued certificate. |
| Management packs | See [PACKS.md](PACKS.md) | Only the versions listed were tested. Other versions of a management pack may use different class names; where the version appears in a class name the queries use a wildcard, but only the lab version was validated. |
| Browser | Microsoft Edge | Rendering was checked in a headless Edge. Any modern browser supported by Grafana should work. |
