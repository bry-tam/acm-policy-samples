# MetalLB Operator - Subscription Name Check
Demonstrates how to clean up incorrectly-named OLM Subscriptions before installing an operator,
using MetalLB as the concrete example.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [MetalLB](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/networking/load-balancing-with-metallb)

#### **Policy layout**
| Policy | Description |
|--------|-------------|
| `metallb-sub-namecheck` | Loops over all Subscriptions in the operator namespace and removes any where `spec.name` matches the package name but `metadata.name` does not. Also removes any `ClusterServiceVersion` whose name starts with the package name. |
| `metallb-operator` | Installs MetalLB Operator pinned to a specific CSV. Depends on `metallb-sub-namecheck` being Compliant. |

---
**Notes:**
  - OLM operators are identified by `spec.name` (the package name), but `metadata.name` is user-supplied and not required to match. This example enforces consistency between the two.
  - Pinned to `metallb-operator.v4.19.0-202604072219` via `upgradeApproval: Automatic` and `spec.versions`. Update both fields in `operatorpolicy.yml` to advance to a new release.
  - Two variables at the top of `subscription-name-check.yml` control the cleanup target: `$pkgName` (OLM package name) and `$opNamespace` (namespace where the Subscription lives).
