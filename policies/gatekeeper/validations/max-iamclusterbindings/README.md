## Introduction
This Gatekeeper Policy is intended to match the behavior of the deprecated ACM IAMPolicy Controller.  It will allow an administrator to monitor and alert if `ClusterRoleBindings` with the specified `ClusterRole` exceed the maximum number of users.  In the case where a Group is specified in the `ClusterRoleBinding` the number of users in the group are counted.  ServiceAccounts are ignored.

## Prerequisites
The Policy makes use of sync data from the cluster to have knowledge of the existing `ClusterRoleBindings` and `Groups`.  To make this data available create a `Config` in the Gatekeeper Operator namespace, this is `openshift-gatekeeper-system` by default.

The config needs to be named "config", there can only be one.  To avoid dealing with arrays and merge issues, in this sample repo the sync config is managed with the operator in [../../../operators/gatekeeper/sync-configmap.yml](../../../operators/gatekeeper/sync-configmap.yml).  Below is an example of the sync config required for this Policy.  Note you should also enable the `auditFromCache` in the gatekeeper instance.

```
apiVersion: config.gatekeeper.sh/v1alpha1
kind: Config
metadata:
  name: config
  namespace: "openshift-gatekeeper-system"
spec:
  sync:
    syncOnly:
      - group: "rbac.authorization.k8s.io"
        version: "v1"
        kind: "ClusterRoleBinding"
      - group: "user.openshift.io"
        version: "v1"
        kind: "Group"
```
