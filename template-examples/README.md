# Template Examples
Within this directory you will find random templating examples.  These are not intended to be used as-is, instead you should use them as guidance to solve more complex issues.

## Examples
  | Policy                                                                            | Description   |
  |--------                                                                           |-------------  |
  | [Kustomize Monitoring Config](./kustomize-monitoring-config/)                     | Examples showcase how to manage the cluster-monitoring configmap with kustomize instead of an ACM Policy. |
  | [Hosted Control Plane example - Auth](./hostedcontrolplane-auth/)                     | Examples showcase how to manage HCP configuration on the hosted cluster using ACM Policies. |
  | [Multi-Cluster GitOps](./gitops-multicluster/)                                    | Examples showcase creating Argo instances for application teams which makes use of ACM `ManagedServiceAccounts` and `ClusterPermissions` for argo access to the managed clusters.  This limits the permissions and lets ACM rotate the access tokens automatically. |
  | [Namespace Configuration Operator](./namespace-config-operator/)                  | Examples showcase how to replace the unsupported Namespace Configuration Operator with ACM Policies.  Each example has more specific details outlining how to replace common usage of NCO with ACM Policies. |
  | [Template snippets](./snippets)                  | Examples showcase how to replace the unsupported Namespace Configuration Operator with ACM Policies.  Each example has more specific details outlining how to replace common usage of NCO with ACM Policies. |
