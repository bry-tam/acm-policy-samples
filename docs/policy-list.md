# Policy list and details
This doc gives a listing of all policies in the repo along with a brief description

**Table of Contents:**
- [Policy list and details](#policy-list-and-details)
  - [ACM Configuration](#acm-configuration)
  - [Application Defaults](#application-defaults)
  - [Cluster Configuration](#cluster-configuration)
  - [Cluster Health](#cluster-health)
  - [Cluster Validations](#cluster-validations)
  - [Cluster Maintenance](#cluster-maintenance)
  - [Gatekeeper](#gatekeeper)
  - [Operators](#operators)


[//]: # (Editor notes)
[//]: # (All policies should be listed alphabetical and where possible the table | should be aligned with the header row)

## ACM Configuration
  | Policy                                                                            | Description   |
  |--------                                                                           |-------------  |
  | [ACM Observability](../policies/acm-configs/observability/)                       | Configures ACM Observability with ODF Storage. |
  | [ClusterAddonConfig Resources](../policies/acm-configs/cluster-addon-config/)     | Ensures governance-framework and config-policy-controller deployments have resource requests and limits set. Used when pods are in OOMKill status. |
  | [Debug OCP Cluster](../policies/acm-configs/set-cluster-debug-mode/)              | Allows adding a label to the `ManagedCluster` to enable a debug mode. During this condition ACM ConfigurationPolicies and OperatorPolicies will not be enforced. Defaults to a 2 hour time limit. |
  | [Ensure Placement Tolerations](../policies/acm-configs/ensure-placement-toleration/) | Ensures all `Placement`s have proper tolerations configured. |
  | [Feature Flag Placements](../policies/acm-configs/feature-flags-placement/)       | Creates `Placement`s based on a naming convention that encodes label selectors in the placement name, allowing PolicyGenerator to reference placements that don't exist yet. |
  | [Klusterlet Infra NodeSelector](../policies/acm-configs/klusterlet-infra/)        | Moves ACM components deployed on `ManagedClusters` to infra nodes when the cluster has dedicated infra nodes. |
  | [kubeadmin Config CA Trust](../policies/acm-configs/kubeadmin-config-trustca/)    | Updates the kubeadmin secret for `ManagedClusters` to include the CA from the Global Cluster Proxy so ACM maintains trust when the API cert is updated to a corporate certificate. |
  | [Managed ServiceAccount](../policies/acm-configs/managedserviceaccount/)          | Ensures the ManagedServiceAccount add-on component is enabled. |
  | [Multicluster CoreDNS Service Data](../policies/multicluster-data/)               | Aggregates CoreDNS LoadBalancer endpoints from service-mesh-federation clusters via `ManagedClusterView` and distributes the resulting DNS configuration secret to all clusters. |
  | [Policy Alerts](../policies/acm-configs/policy-alerts/)                           | Creates an example `PrometheusRule` that generates an alert for every non-compliant Policy. |
  | [Remove kubeadmin Password](../policies/acm-configs/remove-kubeadmin-pass/)       | Removes the kubeadmin password and reference from `ClusterDeployment`. |

## Application Defaults
  | Policy                                                                            | Description   |
  |--------                                                                           |-------------  |
  | [App Reload](../policies/application-defaults/app-reload/)                        | Enables automatic Deployment reloads when watched ConfigMaps or Secrets are updated, based on the Reloader pattern. |
  | [Default Block-All Network Policy](../policies/application-defaults/network-policies/) | Ensures every application namespace has a default-deny `NetworkPolicy` blocking cross-namespace ingress. Runs in inform mode; namespaces opt in to allowed ingress via a label. |
  | [Multi-cluster GitOps with ACM](../policies/application-defaults/gitops-multicluster/) | Creates a GitOps instance using ManagedServiceAccount and ClusterPermissions to authorize an application team to manage objects across multiple ManagedClusters from a single ArgoCD instance. |

## Cluster Configuration
  | Policy                                                                            | Description   |
  |--------                                                                           |-------------  |
  | [API Server Certificate](../policies/cluster-configs/apiserver-cert/)             | Configures a custom named certificate on the OpenShift API server using a cert-manager `Certificate`, waiting for readiness before patching the API server. |
  | [Cluster Autoscaling](../policies/cluster-configs/cluster-autoscaling/)           | Configures OpenShift cluster autoscaling using `ClusterAutoscaler` and `MachineAutoscaler` resources with min/max replicas driven by MachineSet labels. |
  | [Cluster Monitoring](../policies/cluster-configs/monitoring/)                     | Configures OpenShift cluster monitoring and user-workload monitoring, with MCOA and non-MCOA variants. |
  | [Cluster Proxy](../policies/cluster-configs/cluster-proxy/)                       | Manages the cluster-wide HTTP proxy configuration and root CA bundle. |
  | [Cluster Version](../policies/cluster-version/)                                   | Ensures admin acknowledgements for Kubernetes API removals are present before upgrades, with an optional policy for TALM-orchestrated cluster version upgrades. |
  | [ClusterClaims](../policies/cluster-configs/clusterclaims/)                       | Configures ACM `ClusterClaim` resources that expose cluster metadata as labels on the `ManagedCluster` for use in placements and policy templates. |
  | [Default Scheduler](../policies/cluster-configs/default-scheduler/)               | Configures the cluster scheduler profile and applies node labels to direct workloads to appropriate nodes. |
  | [etcd Backup](../policies/cluster-configs/etcd-backup/)                           | Deploys an automated etcd backup solution as a `CronJob` writing snapshots to a `PersistentVolumeClaim`. |
  | [etcd Encryption](../policies/cluster-configs/etcd-encryption/)                   | Enables etcd data-at-rest encryption and monitors each API server component for encryption rollout completion. |
  | [Image Registry](../policies/cluster-configs/image-registry/)                     | Configures the OpenShift internal image registry to use ODF S3 object storage via NooBaa. |
  | [Ingress](../policies/cluster-configs/ingress/)                                   | Manages the default OpenShift `IngressController` configuration and issues a custom TLS certificate using cert-manager. |
  | [Ingress Renew Default Certificate](../policies/cluster-configs/ingress-renew-default-cert/) | Monitors default ingress router certificate expiry and automatically rotates the router secrets and restarts router pods when expiration is within 750 hours. |
  | [KubeletConfig](../policies/cluster-configs/kubeletconfig/)                       | Applies custom `KubeletConfig` resources to tune kubelet settings on master and worker node pools. |
  | [MachineConfigPools](../policies/cluster-configs/machineconfigpools/)             | Defines custom `MachineConfigPool` resources for infra and storage node roles. |
  | [MachineSets](../policies/cluster-configs/machinesets/)                           | Creates dedicated `MachineSet` resources for infra and storage node roles for workload isolation. |
  | [Node Configuration](../policies/cluster-configs/nodes/)                          | Applies base node-level configuration via `MachineConfig` resources, covering cgroup version and CRI-O runtime settings. |

## Cluster Health
  | Policy                                                                            | Description   |
  |--------                                                                           |-------------  |
  | [Cluster Health](../policies/cluster-health/)                                     | Validates the OCP cluster is healthy by checking cluster version, ClusterOperators, MachineConfigPools, and node status. |

## Cluster Validations
  | Policy                                                                            | Description   |
  |--------                                                                           |-------------  |
  | [Cluster Validations](../policies/cluster-validations/)                           | Monitors OLM operator lifecycle health (failed InstallPlans, Subscriptions, and bundle Jobs) and validates that FIPS mode is not enabled. |

## Cluster Maintenance
  | Policy                                                                            | Description   |
  |--------                                                                           |-------------  |
  | [Cluster Node Reboot](../policies/cluster-maintenance/node-reboot/)               | Forces a full cluster reboot of all nodes by monitoring `ClusterNodeReboot` instances and evaluating cluster health before proceeding. |

## Gatekeeper
  | Policy                                                                            | Description   |
  |--------                                                                           |-------------  |
  | [Max Dev Workspaces](../policies/gatekeeper/validations/max-devspaces/)           | Deploys a Gatekeeper `ConstraintTemplate` and `Constraint` to cap the number of concurrently active `DevWorkspace` instances per cluster. |
  | [Max IAM Cluster Bindings](../policies/gatekeeper/validations/max-iamclusterbindings/) | Monitors and alerts when `ClusterRoleBindings` for a given `ClusterRole` exceed the maximum number of users, replacing the deprecated ACM IAMPolicy Controller. |
  | [Verify Deprecated API](../policies/gatekeeper/validations/verify-deprecatedapi/)     | Deploys Gatekeeper constraints that block admission of resources using deprecated Kubernetes API versions, gated per Kubernetes minor version. |

## Operators
  | Policy                                                                            | Description   |
  |--------                                                                           |-------------  |
  | [Advanced Cluster Management Operator](../policies/operators/acm/)                | Deploys ACM Operator and `MultiClusterHub`. |
  | [Advanced Cluster Security Operator](../policies/operators/acs/)                  | Deploys ACS Operator and creates `Central` on the hub and `SecureCluster` on managed clusters. |
  | [Ansible Automation Platform Operator](../policies/operators/ansible-automation-platform/) | Deploys AAP and creates a full instance including AAP Gateway. |
  | [CA ClusterIssuer](../policies/operators/cert-manager/ca-clusterissuer/)          | Sample `ClusterIssuer` for cert-manager using a self-signed CA; replace with your organization's PKI in production. |
  | [Cert-Manager Operator](../policies/operators/cert-manager/)                      | Deploys the cert-manager Operator, configures cluster CA trust, enables Prometheus monitoring, and deploys an example CA-backed `ClusterIssuer`. |
  | [Cluster Logging 5.x to 6.x Migration](../policies/operators/cluster-logging/logs-6.x-migration/) | Assists migration from OpenShift Logging 5.x to 6.x by removing old resources and CRDs to prevent conflicts with the 6.x API. |
  | [Cluster Logging Operator](../policies/operators/cluster-logging/)                | Deploys Cluster Logging Operator and configures `LokiStack` and `ClusterLogForwarder`. Includes an optional multi-cluster mode where managed clusters forward logs to a centralized Loki on the hub. |
  | [Cluster Observability Operator](../policies/operators/cluster-observability/)    | Deploys the Cluster Observability Operator and verifies health of each `UIPlugin` deployment. |
  | [Compliance Operator](../policies/operators/compliance-operator/)                 | Deploys the Compliance Operator and example `ScanSetting` and `ScanSettingBinding` using an extended profile. |
  | [Data Foundation Operator](../policies/operators/data-foundation/)                | Deploys ODF and configures a standalone MultiCloud Object Gateway for S3-compatible storage. Includes a health check covering operator deployments, `StorageCluster`, and `StorageSystem`. |
  | [Developer Hub Operator](../policies/operators/developer-hub/)                    | Deploys Developer Hub and connects all managed clusters. |
  | [External Secrets Operator (community)](../policies/operators/external-secrets/)  | Deploys the community release of the External Secrets Operator. |
  | [File Integrity Operator](../policies/operators/file-integrity/)                  | Deploys the File Integrity Operator and configuration to scan all nodes. |
  | [Gatekeeper Operator](../policies/operators/gatekeeper/)                          | Deploys Gatekeeper Operator and configures a `Gatekeeper` instance with metrics and sync. |
  | [Kiali Operator](../policies/operators/kiali/)                                    | Deploys the Kiali Operator for service mesh topology visualization; `Kiali` instance is configured by the Service Mesh policy. |
  | [Loki Operator](../policies/operators/loki/)                                      | Deploys the Loki Operator. |
  | [Migration Toolkit for Virtualization Operator](../policies/operators/migration-toolkit/) | Deploys the MTV Operator and a `ForkliftController` instance into the `openshift-mtv` namespace. |
  | [Network Observability Operator](../policies/operators/network-observability/)    | Deploys Network Observability Operator and configures `LokiStack` and `FlowCollector`. |
  | [Open Telemetry Operator](../policies/operators/opentelemetry/)                   | Deploys the OpenTelemetry Operator with `ClusterRole` and `ClusterRoleBinding` for the collector; `OpenTelemetryCollector` instances are configured per environment. |
  | [OpenShift GitOps Operator](../policies/operators/gitops/)                        | Deploys GitOps Operator and configures cluster and namespace `ArgoCD` instances via kustomize overlays. On the hub, adds the PolicyGenerator plugin and `ManagedClusterSetBinding` resources for multi-cluster `ApplicationSet` targeting. |
  | [OpenShift Pipelines Operator](../policies/operators/tekton/)                     | Deploys the OpenShift Pipelines Operator with automated cleanup and pull-secret propagation. |
  | [OpenShift Service Mesh Operator](../policies/operators/servicemesh/)             | Deploys Service Mesh 3.x Operator and configures a cluster-wide Istio control plane with IstioD, Kiali, Tempo distributed tracing (ODF S3), OpenTelemetry collection, and a standalone ingress gateway. |
  | [OpenShift Virtualization Operator](../policies/operators/virtualization/)        | Deploys the OpenShift Virtualization Operator and a `HyperConverged` instance configured for live migration over a dedicated network interface. |
  | [Portworx Operator](../policies/operators/portworx/)                              | Deploys the Portworx certified storage operator into the `portworx` namespace and enables the console plugin. |
  | [Secondary Scheduler Operator](../policies/operators/secondary-scheduler/)        | Deploys the secondary scheduler operator and an example secondary scheduler configuration. |
  | [Tempo Operator](../policies/operators/tempo/)                                    | Deploys the Tempo (Distributed Tracing) Operator; `TempoStack` instance is configured by the Service Mesh policy. |
  | [Topology Aware Lifecycle Manager Operator](../policies/operators/talm/)          | Deploys the TALM Operator for managing cluster lifecycle updates at the edge. |
  | [Web Terminal Operator](../policies/operators/webterminal/)                       | Deploys the Web Terminal Operator, enabling in-browser terminal access via `DevWorkspace` instances in the OpenShift console. |
  | [Workload Availability Operator](../policies/operators/workload-availability/)    | Deploys Node Health Check, Self Node Remediation, Fence Agents Remediation, and Machine Deletion Remediation with example remediation configurations. |


[//]: # (Example Table layout)
[//]: # (  | Policy                                                                            | Description   |  )
[//]: # (  |--------                                                                           |-------------  |  )
