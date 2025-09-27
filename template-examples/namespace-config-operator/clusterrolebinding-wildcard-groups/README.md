# ClusterRoleBinding Wildcard Groups/Subjects
This example is based on [RFE-6477](https://issues.redhat.com/browse/RFE-6477).

The request is to use a label selector on `Namespaces` within a cluster, and generate a `CusterRoleBinding` where the name of the subjects are some prefix - namespace - suffix.  In the `NamespaceConfig` it would be something like `ocp-dev-{{ .Name }}-view`.  The problem created by this is when there are thousands of application namespaces, NCO creates thousands of `ClusterRoleBindings` with one subject each all referencing the same role.

#### Example NamespaceConfig from RFE
  ```
  apiVersion: redhatcop.redhat.io/v1alpha1
  kind: NamespaceConfig
  metadata:
    name: cluster-reader-view-test
  spec:
    labelSelector:
      matchLabels:
        deployer: "edit"
    templates:
    - objectTemplate:  |
        apiVersion: rbac.authorization.k8s.io/v1
        kind: ClusterRoleBinding
        metadata:
          name: cluster-view-{{ .Name }}
        roleRef:
          kind: ClusterRole
          apiGroup: rbac.authorization.k8s.io
          name: namespace-config-operator-cluster-reader-custom
        subjects:
        - kind: Group
          apiGroup: rbac.authorization.k8s.io
          name: ocp-dev-{{ .Name }}-view
  ```

ACM gives some options on how to improve this.

First option, [group-name-matches-namespace.yml](group-name-matches-namespace.yml) creates a single `ClusterRoleBinding` based on the name of the namespaces which contains the labelSelector.  This closely matches the original `NamespaceConfig`.
Key differences:
  1. The prefix ocp-dev is replaced with the value from the "env" `ClusterClaim`.  This would allow the single policy to have different groups based on the environment designation of the cluster.
  2. The subjects list will remove any namespace that no longer exists, or is not labeled as expected.
  3. In the event the namespace lookup returns nothing the subject is configured with an empty list.

Second option, [group-name-matches-groups.yml](group-name-matches-groups.yml) creates a single `ClusterRoleVinding` based on the name of the groups in the cluster.  Unlike the previous example this would evaluate the name of the group to a RegEx which would allow for wildcard naming as specified in the RFE.  This is included separately since it doesn't match the behavior of the example `NamespaceConfig`.
Key differences:
  1. The prefix ocp-dev is replaced with the value from the "env" `ClusterClaim`.  This would allow the single policy to have different groups based on the environment designation of the cluster.
  2. Groups with a matching name are stored in a variable.  This is then applied to the `ClusterRoleBinding`
  3. In the event the group list is empty the subject is configured with an empty list.
