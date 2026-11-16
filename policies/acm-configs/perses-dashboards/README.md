# Perses Dashboards

## Description
Deploys a set of custom `PersesDashboard` resources into the `open-cluster-management-observability`
namespace on the hub, alongside the Perses dashboards ACM ships out of the box. Each dashboard was
converted from an existing Grafana dashboard (kept in this directory as the original `*.json` source)
using the upstream `percli migrate` tool against a disposable local Perses server, then adjusted to
match this cluster's conventions:

- `apiVersion: perses.dev/v1alpha2`, with dashboard content nested under `spec.config` (the shape
  required by the installed Perses Operator CRD)
- `metadata.namespace: open-cluster-management-observability` — the same namespace ACM's own
  `PersesDashboard` resources (e.g. `k8s-apiserver`, `acm-clusters-overview`) live in
- `metadata.labels.managed-by: bry-tam-policies`
- All Prometheus queries and label-value variables reference the existing `rbac-query-proxy-datasource`
  `PersesDatasource` by name (the same datasource ACM's own dashboards use), instead of a
  dashboard-local `Datasource` template variable

Each dashboard also has a matching `ScrapeConfig` manifest (`*-metrics-scrapeconfig.yml`) that adds the
dashboard's metrics to the set MCOA federates from managed clusters up to the hub's Thanos — without
these, most panels render empty because the metrics are never forwarded past the managed cluster. See
[Implementation Details](#implementation-details) for how the metric lists were derived.

Every dashboard requires selecting a managed cluster, matching the convention used by ACM's own
built-in dashboards: a `cluster` variable (backed by `acm_managed_cluster_labels`) is the first
variable on every dashboard, every other variable's label-value query is scoped to the selected
cluster, and every panel's PromQL query is scoped to it as well. See
[Implementation Details](#implementation-details) for how this was applied.

| Dashboard | Source JSON | Resource name | ScrapeConfig |
| --- | --- | --- | --- |
| OpenShift Networking (OVN) | `ovn-dashboard.json` | `ovn-dashboard` | `ovn-metrics` |
| OpenShift Cluster Health | originally `ocp-performance.json`, since reworked | `ocp-cluster-health` | `ocp-cluster-health-metrics` |
| Node Performance | `node.json` | `node-performance` | `node-metrics` |
| etcd Cluster Info | `etcd-on-cluster-dashboard.json` | `etcd-on-cluster-dashboard` | `etcd-metrics` |
| API Performance | `api-performance-overview.json` | `api-performance-overview` | `api-performance-metrics` |
| OpenShift & operator lifecycle | sourced from [brian-jarvis/ocp-lifecycle-dashboard](https://github.com/brian-jarvis/ocp-lifecycle-dashboard) (not vendored here) | `ocp-lifecycle` | `ocp-lifecycle-metrics` |

The "OpenShift Cluster Health" dashboard (formerly "OpenShift Performance") is a high-level single-cluster
health view rather than a performance deep dive. Per-component and per-node performance lives in
`node-performance`, `etcd-on-cluster-dashboard`, `api-performance-overview` and `ovn-dashboard`. Sections:

- **Cluster Overview** — firing alerts by severity, a node/namespace/pod summary table, top 10 firing alerts.
- **Cluster Operators** — summary tiles, a per-operator status table (Available / Progressing / Degraded, colored by state), and a status-history timeline of operators that were Degraded or Progressing.
- **etcd Health** — member/leader state, leader changes, failed proposals, DB size vs. quota, top 10 object
  counts stored in etcd (`apiserver_storage_objects`), and fsync/commit/peer latency.
- **Cluster Object Counts** — nodes, namespaces, secrets, configmaps, deployments, services and routes.
- **Monitoring Stack Health** — Prometheus/Alertmanager replicas, config reload, head series, ingestion rate,
  CPU/memory, scrape targets down, and metrics-server resource use.

The "OpenShift & operator lifecycle" dashboard is a fleet-wide summary (cluster counts, operator
support tables, OpenShift version compatibility) fed by the
[ocp-lifecycle-exporter](https://github.com/bry-tam/ocp-lifecycle-exporter) app deployed below — see
[Multicluster compatibility](#multicluster-compatibility) for how its `cluster` variable deliberately
differs from the other five dashboards.

## Dependencies
  - [ACM Observability](../observability/) — requires the `MultiClusterObservability` stack and the
    `open-cluster-management-observability` namespace to exist
  - [Cluster Observability Operator](../../operators/cluster-observability/) — provides the Perses
    Operator and the `PersesDashboard` CRD
  - Requires the `rbac-query-proxy-datasource` `PersesDatasource`, which is created automatically in
    the `open-cluster-management-observability` namespace once the multicluster-observability-addon
    (MCOA) is enabled on the hub
  - [Observability Addon Config](../observability-addon-config/) — this policy watches every
    `ScrapeConfig` in `open-cluster-management-observability` and keeps the
    `multicluster-observability-addon` ClusterManagementAddOn's global metrics config in sync with
    them. The `ScrapeConfig` manifests here are picked up automatically; no changes to that policy are
    needed.
  - The "OpenShift & operator lifecycle" dashboard additionally requires
    [ocp-lifecycle-exporter](#ocp-lifecycle-exporter) (below) to be deployed and its `ServiceMonitor` to
    be scraping it into user workload monitoring — see
    [Multicluster compatibility](#multicluster-compatibility) for details.

## Details
ACM Minimal Version: 2.17

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/latest/html-single/observability/index)

Notes:
  - Deployed using the `ft-acm-observability--enabled` feature-flag placement — the same placement
    used by the [ACM Observability](../observability/) policy itself, since these dashboards only
    make sense where that stack (and its `rbac-query-proxy-datasource`) already exists
  - Each dashboard is a plain, static `PersesDashboard` manifest (no hub templating) — once applied,
    the Perses Operator reconciles it and it shows up under Observe > Dashboards (Perses) in the console
  - Converting an additional Grafana dashboard: run it through `percli migrate --online --format cr`
    against a local throwaway Perses server (e.g. `podman run -d -p 8080:8080
    docker.io/persesdev/perses:v0.54.0`), then apply the same adjustments listed above (apiVersion,
    `spec.config` nesting, namespace, label, datasource references) before adding it as a manifest here

## Implementation Details
Two recurring issues were found and fixed in the source Grafana JSON before migration (in a temporary
copy only — the original `*.json` files in this directory are untouched):
  - Collapsed Grafana `row` panels had a malformed `gridPos.y` (a nested object instead of a plain
    number), which `percli` rejects — fixed by assigning each row an incrementing numeric `y`
  - The dashboards had no top-level `uid`, which `percli`'s `--online` migration requires — fixed by
    assigning each dashboard a slug-style `uid`

After migration, `percli`'s `--format cr` output needed further adjustment to match this cluster: the
API version (`v1alpha1` → `v1alpha2`), the missing `spec.config` wrapper, the target namespace and
label, and swapping every `$Datasource` reference (and the `Datasource` template variable itself) for
a direct reference to the `rbac-query-proxy-datasource` `PersesDatasource`.

See [percli-issues.md](./percli-issues.md) for the full list of `percli` conversion bugs encountered
across all six dashboards (written up as standalone upstream bug reports — summary, source snippet,
what was generated, what was expected), several of which are summarized again below.

See [perses-ui-issues.md](./perses-ui-issues.md) for Perses *core/UI* bugs and feature gaps (not
`percli` conversion bugs): the `JoinByColumnValue` transform requiring every per-query-suffixed instance
of a join column to be listed explicitly (silently collapsing every row into one otherwise — see the
dedicated `JoinByColumnValue` entry below for the short version), the `MergeIndexedColumns`/`MergeColumns`
row-multiplication bug, and an RFE for column header text styling (e.g. bold) which has no supported
mechanism today.

**Table panels with a Grafana `merge` transformation need a manual transform fix after migration.**
`percli` always converts Grafana's `transformations: [{id: merge}]` into Perses' `MergeSeries`
transform, but `MergeSeries` only merges series that share an *identical* full label set — it doesn't
help when each underlying query returns a different subset of labels (e.g. one query has
`{cluster, version, channel}`, another has only `{cluster, status}`). In that (common) case the correct
equivalent is `JoinByColumnValue`, which merges rows that share the same value in one or more named
columns, matching Grafana's `merge` behavior. This bit the three multi-query table panels on the
`ocp-lifecycle` dashboard (`Clusters`, `Operators`, `OpenShift minors: current phase`) — each row
rendered as several partially-populated rows instead of one row per cluster/operator/minor until the
panels' `transforms` were changed from `{kind: MergeSeries, spec: {}}` to
`{kind: JoinByColumnValue, spec: {columns: [...]}}` with the same join column(s) Grafana's `merge` was
implicitly keying on (found by checking which labels are common across all of that panel's queries).
When converting a future dashboard, check the source JSON for any panel with a `merge` transformation
and verify after migration that its Perses `transforms` use `JoinByColumnValue` with the right columns,
not `MergeSeries`.

**Table panels with more than one query need their `columnSettings` label columns suffixed by query
index.** Perses' Table panel suffixes *every* label key (not just `value`) with ` #<queryIndex+1>`
(1-indexed by the query's position in that panel's `queries` list) whenever the panel has more than one
query — this happens as a raw data-building step before any `transforms` run. `percli` already applies
this convention correctly to `value` columns (`value #1`, `value #2`, ...) but leaves label-derived
`columnSettings.name` entries as bare label names (e.g. `cluster`, `phase`, `ocp_version`), which no
longer match any real column once the suffixing happens. The symptom is a blank friendly header (e.g.
"Cluster") with the real data sitting in unmapped, unhidden columns like `cluster #1`..`cluster #9`
visible in a CSV/table export. The fix: rename each affected `columnSettings.name` to
`<label> #<queryIndex+1>`, matching the query that actually produces that label, and add a hidden
(`hide: true`) duplicate entry for every other query index that also happens to produce the same label
(e.g. a `cluster` column that's grouped-by in every query of the panel) — keep only one instance visible
as the authoritative column. The join/merge transform's own `transforms[].spec.columns` field is
**not** exempt from suffixing either — see the dedicated `JoinByColumnValue` gotcha below, which
corrects an earlier (wrong) assumption that this field could stay bare. Also update any `dataLink` URL
that references a renamed column to Perses' `${__data.fields["column_name"]}` bracket-notation syntax
(not the older dot-notation `${__data.fields.column_name}`) using the new suffixed name. This affected
the same three `ocp-lifecycle` panels (`Clusters`, `Operators`, `OpenShift minors: current phase`) —
when converting a future dashboard, check every Table panel with more than one query for bare
label-named `columnSettings` entries and fix them the same way.

**Epoch-millisecond timestamp columns need an explicit `format.unit`, and `unix-timestamp`/
`unix-timestamp-ms` are NOT "format as a date" units.** Grafana field overrides like
`unit: "time:YYYY-MM-DD"` (used on the `ocp-lifecycle` dashboard's "Phase ends"/"Support ends" columns,
all computed as `(max(..._timestamp_seconds{...}) + 43200) * 1000`) are dropped entirely by `percli` —
without a `format` key Perses renders the raw epoch-millisecond number instead of a date.

Our first attempt at a fix added `format: {unit: unix-timestamp-ms}` (a valid unit per the `#dateFormat`
schema in `github.com/perses/shared/cue/common/format.cue`) — this is schema-valid and does **not** fix
the symptom: the raw number (e.g. `1808308800000`) kept rendering as-is, even after a hard browser
refresh/private window. We confirmed why by fetching and reading the actual compiled JS Perses serves to
the browser (`oc exec` into the `perses-0` pod, `GET /plugins/Table/mf-manifest.json` to find the shared
`@perses-dev/core` Module Federation chunk, then `GET` that chunk directly and grepping it). The date
formatter's real logic is:
```js
if ("unix-timestamp" === n) return (e > 1e12 ? Math.floor(e / 1e3) : e).toString();
if ("unix-timestamp-ms" === n) return Math.floor(e < 1e11 ? 1e3 * e : e).toString();
// ... only for every OTHER date unit does it proceed to `new Date(e)` + Intl.DateTimeFormat
```
`unix-timestamp`/`unix-timestamp-ms` are "normalize to a given epoch scale and print the raw number"
units (useful if your data mixes seconds- and milliseconds-scale timestamps) — they are not a
human-readable date format, despite the misleading `#dateFormat` grouping and display labels ("Unix
Timestamp (s)"/"Unix Timestamp (ms)") suggesting otherwise. The actual fix is to use one of the units
that reach the `new Date(e)`/`Intl.DateTimeFormat` branch instead — `date-iso`, `date-us`, `date-local`,
`datetime-iso`, `datetime-us`, `datetime-local`, `time-iso`, `time-us`, `time-local`, or
`relative-time`. We used `format: {unit: date-iso}` (renders `YYYY-MM-DD`, matching Grafana's original
`time:YYYY-MM-DD`). The date-parsing helper auto-detects seconds vs. milliseconds (treats a value
`< 1e10` as seconds and multiplies by 1000, otherwise uses it as-is), so our existing epoch-millisecond
values needed no query changes — only the `format.unit` value. This affected all 11 of our
`unix-timestamp-ms` columns across the `Clusters`, `Operators`, `OpenShift minors: current phase`, and
`OpenShift minors: phase end dates`/`Operator × OpenShift compatibility` (added by the `groupingToMatrix`
rebuild below) panels on `ocp-lifecycle`.

**`JoinByColumnValue`'s `columns` list requires the exact, fully-suffixed column name(s) — it does not
fuzzy-match bare names against the per-query-suffixed variants.** This was found by reading the actual
runtime implementation (`applyJoinTransform` in `perses/shared`'s
`components/src/utils/transform-data.ts`, the same package consumed by the Table plugin): for each raw
row it computes `Object.keys(row).filter((k) => columns.includes(k)).map((k) => row[k]).join('|')` and
groups rows whose hash matches. This is a plain **exact string match** against each row's own keys — it
never strips a ` #N` suffix or matches a bare name like `cluster` against a suffixed key like
`cluster #3`. Since every Table panel with more than one query suffixes *every* key (per the gotcha
above), a bare `columns: [cluster]` (or `[join_key]`) matches **zero** keys on every row, so
`Object.keys(...).filter(...)` is always empty and every row hashes to the same empty string `''` —
**silently collapsing all rows into one.** This explains two things discovered in this project: (1) the
`Operators` panel showing only one merged row despite ~24 distinct operators existing in the data, and
(2) the `Clusters` panel *appearing* to work correctly with a bare `columns: [cluster]` — it was actually
hitting the exact same empty-hash collapse-to-one-row bug, which happened to produce the visually correct
result only because this environment currently has exactly one managed cluster. That panel is a latent
bug that will silently merge every cluster into one row again as soon as a second managed cluster exists.
The correct fix is to list **every per-query-suffixed instance** of the join column(s) in
`transforms[].spec.columns`, e.g. `['cluster #1', 'cluster #2', ..., 'cluster #9']` for a panel with 9
queries all grouping by `cluster`. Since each raw row only ever contains the one suffix matching its own
query index, `Object.keys(row).filter(...)` finds exactly one matching key per row, and the values hash
correctly across queries as long as the underlying label value is the same. This repo's earlier
mitigation of wrapping the `Operators` panel's 8 queries in a `label_join(<expr>, "join_key", "/",
"cluster", "operator_namespace", "package")` to synthesize a single composite key (rather than listing
`cluster`/`operator_namespace`/`package` directly) is **still the right approach** for a true
multi-column composite join — it was just missing the suffixing fix on top: the transform now reads
`columns: ['join_key #1', ..., 'join_key #8']`, not bare `[join_key]`. All five `JoinByColumnValue`
transforms on `ocp-lifecycle` (`Clusters`, `Operators`, `OpenShift minors: current phase`,
`Operator × OpenShift compatibility`, `OpenShift minors: phase end dates`) were corrected to list every
suffixed variant. When converting a future multi-query Table panel, always list every `<name> #N`
instance of the join column(s) — never a bare name — regardless of how the panel currently appears to
behave.

**`percli` drops Grafana's `groupingToMatrix` transform entirely — Perses has no dynamic pivot
equivalent.** `ocp-lifecycle`'s `Operator × OpenShift compatibility` and `OpenShift minors: phase end
dates` panels both pivot a single query's results into a wide matrix (one column per distinct label
value — `ocp_version` and `phase` respectively). `percli` converts the query but silently drops the
transform, leaving `columnSettings` that reference the *post-pivot* Grafana column names (e.g. `'4.12'`,
`'Full support'`), which never match any real raw column (`ocp_version`/`phase`/`value`). The symptom is
the raw, unformatted metric value showing up in the table instead of the expected matrix. Since Perses'
Table plugin has no declarative pivot transform, the fix is to rebuild the panel with one query per
pivoted column value (filtered via a label matcher, e.g. `ocp_version="4.12"` or `phase="Full support"`),
grouped by the row label only, then join all of those queries back together on the row label via
`JoinByColumnValue` — the same per-query column-suffixing and join-key rules documented above apply.
For `OpenShift minors: phase end dates`, the `phase` label only ever takes a small fixed set of values
(confirmed live: `Full support`, `Maintenance support`, `Extended update support`, `Extended update
support Term 2`, `Extended update support Term 3`, plus `Extended life phase` which doesn't occur yet),
so one query per phase is a stable, low-maintenance fix. For `Operator × OpenShift compatibility`, the
pivot column is `ocp_version`, which is an open-ended, growing set — the fix uses a **hardcoded list of
OCP minor versions** as one query per version. **This list needs periodic maintenance** as clusters
upgrade and new OpenShift minors are released; there is no way to make it fully dynamic without a pivot
transform Perses doesn't support. The list was originally seeded with every version `4.12`-`4.26`
(mirroring the dashboard's other hardcoded ranges), but most of those were irrelevant: versions below
what any managed cluster is running will never need an upgrade-compatibility check, and the exporter
only reports compatibility data up to the newest release it knows about. The range was narrowed to the
lowest `ocp_version` currently reported by `ocp_lifecycle_cluster_info` across managed clusters (today:
`4.20`) through the highest version with real compatibility data in `ocp_lifecycle_operator_ocp_compatibility`
(today: `4.22`), plus a few explicit extra columns for near-future versions chosen when this was last
refreshed (`4.23`, `5.0`, `5.1`). Re-derive both ends of this range (via the two queries above) whenever
this panel is revisited, rather than assuming the existing list is still current.

A second, independent bug was found in this same panel: the visible "Operator" column was pinned to
`package #1` (the per-query-suffixed column from only the *first* listed version query), so any operator
whose earliest compatible version wasn't that first column showed a blank name even though its row held
real data for later columns — confirmed via a CSV export showing only 2 of ~24 operators (the ones
supporting the oldest listed version) with a populated name. The first fix attempted was a second
transform, `MergeIndexedColumns` (`spec: {column: package}`), run *after* the `JoinByColumnValue` join, on
the theory that it would collapse `package #1..#N` into one plain `package` column containing whichever
per-row value is non-null. **This introduced a worse bug: every operator rendered 2-3 duplicate rows.**
Reading the actual deployed JS (same `oc exec`-into-`perses-0`/Module Federation approach used for the
date-format investigation below) found the real `MergeIndexedColumns` implementation: for each input row it
finds *every* key matching `^((package #\d+)|(package))$`, and then — instead of picking one and collapsing
the row — pushes **one new output row per matching key**. After `JoinByColumnValue` correctly merges an
operator's per-version queries into a single row containing e.g. `package #1`, `package #2`, `package #3`
(three matched version queries), `MergeIndexedColumns` explodes that single merged row back into three
near-identical copies — exactly reproducing the number-of-matched-queries as duplicate rows. (`MergeColumns`
has the identical per-matching-key row-multiplication bug in its implementation and is equally unsafe for
this purpose.) The fix: drop `MergeIndexedColumns` entirely and add a 7th, version-unconditional query —
`max by (package) (ocp_lifecycle_operator_info{cluster=~"$cluster"})` — which returns every tracked operator
regardless of OCP-version compatibility. `JoinByColumnValue` is extended to list `package #1` through
`package #7`; the panel then displays `package #7` (always present) as the "Operator" column and hides
`package #1..#6` as duplicates, the same hidden-duplicate convention used by every other multi-query Table
panel in this dashboard. This fixes both bugs at once without ever calling `MergeIndexedColumns`: the name
column is always populated (query 7 has no version filter) and no row-exploding merge step is involved. The
per-version `value #N`/`lifecycle_version #N` columns are unaffected and remain one per query.

**Each version column shows the compatible operator version, not just a checkmark.** The underlying
metric, `ocp_lifecycle_operator_ocp_compatibility`, carries a `lifecycle_version` label (the operator's
own version/channel string, e.g. `1.20`) alongside the `package`/`ocp_version` labels already used for
grouping and joining. The panel's 6 per-version queries now group by `(package, lifecycle_version)`
instead of `(package)` alone, so each query's result row carries `lifecycle_version` as a column — the
`columnSettings` reference `lifecycle_version #1`..`#6` (one per query, same per-query suffixing rule as
everywhere else in this panel) as the visible content for each OCP-version column, instead of the raw
`value #N` compatibility flag (now hidden). A cell is blank when the operator has no reported compatibility
for that OCP version, same as before. Today every tracked operator reports exactly one `lifecycle_version`
across all the OCP versions it's compatible with, so this doesn't change row counts — but if an operator
ever reports *different* `lifecycle_version` values as compatible with the same `ocp_version` (e.g. two
channels both certified for the same release), it would produce one row per distinct `(package,
lifecycle_version)` pair for that query, which is the correct behavior to surface the distinction rather
than silently collapsing it.

**`OpenShift minors: current phase` was removed; its current-phase signal was merged into
`OpenShift minors: phase end dates`.** The two panels showed overlapping information: `current phase`
displayed each version's current support phase (via `ocp_lifecycle_ocp_version_support_phase`, a numeric
0-3 indicator) plus a generic "Standard support ends" date that duplicated information already visible
in `phase end dates`' own per-phase end-date columns. The `current phase` panel was dropped entirely, and
its `ocp_lifecycle_ocp_version_support_phase` query — along with its `cellSettings` color mapping (`3`
→ green "Full support", `2` → blue "Maintenance", `1` → orange "Extended (EUS)", `0` → red "End of life",
`-1` → plain "Unknown") — was added as a 7th query to `phase end dates`, producing a new, visible, colored
"Current phase" column positioned right after "Minor". The same per-query-suffixing and
`JoinByColumnValue` rules documented above apply here too: the new query's `ocp_version` column is
suffixed `#7` and listed in the transform's `columns`, and its plain-text `phase #7` column is hidden
since the colored cell's own text already conveys the same phase name. The dashboard row (previously
titled "OpenShift lifecycle") was renamed to "OpenShift Release Lifecycle" and widened to the panel's
full 24-column grid width now that it holds a single panel instead of two side by side.

**Follow-up: revisit these two panels once the cluster's Perses version moves past v0.54.0.** Perses has
since added a `PivotByLabel` transform (true parity with Grafana's `groupingToMatrix`: a declarative,
dynamic pivot that turns distinct values of a label into columns, with no fixed query-per-column list
needed) — confirmed present on `perses/shared`'s current `main` branch but confirmed *absent* from the
v0.54.0-vendored copy that Red Hat's Cluster Observability Operator 1.5.3 actually ships on this cluster.
Once an upgrade brings `PivotByLabel` into the deployed version, `Operator × OpenShift compatibility` and
`OpenShift minors: phase end dates` should be rebuilt to use it instead of the hardcoded
one-query-per-column-value workaround described above, eliminating the periodic version-list maintenance
burden entirely.

### ScrapeConfigs

MCOA does not use the `observability-metrics-(custom-)allowlist` ConfigMap mechanism from classic ACM
observability — it federates metrics from each managed cluster based on the `ScrapeConfig` objects
referenced by the `multicluster-observability-addon` ClusterManagementAddOn (see
[Observability Addon Config](../observability-addon-config/)). Each `*-metrics-scrapeconfig.yml` here
follows the same shape as ACM's own built-in ScrapeConfigs (`platform-metrics`,
`apiserver-hcp-uwl-metrics`, etc.) in that namespace: `metricsPath: /federate`, `scheme: HTTPS`,
`scrapeClass: not-configurable`, a placeholder `staticConfigs` target, and an exact-match `params.match[]`
list (`{__name__="..."}` per metric, no regex) to minimize the extra Thanos cardinality/storage cost.

The metric lists were derived by: parsing every PromQL query in the converted dashboards to extract
candidate metric names, then diffing against the full set of metric names already forwarded by ACM's 7
built-in ScrapeConfigs (165 distinct names). Only metrics not already forwarded were added. A few metric
names (e.g. `container_cpu_usage_seconds_total`) are repeated across more than one dashboard's
ScrapeConfig — that overlap is expected and harmless (duplicate `match[]` entries across separate
ScrapeConfigs don't double-scrape). When converting another dashboard in the future, repeat this
diffing process against the then-current set of forwarded metrics before writing its ScrapeConfig.

**Required label — `app.kubernetes.io/component: platform-metrics-collector`:** being listed in the
`multicluster-observability-addon` ClusterManagementAddOn's config (which happens automatically via
[Observability Addon Config](../observability-addon-config/)'s discovery) only delivers the `ScrapeConfig`
object to each managed cluster; it does **not** make the local `PrometheusAgent` actually scrape it. The
agent (`platform-metrics-collector` in `open-cluster-management-agent-addon`) only picks up
`ScrapeConfig`s matching its `scrapeConfigSelector` label selector,
`app.kubernetes.io/component: platform-metrics-collector` — the same label every one of ACM's own
built-in platform ScrapeConfigs carries. Every `*-metrics-scrapeconfig.yml` here must set this label
(along with `managed-by: bry-tam-policies` for consistency with the rest of this repo), otherwise the
object exists but is silently never scraped and dashboard panels render empty. This was the root cause
of an initial empty-data bug found after deployment (`node_load1` panels showing no data); confirmed
fixed by checking the generated agent config
(`oc get secret -n open-cluster-management-agent-addon prom-agent-platform-metrics-collector -o jsonpath='{.data.prometheus\.yaml\.gz}' | base64 -d | gunzip`)
for a `job_name: scrapeConfig/.../<name>` entry with the expected `match[]` list.

**Watch out for generic metric names that are already forwarded under a restrictive `job=`/`service=`
filter.** The "already forwarded" diffing above only checks metric *names*, not the label filters those
names are forwarded with. A handful of ACM's built-in ScrapeConfigs forward common `client_golang`
process metrics (`process_cpu_seconds_total`, `process_resident_memory_bytes`, `go_goroutines`,
`workqueue_adds_total`, `workqueue_depth`) but restricted to specific jobs (`job="apiserver"` or
`job="etcd"`). Several converted dashboards query these same metric names for *different* jobs
(`node` queries `process_cpu_seconds_total`/`process_resident_memory_bytes` with
`job="kubelet"`/`job="crio"`, and `go_goroutines` unfiltered/aggregated by job; `ovn-dashboard` queries `workqueue_adds_total`/`workqueue_depth` with
`job=~"ovnkube-controller.*"`), so the name-only diff incorrectly treated them as already covered and
they were left out of the original `match[]` lists, leaving those specific panels empty while others on
the same dashboard worked fine. Fixed by adding unrestricted `{__name__="..."}` entries for these 5
metric names to the relevant ScrapeConfigs (`ovn-metrics`: `workqueue_adds_total`, `workqueue_depth`;
`node-metrics`: `go_goroutines`, `process_cpu_seconds_total`,
`process_resident_memory_bytes`). To avoid storing the same series twice, these entries are now
*complementary* selectors that exclude what ACM already forwards (`job!="apiserver"` for
`go_goroutines`, `process_cpu_seconds_total`, `workqueue_adds_total`, `workqueue_depth`;
`job!~"apiserver|etcd"` for `process_resident_memory_bytes`). Likewise, metrics ACM's `platform-metrics`
ScrapeConfig already forwards unfiltered (e.g. `etcd_server_has_leader`, `etcd_mvcc_db_total_size_in_bytes`,
`etcd_disk_wal_fsync_duration_seconds_bucket`, `container_memory_rss`) are not re-federated by
`ocp-cluster-health-metrics`. When converting another dashboard, check any
generic/common metric name against the *label-filtered* match list of ACM's existing ScrapeConfigs, not
just its name, before concluding it's already covered.

### Multicluster compatibility

The converted dashboards originally had no managed-cluster selector, unlike ACM's own built-in
dashboards. To match that convention, each dashboard gained the same `cluster` `ListVariable` ACM's
dashboards use (a `PrometheusLabelValuesVariable` against `acm_managed_cluster_labels`, via
`rbac-query-proxy-datasource`), and every other variable and panel query was scoped to it:

  - Variables whose label-value matcher already had `{...}` (e.g. `kube_node_role{role="master"}`) got
    `cluster="$cluster",` prepended inside the existing braces
  - Variables with a bare metric name and no braces (e.g. `apiserver_request_total`) got
    `{cluster="$cluster"}` appended
  - Variables with no matcher at all (e.g. api-performance-overview's `code`/`verb`/`flow_schema`/
    `priority_level`) got a matcher of `{cluster="$cluster"}`
  - `StaticListVariable`-kind variables (the `interval` variables) were left untouched — they aren't
    Prometheus-backed
  - Every PromQL panel query had `cluster="$cluster"` injected into every metric selector it
    references, including inside aggregations, vector-matching expressions, and range-vector/subquery
    syntax, while leaving function names, `by (...)`/`on (...)`-style label lists, and duration
    literals (e.g. `[5m]`, `[$interval:]`) untouched

This was done with a scripted regex-based PromQL transform (not a full parser, since PromQL tooling
isn't available in this environment) with a stoplist of aggregation operators, functions, and keywords
to avoid misidentifying them as metric names. When converting another dashboard in the future, apply
the same cluster-scoping to its variables and panel queries before committing it.

**`ocp-lifecycle` is a deliberate exception to the single-cluster convention above.** It's a fleet-wide
summary dashboard (cluster counts, operator support tables, compatibility matrices) that only makes
sense showing multiple clusters at once, so its `cluster` variable keeps `allowMultiple: true` and
`allowAllValue: true` (defaulting to all clusters), and the panel queries below the "Fleet summary"
section use `cluster=~"$cluster"` (regex match) instead of the other five dashboards' `cluster="$cluster"`
(exact match) — both of these were already present in the upstream Grafana source and were preserved
as-is; only the variable's datasource/matcher were swapped to the ACM-standard
`acm_managed_cluster_labels` source (for friendly cluster display names) in place of the original
`ocp_lifecycle_cluster_info`-based one.

The "Fleet summary" panels (the five stat panels and the "Clusters" table) intentionally have **no**
`cluster` matcher: they always show the whole fleet regardless of the `cluster` variable selection.

Unlike the other five dashboards, `ocp-lifecycle`'s metrics don't come from the managed cluster's
platform Prometheus — they come from
[ocp-lifecycle-exporter](https://github.com/bry-tam/ocp-lifecycle-exporter) (deployed by
`generator-ocp-lifecycle-exporter.yml` below), scraped into OpenShift's **user workload monitoring**
Prometheus by a `ServiceMonitor` shipped in that repo. Its `ocp-lifecycle-metrics-scrapeconfig.yml`
therefore uses `app.kubernetes.io/component: user-workload-metrics-collector` instead of
`platform-metrics-collector` — a second `PrometheusAgent` (also named `user-workload-metrics-collector`,
in `open-cluster-management-agent-addon`) federates ScrapeConfigs carrying that label from user
workload monitoring instead of the platform Prometheus. This requires user workload
monitoring to be enabled both on the managed cluster (`enableUserWorkload: true` in
`cluster-monitoring-config`) and in the `MultiClusterObservability` CR
(`spec.capabilities.userWorkloads.metrics.default.enabled`, already wired up in
[../observability/observability.yml](../observability/observability.yml) via the `observability-mcoa`
label). Its `params.match[]` list includes all 26 `ocp_lifecycle_*` metrics the exporter exposes
(confirmed against its live `/metrics` output), not just the 19 the dashboard's panels query, so the
exporter-health/debug metrics are available for future panels without another ScrapeConfig edit.

**`user-workload-metrics-collector` ScrapeConfigs must NOT set `staticConfigs` (or `scrapeClass`/`scheme`)
— leave them out entirely and let MCOA populate them.** This folder's `platform-metrics-collector`
ScrapeConfigs all carry a placeholder `scrapeClass: not-configurable` and a placeholder `staticConfigs`
target, because MCOA's `multicluster-observability-addon` *unconditionally* rewrites
`scrapeClassName`/`scheme`/`staticConfigs` for every platform-labeled ScrapeConfig regardless of what's
already set (see
[`internal/metrics/manifests/values.go`](https://github.com/stolostron/multicluster-observability-addon/blob/main/internal/metrics/manifests/values.go),
`BuildValues()`, the `opts.Platform.ScrapeConfigs` loop). The `user-workload-metrics-collector` path is
different: MCOA only auto-populates those same three fields `if len(scrapeConfig.Spec.StaticConfigs) == 0`
(i.e. only when the ScrapeConfig doesn't already define `staticConfigs`). Earlier revisions of
`ocp-lifecycle-metrics-scrapeconfig.yml` copied the platform convention and shipped a placeholder
`staticConfigs: [{targets: ["not-configurable"]}]`, which made that length check non-zero and silently
skipped MCOA's auto-population entirely — leaving `scrapeClass` unset/wrong (COO's Prometheus Operator
rejected the object: `scrapeConfig/ocp-lifecycle-metrics ... rejected due to invalid configuration:
scrapeClass "not-configurable" not found in Prometheus scrapeClasses`, visible via
`oc get events -n open-cluster-management-agent-addon`) and then, after that was hand-fixed, left
`staticConfigs.targets` as the literal unresolvable string `not-configurable` (`dial tcp: lookup
not-configurable ...: no such host`). Both problems were originally worked around by hand (setting
`scrapeClass: ocp-monitoring` and `staticConfigs.targets:
prometheus-user-workload.openshift-user-workload-monitoring.svc:9092` explicitly, the latter requiring
discovering that UWM's `prometheus-user-workload` Service splits `/metrics` and `/federate` across ports
9091/9092 unlike platform's `prometheus-k8s`, which serves everything on 9091) — but the *correct* fix,
confirmed from the MCOA source above, is to **omit `staticConfigs` (and `scrapeClass`/`scheme`) from the
ScrapeConfig manifest entirely**. With no `staticConfigs` defined, MCOA's own length check passes and it
fills in the correct `scrapeClassName` (`ocp-monitoring`), `scheme` (`HTTPS`), and `staticConfigs` target
(an internal `ScrapeClassUWLTarget` constant it maintains itself) automatically — this is both simpler
and more durable than hardcoding a target that could change between MCOA releases. Any future
`user-workload-metrics-collector`-labeled ScrapeConfig in this folder should follow this same pattern:
set `jobName`, `metricsPath: /federate`, and `params.match[]` only, and leave `scheme`/`scrapeClass`/
`staticConfigs` out of the spec.

### Dynamic intervals

Every dashboard that has an `interval` variable (`ovn-dashboard`, `etcd-on-cluster-dashboard`,
`api-performance-overview`, `node-performance`, `ocp-cluster-health`) uses the same `StaticListVariable`
scale: `1m, 3m, 5m, 10m, 20m, 30m`, defaulting to `10m`. `api-performance-overview` additionally keeps
an `auto` ($__auto_interval_interval) option as an extra first choice; the others don't.

`ovn-dashboard` and `etcd-on-cluster-dashboard` originally had no `interval` variable at all, and every
panel's rate-style range-vector window (`[2m]`/`[5m]`) was hardcoded. Both dashboards gained the
`interval` variable above, and every `rate()`/`irate()`/`increase()` window was switched to
`[$interval]`. The one exception is `etcd-on-cluster-dashboard`'s
`changes(etcd_server_leader_changes_seen_total{...}[1d])` panel, which intentionally stays hardcoded at
`[1d]` — it's a full-day leader-election-stability check, not a rate-smoothing window, so tying it to
the (max 30m) interval selector would change its meaning rather than just its resolution.

The other three dashboards already had an `interval` variable wired up for most panels, but a handful
of panels were missed and still had a hardcoded `[5m]`: one in `api-performance-overview`
(`apiserver_flowcontrol_request_wait_duration_seconds_bucket`) and four in `node-performance` (three
`kubelet_cgroup_manager_duration_seconds_bucket` panels plus one `kubelet_pleg_relist_duration_seconds_count`
panel). These were switched to `[$interval]` as well. `ocp-cluster-health` (formerly `ocp-performance`) had no leftover hardcoded
windows. When converting or auditing another dashboard, grep its queries for `\[[0-9]+[smhd]\]` to find
any windows that should be tied to the `interval` variable instead.

### Dashboard and panel descriptions

Every dashboard has a `spec.config.display.description`, and every panel has a
`spec.display.description` (shown as the "i" tooltip next to the panel title in Perses). A panel
description should say what the data shows, how to read it (units, normal values, warning thresholds)
and any caveats (for example a dependency on an extra ScrapeConfig, PSI being enabled, or a panel that
ignores a variable). Keep this up to date when adding or changing panels. To find panels that are
missing one, check for panels whose `spec.display` has no `description`.

### `complianceType: mustonlyhave` on every manifest

Every manifest in this policy explicitly sets `complianceType: mustonlyhave`. The default
`musthave` compares list fields (like a `PersesDashboard`'s `spec.config.variables` or a
`ScrapeConfig`'s `params.match[]`) by checking that each desired entry is present — it never removes
entries that are no longer in the desired manifest. In practice this meant edits that shrank or
renamed a variable (e.g. removing a one-off `interval` entry that had been added twice across two
edits) left stale, duplicate entries on the live object indefinitely, even though the repo file and
`git diff` looked correct. This was discovered by comparing the live `PersesDashboard` objects
(`oc get persesdashboard <name> -n open-cluster-management-observability -o json`) against the
checked-in YAML and finding duplicate variable names (e.g. two `interval` entries on
`ocp-performance` (since renamed `ocp-cluster-health`), two `etcd_pod` entries on `etcd-on-cluster-dashboard`) that didn't exist in the
repo. With `mustonlyhave`, the governance framework does an exact replace of every field covered by
the template instead, so the live object always matches the committed file precisely — this both
fixes the existing drift (the policy controller will correct it on its next evaluation) and prevents
it from recurring. Any new manifest added to this policy should also set `complianceType: mustonlyhave`
unless there's a specific reason to allow unmanaged fields to persist.

# OCP Lifecycle Exporter

## Description
`generator-ocp-lifecycle-exporter.yml` is a second, independent `PolicyGenerator` kept in this same
directory (not part of the `perses-dashboards` policy above). It deploys
[ocp-lifecycle-exporter](https://github.com/bry-tam/ocp-lifecycle-exporter) — a self-contained app that
builds its own container image in-cluster with Shipwright and runs it, exposing OpenShift/operator
lifecycle metrics on `:9120/metrics` — to every managed cluster.

Rather than vendoring a copy of that repo's manifests here, the `ocp-lifecycle-exporter/` subdirectory
is a thin local Kustomization whose only `resources:` entry is the remote repository itself:
```yaml
resources:
  - https://github.com/bry-tam/ocp-lifecycle-exporter?ref=main
```
The `manifests:` path in `generator-ocp-lifecycle-exporter.yml` points at that subdirectory, which
`kustomize` (and therefore the PolicyGenerator plugin) resolves at build time into the 13 objects the
upstream repo's own root `kustomization.yaml` produces (Namespace, ServiceAccounts, RBAC, a Shipwright
`Build`/`BuildRun`, an `ImageStream`, a `Deployment`, and a `Service`), bundled into a single
`consolidateManifests: true` `ConfigurationPolicy` with `complianceType: mustonlyhave` (see above for
why `mustonlyhave` matters for list-shaped fields like RBAC rules).

**Tradeoff:** this is the only policy in the repo whose manifest content is fetched over the network at
`kustomize build` time instead of being vendored locally. Every time this policy is regenerated (CI,
local build, or an ArgoCD render), it re-fetches `bry-tam/ocp-lifecycle-exporter@main` live — a new
commit to that repo's `main` branch changes what this policy deploys without any change to this repo.

## Dependencies
  - [Builds for Red Hat OpenShift Operator](../../operators/openshift-builds/) — the exporter's image is
    built in-cluster via a Shipwright `Build`/`BuildRun`, which requires this operator (and, transitively,
    the Pipelines Operator it depends on). The `ocp-lifecycle-exporter` policy declares a `dependencies:`
    entry on the `openshift-builds-operator` policy (`compliance: Compliant`) so it won't attempt to
    deploy until that operator is installed and healthy.

## Details
ACM Minimal Version: 2.12

Upstream: [bry-tam/ocp-lifecycle-exporter](https://github.com/bry-tam/ocp-lifecycle-exporter)

Notes:
  - Deployed to every managed cluster via the `env-bound-placement` Placement (the same "all clusters in
    this environment's clusterset" placement used by `cluster-health`/`cluster-version`) — not gated
    behind any `ft-*` feature flag
  - The upstream repo now ships a `ServiceMonitor` (`deployment/servicemonitor.yml`) that scrapes the
    exporter into OpenShift user workload monitoring, so it's included automatically as one of the 13
    objects this policy deploys. Alerting is still intentionally out of scope, matching the upstream
    repo's own README. See the [`ocp-lifecycle` dashboard](#description) above and its
    `ocp-lifecycle-metrics-scrapeconfig.yml` for how that data then gets federated up to the hub.
  - To pin to a specific commit or tag instead of tracking `main`, change the `?ref=main` query
    parameter in `ocp-lifecycle-exporter/kustomization.yaml`
