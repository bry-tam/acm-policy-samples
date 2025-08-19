# Namespace Configuration Operator examples
These examples will showcase how to replace common usage of NCO with ACM Polices.

  | NCO Example                                                                       | Description   |
  |--------                                                                           |-------------  |
  | [ClusterRileBinding Wildcard Groups/Subjects](./clusterrolebinding-wildcard-groups/)    | This example is based on [RFE-6477](https://issues.redhat.com/browse/RFE-6477). Policy will create a ClusterRoleBinding using the name of the namespace/groups as the subjects. |
