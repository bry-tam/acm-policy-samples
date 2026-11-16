---
# `percli migrate` issues found during Grafana → Perses conversion

While converting the six Grafana dashboards in this folder to `PersesDashboard` CRs
(via `percli migrate -f <dashboard.json> --online --format cr -o yaml`, Perses
`v0.54.0`), we ran into the issues below. Each one required a manual, hand-written
fix to the generated YAML before the resulting `PersesDashboard` would render
correctly (or at all) against a real Perses backend (Perses Operator `v1alpha2`,
as shipped by Red Hat ACM's `multicluster-observability-addon`/Cluster
Observability Operator).

This document exists to be filed as one or more upstream issues against
[`perses/perses`](https://github.com/perses/perses) (the `percli` CLI). Each entry
below is written to stand alone as a bug report: a brief summary, the relevant
source snippet, what `percli` actually generated, and what was expected instead.

---

The dashboards used for this issue can be found at:
- https://github.com/brian-jarvis/ocp-lifecycle-dashboard/blob/main/dashboards/ocp-lifecycle.json
- https://gitlab.cee.redhat.com/sbr-shift/metrics-dashboards/-/tree/main/dashboards?ref_type=heads

The inprogress migrated dashboards to be used with ACM MCOA can be found at:
- https://github.com/brian-jarvis/bry-acm-policy-samples/tree/implement-perses-dashboards/policies/acm-configs/perses-dashboards


## 1. Generated CR uses `apiVersion: perses.dev/v1alpha1` and omits the `spec.config` wrapper

**Summary:** `percli migrate --format cr` emits a `PersesDashboard` manifest with
`apiVersion: perses.dev/v1alpha1` and puts all dashboard content (`display`,
`variables`, `panels`, `layouts`, `duration`) directly under `spec`. The real
`PersesDashboard` CRD installed by the Perses Operator (as shipped via Cluster
Observability Operator / ACM's MCOA) is `perses.dev/v1alpha2`, and its
`PersesDashboardSpec` requires all of that content to be nested one level deeper,
under `spec.config`. Every converted dashboard failed server-side validation until
this was fixed by hand.

**Source (Grafana dashboard, any example — this is not input-dependent; the
bug is in the CR envelope `percli` always produces):**
```json
{
  "title": "Openshift Networking",
  "uid": "ovn-dashboard",
  "panels": [ ... ],
  "templating": { "list": [ ... ] }
}
```

**What was generated:**
```yaml
apiVersion: perses.dev/v1alpha1
kind: PersesDashboard
metadata:
  name: ovn-dashboard
spec:
  display:
    name: Openshift Networking
  variables: [ ... ]
  panels: { ... }
  layouts: [ ... ]
  duration: 1h
```

**What was expected** (confirmed by inspecting ACM's own live, operator-managed
`PersesDashboard` objects, and by server-side dry-run rejecting the above with
`spec.config: Required value`):
```yaml
apiVersion: perses.dev/v1alpha2
kind: PersesDashboard
metadata:
  name: ovn-dashboard
  namespace: open-cluster-management-observability
spec:
  config:
    display:
      name: Openshift Networking
    variables: [ ... ]
    panels: { ... }
    layouts: [ ... ]
    duration: 1h
```

---

## 2. Online migration fails with an opaque error when the source dashboard has no top-level `uid`

**Summary:** Several of our source Grafana dashboards (exported some time ago,
before Grafana started always including a `uid`) had no top-level `uid` field.
`percli migrate --online` does not report this as a missing/required field —
it fails with a generic, unrelated-sounding decode error that gives no hint
about the actual cause.

**Source (Grafana dashboard with no `uid`):**
```json
{
  "title": "etcd-cluster-info dashboard",
  "schemaVersion": 16,
  "panels": [ ... ],
  "templating": { "list": [ ... ] }
}
```
*(note: no `"uid"` key present anywhere in the document)*

**What was generated:** `percli` exits with a failure, regardless of
`--format`/`-o` combination:
```
Error: unable to decode the response body. Error name cannot be empty
```

**What was expected:** A clear, specific validation error identifying the
missing `uid` field as the cause (e.g. `error: dashboard.uid is required for
migration`), or — preferably — `percli` should synthesize a `uid` itself (e.g.
slugified from `title`) when one is absent, the same way Grafana itself does
when importing a `uid`-less dashboard.

---

## 3. Malformed row `gridPos.y` fails with a raw Go unmarshal error instead of a validation message

**Summary:** Some source dashboards had a corrupted `gridPos.y` on their
top-level `row` panels — a nested `gridPos` object instead of a plain integer
(likely produced by a buggy prior export/edit of the dashboard in Grafana).
`percli` correctly rejects this malformed input, but the error message leaks
an internal Go struct field name and gives no indication of which panel, or
even which file region, is at fault.

**Source (malformed `row` panel):**
```json
{
  "type": "row",
  "title": "OVN Resource Monitoring",
  "collapsed": true,
  "gridPos": { "h": 1, "w": 24, "x": 0, "y": { "h": 1, "w": 24, "x": 0, "y": 0 } },
  "panels": [ ... ]
}
```

**What was generated:**
```
Error: cannot unmarshal object into Go struct field plain.panels.y of type float64
```

**What was expected:** A validation error identifying the offending panel (by
index, `id`, or `title`) and field (`gridPos.y`), and ideally the expected type,
e.g. `error: panel[2] ("OVN Resource Monitoring").gridPos.y: expected number,
got object`.

---

## 4. Grafana `merge` transformation is always converted to Perses `MergeSeries`, even when `JoinByColumnValue` is required

**Summary:** Grafana's `transformations: [{id: "merge"}]` is used both (a) to
collapse series that share an *identical* label set, and (b) — just as
commonly — to join several queries that return *different, partially
overlapping* label sets into one row per shared key (e.g. one query grouped by
`cluster,status` and another by `cluster,phase`, merged into one row per
`cluster`). Perses' `MergeSeries` transform only implements case (a); case (b)
requires `JoinByColumnValue`. `percli` always emits `MergeSeries` for a Grafana
`merge` transformation, regardless of which case actually applies, so tables
built from queries with different label sets rendered as several
mostly-empty rows instead of one merged row per key.

**Source (Grafana panel with queries returning different label sets, joined
via `merge`):**
```json
{
  "title": "Clusters",
  "transformations": [
    { "id": "merge", "options": {} },
    { "id": "organize", "options": { ... } }
  ],
  "targets": [
    { "refId": "A", "expr": "ocp_lifecycle_cluster_info", "instant": true },
    { "refId": "B", "expr": "ocp_lifecycle_cluster_status", "instant": true },
    { "refId": "C", "expr": "ocp_lifecycle_cluster_support_phase", "instant": true }
  ]
}
```

**What was generated:**
```yaml
transforms:
- kind: MergeSeries
  spec: {}
```
(Result: each query's series stayed on its own row, since no two of the three
queries share an identical label set — the table rendered 1 row per query
instead of 1 row per cluster.)

**What was expected:**
```yaml
transforms:
- kind: JoinByColumnValue
  spec:
    columns:
    - cluster
```
`percli` should detect that the panel's queries return differing label sets and
choose `JoinByColumnValue` (joining on whatever label(s) are common to all of
the panel's queries) instead of unconditionally emitting `MergeSeries`.

---

## 5. Table `columnSettings` entries are not suffixed to match Perses' own per-query label-suffixing behavior

**Summary:** Perses' Table panel runtime suffixes **every** label key (not
just the metric `value`) with ` #<queryIndex+1>` whenever a panel has more
than one query (confirmed in `perses/plugins`,
`table/src/table-data-utils.ts`, `buildTimeSeriesTableData()`) — this happens
unconditionally, before any `transforms` run. `percli`'s generated
`columnSettings` correctly anticipates this suffixing for the synthetic
`value` column (emitting `value #1`, `value #2`, …) but leaves every
*label*-derived column name (e.g. `cluster`, `package`, `status`) bare and
unsuffixed. Since the real data never contains a bare `cluster` column once
there's more than one query, these `columnSettings` entries never match
anything: configured friendly headers rendered blank, while the real data sat
in unmapped columns like `cluster #1`, `cluster #2`, … `cluster #9` (visible
directly in a CSV export of the table).

**Source (Grafana field override giving a friendly display name to the
`cluster` field, on a multi-query panel):**
```json
{
  "fieldConfig": {
    "overrides": [
      {
        "matcher": { "id": "byName", "options": "cluster" },
        "properties": [ { "id": "displayName", "value": "Cluster" } ]
      }
    ]
  }
}
```

**What was generated** (panel with 9 queries, all grouping by `cluster` among
other labels):
```yaml
columnSettings:
- name: cluster
  header: Cluster
- name: value #1
  hide: true
- name: value #9
  hide: true
```

**What was expected:**
```yaml
columnSettings:
- name: 'cluster #1'
  header: Cluster
- hide: true
  name: 'cluster #2'
# ... one hidden duplicate per additional query that also groups by `cluster`,
#     through 'cluster #9'
- name: value #1
  hide: true
- name: value #9
  hide: true
```
`percli` should apply the exact same `#<queryIndex+1>` suffix it already uses
for `value` to every label-derived `columnSettings.name`, for any Table panel
with more than one query.

---

## 6. `dataLink.url` is generated using deprecated dot-notation field references

**Summary:** Perses' documented syntax for referencing a row's cell value
inside a `dataLink.url` is bracket notation with a quoted key —
`${__data.fields["column_name"]}` (see
[perses.dev/plugins/docs/table](https://perses.dev/plugins/docs/table/)).
`percli` instead emits the older/incorrect dot-notation form,
`${__data.fields.column_name}`, carried over verbatim from Grafana's own
(different) data-link templating syntax.

**Source (Grafana data link on the `Product` field):**
```json
{
  "links": [
    {
      "title": "Red Hat lifecycle policy",
      "url": "${__data.fields.link}",
      "targetBlank": true
    }
  ]
}
```

**What was generated:**
```yaml
dataLink:
  url: '${__data.fields.link}'
  openNewTab: true
  title: 'Red Hat lifecycle policy'
```

**What was expected:**
```yaml
dataLink:
  url: '${__data.fields["link"]}'
  openNewTab: true
  title: 'Red Hat lifecycle policy'
```

---

## 7. Grafana theme-keyword / alpha-channel colors are copied verbatim into `cellSettings.backgroundColor`, producing values Perses itself rejects

**Summary:** Grafana value mappings can set `"color"` to a theme keyword such
as `"text"` (meaning "default text color / no highlight") or `"transparent"`.
`percli` copies these values directly into Perses' `cellSettings[].
backgroundColor` field. Perses' schema requires `backgroundColor` to match
`^#(?:[0-9a-fA-F]{3}){1,2}$` (3 or 6 hex digits only — no alpha channel, no
theme keywords). The literal string `"text"` fails this pattern outright, and
Grafana's `"transparent"` gets translated to an 8-digit RGBA hex
(`"#00000000"`) that also fails it (alpha channel unsupported). Both cases
caused the live `PersesDashboard` object to go `Degraded`/`PersesBackendError`
(HTTP 400) with explicit `invalid value ... (out of bound =~"^#...")` errors —
this is caught by the Perses backend's own validation, not by Kubernetes CRD
schema validation, so it was not caught until the object was actually applied.

**Source (Grafana value mappings using a theme color and a transparent color):**
```json
{
  "mappings": [
    {
      "type": "value",
      "options": {
        "-1": { "text": "Not tracked", "color": "text", "index": 8 }
      }
    },
    {
      "type": "special",
      "options": {
        "match": "null",
        "result": { "text": "–", "color": "transparent", "index": 1 }
      }
    }
  ]
}
```

**What was generated:**
```yaml
cellSettings:
- condition:
    kind: Value
    spec:
      value: '-1'
  text: Not tracked
  backgroundColor: text
- condition:
    kind: Misc
    spec:
      value: 'null'
  text: '–'
  backgroundColor: '#00000000'
```

**What was expected:** `backgroundColor` is an optional field — omitting it
produces exactly the "no highlight" effect both of these Grafana mappings
intended. `percli` should either omit `backgroundColor` when the source
Grafana color isn't a literal hex value, or translate theme keywords to the
dashboard's actual resolved theme color, rather than passing through a value
its own target schema will reject:
```yaml
cellSettings:
- condition:
    kind: Value
    spec:
      value: '-1'
  text: Not tracked
- condition:
    kind: Misc
    spec:
      value: 'null'
  text: '–'
```

---

## 8. Grafana field-level date/time unit overrides are dropped with no Perses equivalent set

**Summary:** Grafana field overrides with `unit: "time:YYYY-MM-DD"` (or
similar custom moment-format units) tell Grafana to render a raw numeric
value — in our dashboards, always epoch-milliseconds — as a formatted date.
`percli` drops this override entirely; the resulting `columnSettings` entry
has no `format` key at all, so Perses falls back to displaying the raw
number (e.g. `1808308800000`) instead of a date.

**Source (Grafana field override on a "Phase ends" column computed as an
epoch-millisecond expression):**
```json
{
  "fieldConfig": {
    "overrides": [
      {
        "matcher": { "id": "byName", "options": "Phase ends" },
        "properties": [ { "id": "unit", "value": "time:YYYY-MM-DD" } ]
      }
    ]
  }
}
```

**What was generated:**
```yaml
- name: 'value #4'
  header: Phase ends
  hide: false
```

**What was expected** (Perses' column `format.unit` schema, per
`perses/shared`'s `cue/common/format.cue`, supports `unix-timestamp-ms`
specifically for this case):
```yaml
- name: 'value #4'
  header: Phase ends
  hide: false
  format:
    unit: unix-timestamp-ms
```

---

## 9. Grafana's `groupingToMatrix` transform is silently dropped, leaving a broken panel with dangling column references

**Summary:** Grafana's `groupingToMatrix` transformation pivots query results
— one label becomes the row key, another label's distinct values become
columns, and a third field becomes each cell's value. `percli` does not
support this transform and drops it from the output with **no warning or
error of any kind**. The underlying query is still converted normally, but
the panel's `columnSettings` (carried over from the *post-pivot* Grafana
column names) reference columns that no longer exist anywhere in the
(un-pivoted) output, and no `transforms` block is emitted at all. The result
is a seemingly valid, schema-correct `PersesDashboard` panel that silently
renders nothing useful — there is no indication that a transform was dropped.

**Source (Grafana panel pivoting `ocp_lifecycle_ocp_version_phase_end_timestamp_seconds`
by `phase`, with `ocp_version` as the row key):**
```json
{
  "title": "OpenShift minors: phase end dates",
  "transformations": [
    {
      "id": "groupingToMatrix",
      "options": {
        "columnField": "phase",
        "rowField": "ocp_version",
        "valueField": "Value"
      }
    },
    { "id": "organize", "options": { ... } }
  ],
  "targets": [
    {
      "expr": "(max by (ocp_version, phase) (ocp_lifecycle_ocp_version_phase_end_timestamp_seconds{cluster=~\"$cluster\"}) + 43200) * 1000"
    }
  ]
}
```

**What was generated:**
```yaml
queries:
- kind: TimeSeriesQuery
  spec:
    plugin:
      kind: PrometheusTimeSeriesQuery
      spec:
        query: (max by (ocp_version, phase) (ocp_lifecycle_ocp_version_phase_end_timestamp_seconds{cluster=~"$cluster"}) + 43200) * 1000
columnSettings:
- name: ocp_version
  header: Minor
- name: 'Full support'
  header: Full support
- name: 'Maintenance support'
  header: Maintenance support
# ... one entry per Grafana post-pivot column, none of which exist in the
#     un-pivoted raw data
# (no `transforms:` block emitted at all)
```

**What was expected:** At minimum, a clear warning in `percli`'s output (and
ideally a comment left in the generated YAML) stating that a
`groupingToMatrix` transformation could not be converted and was dropped, so
the user knows the panel requires manual remediation. There is no direct
Perses equivalent for a dynamic pivot, so a full automatic fix isn't
expected — but silent, warning-free data loss resulting in a broken panel is
the core issue. (Our manual remediation: rewrite the single pivoting query as
N queries, one per distinct value of the pivoted-on label, each still
grouped by the row label, and join them back together with
`JoinByColumnValue` on that row label — see this folder's `README.md` for the
full pattern.)

---

## Environment used to reproduce

- `percli`/`perses` version: `0.54.0` (Linux amd64 release tarball)
- Migration mode: `percli migrate -f <dashboard.json> --online --format cr -o yaml --project <namespace>`, against a disposable local `persesdev/perses:v0.54.0` server (no auth)
- Target CRD actually deployed: Perses Operator `perses.dev/v1alpha2` `PersesDashboard`, as shipped by the Cluster Observability Operator / Red Hat ACM's `multicluster-observability-addon`
- Source dashboards: Grafana `schemaVersion` 16–39, exported at various points over several years
