#  ACM Feature Flag Placements

## Description
Automatically creates `Placement` resources for any `PlacementBinding` that references a placement
following the `ft-<label>--<value>` naming convention. This removes the need to manually define
feature-flag placements — they are generated dynamically from the naming convention alone.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: None

Notes:
  - Deployed to hub only
  - Only creates Placements for bindings whose `placementRef.name` starts with `ft-`
  - The generated Placement inherits the `clusterSet` from an existing Placement in the same namespace
  - Use `exists` as the value to create an `Exists` operator selector (e.g. `ft-logging--exists`)

## Implementation Details
A hub-side template ranges over all `PlacementBinding` resources. For each binding whose
`placementRef.name` starts with `ft-`, the name is parsed using the `ft-<key>--<value>` convention:

- The `ft-` prefix is stripped (only the leading occurrence, via `trimPrefix`) and the remainder is
  split on `--`
- The left part becomes the label `key` for the cluster selector
- The right part becomes the label `value`; if the value is `exists`, an `Exists` operator is used
  instead of `In`, which means the label only needs to be present regardless of value

The generated Placement uses the `clusterSets` from the first existing Placement found in the same
namespace, so new feature-flag Placements automatically stay within the correct ClusterSet boundary.

**Example naming:**

| PlacementBinding placementRef | Generated selector |
|---|---|
| `ft-logging-type--Loki` | `logging-type In [Loki]` |
| `ft-ocp-virt--enabled` | `ocp-virt In [enabled]` |
| `ft-acm-hub--active` | `acm-hub In [active]` |
| `ft-gpu--exists` | `gpu Exists` |
| `ft-openshift-builds--enabled` | `openshift-builds In [enabled]` |

**Bug fixed:** the prefix used to be stripped with `replace "ft-" ""`, which removes *every* occurrence
of the substring `ft-` in the name, not just the leading prefix. For a feature key containing `ft-`
elsewhere (e.g. `openshift-builds`, where `...shift-builds` contains `ft-` right before the hyphen),
this silently mangled the label key (`ft-openshift-builds--enabled` became `openshibuilds In [enabled]`
instead of `openshift-builds In [enabled]`). Fixed by switching to `trimPrefix "ft-"`, which only
removes a literal leading prefix.
