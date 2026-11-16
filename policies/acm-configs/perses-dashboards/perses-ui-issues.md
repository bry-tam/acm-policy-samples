---
# Perses UI/core issues: Table panel transform bugs and feature gaps

While building Table panels for the `ocp-lifecycle` dashboard in this folder,
we hit two distinct bugs in Perses' own Table transform implementation (not
anything `percli` generated incorrectly), plus one feature gap. All three are
documented here to be filed as upstream issues/RFEs against
[`perses/perses`](https://github.com/perses/perses) (core table transform/UI
behavior, implemented in [`perses/shared`](https://github.com/perses/shared)).

- Issue 1: `JoinByColumnValue` requires every per-query-suffixed column name
  to be listed explicitly, or it silently collapses every row into one.
- Issue 2: `MergeIndexedColumns`/`MergeColumns`, when run on rows that already
  have more than one matching indexed column present (e.g. after a
  `JoinByColumnValue` join), multiply the row instead of collapsing it.
- Issue 3 (RFE): Table panel `columnSettings.header` has no way to control
  text styling (e.g. bold), so column headers can't be visually emphasized
  from dashboard config.

---


The dashboards used for this issue can be found at:
- https://github.com/brian-jarvis/ocp-lifecycle-dashboard/blob/main/dashboards/ocp-lifecycle.json
- https://gitlab.cee.redhat.com/sbr-shift/metrics-dashboards/-/tree/main/dashboards?ref_type=heads

The inprogress migrated dashboards to be used with ACM MCOA can be found at:
- https://github.com/brian-jarvis/bry-acm-policy-samples/tree/implement-perses-dashboards/policies/acm-configs/perses-dashboards


## Issue 1: `JoinByColumnValue` requires every per-query-suffixed column name to be listed explicitly

### Summary

A Table panel with more than one query gets every label key — not just the
synthetic `value` column — suffixed with ` #<queryIndex+1>` before any
`transforms` run (this is documented/expected Perses behavior, confirmed in
`perses/plugins`, `table/src/table-data-utils.ts`,
`buildTimeSeriesTableData()`). However, the `Join by column value`
(`JoinByColumnValue`) transform's own `columns` option does **not** know
about this suffixing: it matches column names by exact string equality
against each row's actual (already-suffixed) keys. If a dashboard author
writes the obvious, intuitive config — `columns: [cluster]` — naming just the
bare label that every query groups by, the transform matches **zero** keys on
every row, which causes *every row in the table to silently collapse into a
single merged row*, with no error, warning, or any other indication that
anything went wrong. The only way to get correct behavior is to list every
per-query-suffixed instance of the join column(s) explicitly (e.g. `['cluster
#1', 'cluster #2', ..., 'cluster #9']` for a panel with 9 queries), which is
unintuitive, verbose, and easy to get subtly wrong (see "Why this is
dangerous" below).

### Source: the transform implementation

`perses/shared`, `components/src/utils/transform-data.ts`,
`applyJoinTransform()`:

```ts
export function applyJoinTransform(
  data: Array<Record<string, unknown>>,
  columns: string[],
): Array<Record<string, unknown>> {
  if (columns.length === 0) {
    return data;
  }
  const rowHashed: { [key: string]: Record<string, unknown> } = {};
  for (const row of data) {
    const rowHash = Object.keys(row)
      .filter((k) => columns.includes(k))
      .map((k) => row[k])
      .join('|');
    const rowHashedValue = rowHashed[rowHash];
    if (rowHashedValue) {
      rowHashed[rowHash] = { ...rowHashedValue, ...row };
    } else {
      rowHashed[rowHash] = { ...row };
    }
  }
  return Object.values(rowHashed);
}
```

`columns.includes(k)` is a plain exact-string match against each row's raw
object keys. It never strips, normalizes, or fuzzy-matches the
` #<queryIndex+1>` suffix that the panel's own data-building step
(`buildTimeSeriesTableData()` in `perses/plugins`,
`table/src/table-data-utils.ts`) unconditionally adds to every label key
whenever the panel has more than one query:

```ts
// If there are multiple queries, add query index to value key and label keys to avoid conflicts
const valueColumnName = queryResults.length === 1 ? 'value' : `value #${queryIndex + 1}`;
const labels =
  queryResults.length === 1
    ? ts.labels
    : Object.entries(ts.labels ?? {}).reduce((acc, [key, value]) => {
        if (key) acc[`${key} #${queryIndex + 1}`] = value;
        return acc;
      }, {} as Labels);
```

So by the time `applyJoinTransform` runs, a row never has a bare `cluster`
key to match against — only `cluster #1`, `cluster #2`, etc.

### What was generated / observed

Dashboard config (8 queries, all grouping by `cluster`, `operator_namespace`,
`package` among other per-query labels — see this folder's
`ocp-lifecycle-perses.yml` for the full panel):

```yaml
transforms:
- kind: JoinByColumnValue
  spec:
    columns:
    - join_key
```

(`join_key` here is itself a label synthesized via a PromQL `label_join(...,
"cluster", "operator_namespace", "package")` in every query, specifically to
work around `JoinByColumnValue` not supporting a true composite multi-column
key — but the underlying suffixing problem affects a single bare column name
just as much, e.g. the simpler `columns: [cluster]` case below.)

Live behavior: confirmed via direct Prometheus query against the dashboard's
own datasource that the underlying data genuinely contains 24 distinct
`join_key` values (one per installed operator). Despite this, the rendered
table — and a CSV export of it — always showed **exactly one row**. For every
row, `Object.keys(row).filter((k) => columns.includes(k))` evaluates to `[]`
(since every real key is suffixed, e.g. `join_key #1`..`#8`, and none of them
equal the bare string `join_key`), so `[].join('|')` produces the same empty
string `''` as the `rowHash` for all 24 rows, and the accumulating `{
...rowHashedValue, ...row }` spread silently merges all of them into one.

### Why this is dangerous (a second, worse manifestation)

A second panel in the same dashboard ("Clusters") was, at the time, assumed
to be working correctly with the simpler, intuitive config:

```yaml
transforms:
- kind: JoinByColumnValue
  spec:
    columns:
    - cluster
```

This panel also hits the exact same bug — `columns: [cluster]` matches
nothing against real rows keyed `cluster #1`..`cluster #9` — but it happened
to *look* correct, because this particular environment only has one managed
cluster. The "merge everything into one row" failure mode is
indistinguishable from the "correctly joined one row per cluster" success
case when there is only one cluster's worth of data. This makes the bug a
silent, **latent** data-correctness issue: it will not surface until a second
managed cluster (or any other dimension with >1 real value) is added, at
which point two clusters' rows would silently merge into one with no error.
A dashboard author relying on the `columns: [cluster]` form has no way to
detect this ahead of time short of already knowing to list the suffixed
variants.

### What was expected

Either of the following would resolve this:

1. **(Preferred)** `applyJoinTransform` (and any other transform/column
   config that accepts a bare column name) should match against the
   suffix-stripped form of each key, so `columns: [cluster]` correctly
   matches `cluster #1`, `cluster #2`, etc. across all of a panel's queries.
   This is the behavior a dashboard author would reasonably expect, since the
   panel's own `columnSettings` already requires this same suffixed-vs-bare
   distinction to be handled manually (see this folder's `percli-issues.md`,
   issue 5) — the join transform doing the same normalization internally
   would make the two mechanisms consistent.
2. **(Minimum)** If exact-match-only behavior is intentional, the transform
   should at minimum warn or error when `columns` contains a name that
   matches zero keys on every input row (a strong signal of exactly this
   misconfiguration), rather than silently collapsing all rows. The Table
   panel editor UI should also surface the *actual* available column names
   (i.e., the suffixed ones) when a user is choosing columns for a
   `JoinByColumnValue` transform, rather than requiring the user to infer the
   suffix naming convention from documentation/source.

What we had to configure in practice, to work around the bug today (listing
every per-query-suffixed instance of the join column explicitly):

```yaml
transforms:
- kind: JoinByColumnValue
  spec:
    columns:
    - 'cluster #1'
    - 'cluster #2'
    - 'cluster #3'
    - 'cluster #4'
    - 'cluster #5'
    - 'cluster #6'
    - 'cluster #7'
    - 'cluster #8'
    - 'cluster #9'
```

This is correct, but unintuitive (nothing in the Table panel editor UI or the
`JoinByColumnValue` documentation at
[perses.dev/plugins/docs/table](https://perses.dev/plugins/docs/table/)
mentions that bare column names must be manually expanded to every
per-query-suffixed variant), verbose (grows linearly with query count, up to
15 entries in one of our panels), and brittle (adding or removing a query
from the panel silently breaks the join unless every `columns` list in that
panel is updated to match the new query count — again with no warning if
missed).

### Environment used to reproduce

- Perses version: `v0.54.0` (confirmed as the pinned upstream version
  compiled into Red Hat's Cluster Observability Operator 1.5.3 downstream
  build, via `rhobs/konflux-coo`'s `release-1.5` branch `Dockerfile.perses`,
  `ARG VERSION=v0.54.0`)
- Reproduced both against a disposable local `persesdev/perses:v0.54.0`
  server and against the Red Hat downstream build shipped by Cluster
  Observability Operator 1.5.3 (`perses-rhel9` image) on an OpenShift/ACM
  cluster
- Affected panel type: Table (`perses/plugins`, `table` plugin)
- Affected transform: `Join by column value` (`JoinByColumnValue`)

---

## Issue 2: `MergeIndexedColumns`/`MergeColumns` multiply rows instead of collapsing them

### Summary

Both `MergeIndexedColumns` (`spec: {column: string}`) and `MergeColumns`
(`spec: {columns: string[], name: string}`) are documented/intended to collapse
several same-meaning indexed columns (e.g. `package #1`, `package #2`,
`package #3`, produced by a multi-query panel per Issue 1's suffixing
behavior) into a single column containing whichever value is actually present
on a given row. In the real implementation, when a row already has **more
than one** of those indexed keys present at once — which is exactly what
happens on a row that was just produced by a `JoinByColumnValue` join across
several queries — both transforms instead emit **one duplicate output row per
matching key**, silently multiplying every already-correctly-joined row.

### Source: the transform implementation

Found by fetching and reading the real minified JS actually served by the
cluster's Perses instance (`@perses-dev/core@0.53.0`, Module Federation chunk
`__mf/js/async/1117.b21b0ae4.js`, loaded via the `Table` plugin's
`mf-manifest.json`) rather than source on GitHub, since the deployed build is
a Red Hat downstream fork that can lag/diverge from upstream `main`. De-minified
for readability (`oA` = `MergeIndexedColumns`, `oT` = `MergeColumns`):

```js
// MergeIndexedColumns(column): for every row, find every key matching
// `^((<column> #\d+)|(<column>))$`, then push ONE NEW ROW PER MATCHING KEY.
function applyMergeIndexedColumnsTransform(rows, column) {
  const out = [];
  for (const row of rows) {
    const matchingKeys = Object.keys(row).filter((k) =>
      new RegExp(`^((${column} #\\d+)|(${column}))$`).test(k)
    );
    const extracted = {};
    for (const k of matchingKeys) {
      extracted[k] = row[k];
      delete row[k];
    }
    for (const k of matchingKeys) {
      out.push({ ...row, [column]: extracted[k] }); // <-- one row PER key
    }
    if (matchingKeys.length === 0) out.push(row);
  }
  return out;
}

// MergeColumns(columns, name): identical per-matching-key row multiplication,
// just against an explicit column list instead of a regex pattern.
function applyMergeColumnsTransform(rows, columns, name) {
  const out = [];
  for (const row of rows) {
    const matchingKeys = Object.keys(row).filter((k) => columns.includes(k));
    const extracted = {};
    for (const k of matchingKeys) {
      extracted[k] = row[k];
      delete row[k];
    }
    for (const k of matchingKeys) {
      out.push({ ...row, [name]: extracted[k] }); // <-- same bug
    }
    if (matchingKeys.length === 0) out.push(row);
  }
  return out;
}
```

If a row has exactly one matching key (the only case these transforms are
ever demonstrated for in the Table plugin's own placeholder text — "Example:
'value' for merging 'value #1', 'value #2' and 'value #...'" — which implies
a **set** of rows each with one key, not one row with several), this works as
documented: one key, one output row. But the natural, intended workflow —
`JoinByColumnValue` first (to merge a multi-query panel's per-query rows into
one row per entity), then `MergeIndexedColumns`/`MergeColumns` second (to
collapse that merged row's now-multiple surviving indexed columns into one
plain column) — guarantees the opposite: the join step's `{ ...rowHashedValue,
...row }` spread (see Issue 1) deliberately accumulates *every* matching
query's suffixed keys onto the single merged row, so by the time
`MergeIndexedColumns` runs, the row legitimately has 2+ matching keys. The
transform then treats that as "N separate rows to emit" instead of "N
candidate values to pick one from."

### What was generated / observed

`ocp-lifecycle-perses.yml`'s "Operator × OpenShift compatibility" panel (6
per-OCP-version queries, each grouping by `package`): after `JoinByColumnValue`
correctly merges each operator's per-version rows into one row per operator,
that row holds `package #1`, `package #2`, `package #3` (one per OCP version
the operator is compatible with). Running `MergeIndexedColumns(column:
"package")` on it produced **three duplicate rows** for that operator instead
of one — exactly matching the number of OCP versions it was compatible with.
Confirmed live in the dashboard UI (screenshot showed every visible operator
duplicated 2-3×, with identical data in every duplicate) and reproduced by
hand-tracing the real deployed implementation above against the panel's actual
query/transform config.

### What was expected

`MergeIndexedColumns`/`MergeColumns` should pick a single value when a row has
multiple matching indexed keys (e.g. first non-null, by stated precedence, or
documented "last wins"/"first wins" semantics) and emit exactly one row,
regardless of how many matching keys are present — not treat "more than one
match" as "more rows to emit." This is the only way the transform can be
safely chained after `JoinByColumnValue`, which is the obvious and, per the
Table plugin's own two-step UI (both transforms selectable from the same
dropdown in the same transform list), clearly an intended combination.

### Workaround used in this repo

Avoid `MergeIndexedColumns`/`MergeColumns` for this use case entirely. Instead
of relying on a post-join merge step to collapse `package #1..#N` into one
display column, add an extra, version-unconditional query that is guaranteed
to return every tracked entity regardless of which of the "real" per-column
queries matched (here: `max by (package) (ocp_lifecycle_operator_info{cluster=~"$cluster"})`,
with no `ocp_version` filter), then reference *that* query's suffixed column
directly as the visible name column (hiding the other N per-column-value
queries' duplicate name columns, same hidden-duplicate convention used
everywhere else in this dashboard for shared join-key labels). This sidesteps
the bug by never calling a transform that multiplies rows — `JoinByColumnValue`
alone, which our Issue 1 investigation already confirmed merges rows correctly
when every suffixed instance of the join column is listed, is sufficient.

### Environment used to reproduce

- Perses version: `v0.54.0` (Red Hat Cluster Observability Operator 1.5.3
  downstream build, same as Issue 1).
- Reproduced by reading the actual deployed JS directly from the live
  `perses-0` pod (`@perses-dev/core@0.53.0` Module Federation chunk), then
  hand-tracing it against the panel's real query/transform config and
  confirming the row count matched the predicted multiplication factor;
  additionally confirmed visually via a dashboard screenshot and the earlier
  symptom-matching (blank-name) CSV export from Issue 1's companion bug on the
  same panel.
- Affected panel type: Table (`perses/plugins`, `table` plugin).
- Affected transforms: `Merge indexed columns` (`MergeIndexedColumns`) and,
  by code inspection, `Merge columns` (`MergeColumns`) — not independently
  reproduced in a live dashboard, since this repo never needed it, but the
  bug is present in the exact same shape in the minified source.

---

## Issue 3 (RFE): Table panel column headers cannot be styled (e.g. bold)

### Summary

There is no way to make a Table panel's column header text bold (or apply any
other text styling) from dashboard configuration. The `Column Settings`
specification's `header` field is a plain string with no accompanying
style/weight option, and there is no panel-wide or dashboard-wide setting that
controls header font weight either. Header rendering appears to be a fixed
decision baked into the Perses UI/theme, not something a dashboard author can
influence.

### Source: the documented model

[`perses.dev/plugins/docs/table/model/`](https://perses.dev/plugins/docs/table/model/),
Column Settings specification:

```
name: <string> # Required
header: <string> # Optional
headerDescription: <string> # Optional
cellDescription: <string> # Optional
plugin: <Plugin specification> # Optional
format: <Format specification> # Optional
align: <enum = "left" | "center" | "right"> # Optional
enableSorting: <boolean> # Optional
sort: <enum = "asc" | "desc"> # Optional
width: <anyOf = number | "auto"> # Optional
hide: <boolean> # Optional
dataLink: <Data Link specification> # Optional
```

No field anywhere in this spec (or in the sibling `Cell Settings`/`Format`
specs) controls font weight, style, or any other header text presentation.

### What was generated / observed

We wanted to bold all column headers across the `ocp-lifecycle` dashboard's
Table panels for readability. There is no `columnSettings` field, panel-level
`Table` plugin option, or dashboard-level setting to express this — it simply
cannot be configured.

### What was expected

A way to mark a column's header (or all headers in a panel, or all headers in
a dashboard) as bold/emphasized — e.g. an optional `headerStyle` field on
Column Settings (`{fontWeight: "bold" | "normal" | ...}`), or support for
lightweight markup (e.g. Markdown `**bold**`) in the `header` string itself,
similar to how some other dashboarding tools treat panel/column titles.

### Workaround used in this repo

None available. This is purely a feature gap, not a bug with a workaround —
recorded here to be filed as an RFE rather than acted on in
`ocp-lifecycle-perses.yml`.

### Environment used to reproduce

- Perses version: `v0.54.0` (Red Hat Cluster Observability Operator 1.5.3
  downstream build, same as Issues 1 and 2).
- Confirmed against the published model documentation
  ([`perses.dev/plugins/docs/table/model/`](https://perses.dev/plugins/docs/table/model/))
  rather than the deployed JS, since this is an absence of a documented
  feature rather than a runtime bug.
- Affected panel type: Table (`perses/plugins`, `table` plugin).
