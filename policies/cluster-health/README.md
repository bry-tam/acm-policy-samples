The purpose of this policy is to validate the OCP cluster is healthy.  This should be a single point to validate the cluster is:
- updated to the version specified
- all ClusterOperators are at that version and reporting healthy
- all MachineConfigPools are healthy (not progressing, not degraded)
- all nodes are healthy and schedulable
  - updated to the rendered config matching the MCP
  - are managed by an MCP
-
