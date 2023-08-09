The cluster-maintenance policies provide a process to manage a cluster long term. 
These policies will review RoleBindings, groups and other objects to find out of date cruft and clean itfrom th cluster

Policies:
  - clean-clusterrolebinding: Will find `ClusterRoleBindings` that reference Users, Groups and ServiceAccounts which no longer exist.  This will either remove the CRB if that is the only subject or replace the CRB.
  - clean-rolebinding: Similar function to `clean-clusterrolebinding` except cleans namespace based rolebindings
  - clean-groups: Will find `Groups` that are empty or reference users which no longer exist.  This will either remove the `Group` or will remove the user which is no longer in the cluster.
  - clean-marketplace-jobs: The `openshift-marketplace` namespace contains a series of `Jobs` created during the install and upgrade of Operators from the OpenShift Operator Hub.  These jobs are never deleted from the cluster.  In addition there is a corresponding `ConfigMap`, `Role`, and `RoleBinding`.  The policy will remove the `ConfigMap` which due to owner references will cause the deletion of the other objects.  **Note:** this will only remove successfully completed jobs.