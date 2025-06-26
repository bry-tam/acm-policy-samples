# Gatekeeper Operator
Installs the Gatekeeper operator and instance of `Gatekeeper`.


## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/latest/html-single/governance/index#gk-operator-overview)
> Upstream documentation is very helpful

#### **Example Constraint annotation for sync data**
  > When creating a constraint you can add a annotation as a json string to configure the data to be synced.
  > ```
  > apiVersion: templates.gatekeeper.sh/v1
  > kind: ConstraintTemplate
  > metadata:
  >   name: maxdevworkspaces
  >   annotations:
  >     metadata.gatekeeper.sh/requires-sync-data: |
  >       "[
  >         [
  >           {
  >             "groups": ["workspace.devfile.io"],
  >             "versions": ["v1alpha2"],
  >             "kinds": ["DevWorkspace"]
  >           }
  >         ]
  >       ]"
  > ```

---
**Notes:**
  - Deploys to custom openshift-gatekeeper-operator namespace instead of documented openshift-operators.  The later causes issues when trying to manage manual install plan approval.  It is supported to use an alternate namespace and generally makes things easier in the long run.
  - Deploys additional policy that will alert if any Gatekeeper policy becomes non-compliant
  - Creates Service and ServiceMonitor for collecting metrics.  No alerting rules are created for Gatekeeper
  - Creates SyncSet to sync external data.
    - https://open-policy-agent.github.io/gatekeeper/website/docs/sync/
    - Operator has provision to automatically build syncset based on `auditFromCache: Automatic` setting.  This only syncs objects based on constraints.  It will miss if the policy needs a type that is not part of the constraint.
      - The downside is the SyncSet needs to include the objects in the constraint not just policy.
    - SyncSet is built from annotation in the constraint to allow control at the [constraint definition](#example-constraint-annotation-for-sync-data).
    - TODO: automatically include sync data from constraint definitions
