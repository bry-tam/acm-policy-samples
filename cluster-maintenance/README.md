The cluster cleaner policies provide a process to manage a cluster long term. 
These policies will review RoleBindings, groups and other objects to find out of date cruft and clean itfrom th cluster

Policies:
  - cluster-cleaner-clusterrolebinding:  Will find `ClusterRoleBindings` that reference Users, Groups and ServiceAccounts which no longer exist.  This will either remove the CRB if that is the only subject or replace the CRB.