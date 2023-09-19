# acm-policy-samples

RHACM sample policies meant to showcase best practices.

## Background
Many users have requirements that Policy changes should be deployed to Dev --> QA --> Prod clusters in sequence to allow testing.  Many also require a workflow that allows blocking changes except during maintenance windows.

These customer requirements are in contradiction to basic GitOps practices and ACM functionaltiy.  RHACM does not have a control process that enables managing changes to Policies through the managed cluster environments.  Further most GitOps practioners recommend against using branches to control change.  When we have RHACM `Policies` that should be applied to every cluster we want to use all of the tooling in the best way possible to meet our requirements while at the same time following GitOps and code maintenance best practices.  When a new Policy that deployed to all clusters is created, or an existing edited, we want to make sure those changes can be controlled where and when they are deployed.

Additionally we don't want to have to manage multiple copies of the same Policy, such as using directories would cause.  We want to have a little friction between the Policy definition itself and the business rules used to determine when/where a Policy is applied.

## Solution outline
This repo has been setup to highlight my recommendations for RHACM configuration, code change management practices, and policy standards.

Goals:
  - The configuration of RHACM should be consistent with the code change workflow
  - Policy placement should be flexible enough to allow controlling where a Policy is deployed without having to create placements and policies in a 1:1 ratio.  We want to adhere to a practice of simple reusable placements.
  - Follow a GitOps approach to managing all code
  - All Policies should use the PolicyGenerator and be included in a PolciySet.
  

## General repo layout
```
.
├── environments
│   └── prod
│       └── kustomize-configs
│   └── dev
│       └── kustomize-configs
├── kustomize-configs
├── local-cluster
├── policies
│   ├── acm-placements
│   ├── application-defaults
│   ├── cluster-configs
│   ├── cluster-maintenance
│   ├── cluster-validations
│   ├── cluster-version
│   ├── gatekeeper
│   ├── kustomize-configs
│   └── operators
└── README.md (this file)
```

The file structure is based on a typical kustomize enviroment.  There are kustomize configurations (will be discussed later) which help tie everything together.  The assumption is all deployments are done through one of the environments subdirectories.

 - policies: Holds the Policy definitions.  It is expected most if not all policies would be applied to all environments.  This means Policies should have business logic defined in them such that the same policy deployed to QA and Prod would exhibit expected behaviors.  This also allows testing the logic as policies are moved between environments. 
 - environments/ENVIRONMENT_NAME: holds the kustomize overlay for specified environment.  Here we set the namespace name to deploy the policies in, the suffix for the PoliySet naming override., and the ClusterSet to select the array of clusters to be considered as targets for that environments placements.
 - local-cluster: Should only be included in the environment which the ACM hub is expected to be managed. This would typically be "prod".  Configuration here would change the behavor of the ACM Hub `ManagedCluster` object to include it in the ClusterSet created as part of the environment.

## RHACM Cluster structure
Each cluster should be included in a ClusterSet that matches the environments/ENVIRONMENT_NAME which is targetting them.  In this demo repo I use the naming convention of "ENVIRONMENT_NAME-clusters".  You could expand from the simple dev, qa, prod naming used here as required for additional separation and control.  As a general rule all clusters in the ClusterSet should be able to have a change applied at the same time.  

To control subsets of clusters allowing specific features we will use labels applied to the `ManagedCluster`.  Here features would be a PolicySet which could be a specific configuration or operator or some such.  For example if we wanted to introduce a change to switch from the ElasticSearch logging stack to Loki we would introduce a feature flag label `logging-type=ElasticSearch|Loki`.  In preparation for use of this feature all clusters would be given the `logging-type=ElasticSearch` label.  Then as we want to change the logging a simple change to the label would be applied during the specified maintenance time period.


## Managing changes between environments and naming conventions
 Using a kustomize approach with appropriate branches allows a better workflow when moving changes between environments.  Assuming one ACM Hub will manage all clusters this appraoch allows the same policy to be reused for each environment.  Branches allow us to control when changes to the policy are perculated through the stack.

 The name of the Policies will not change between environments, however they will be deployed to a separate namespace and PolicySet.  Each PolicySet will point to a Placement of the same name, however the ClusterSet targetted will control which clusters are deployed to.  There are a small set of Placements which encompass the following selectors:
 - All clusters
 - All clusters labeled env=dev
 - Hub only: cluster name is local-cluster
 - All clusters except Hub: cluster name is not local-cluster

In addition there is a Hub Policy that will generate Placements for the feature flag based PolicySets.  This is accomplished by specifying the name of the Placement in the PolicyGenerator in the format of "ft-<LabelName>--<LabelValue>".  For the above logging-type example, the Placement name in the generator would be "ft-logging-type--Loki".

The intersection between the choosen Placement and the clusters in the ClusterSet will determine which clusters are deployed to.

 Each environment will consist of the following items:
 - ClusterSet containing all clusters in that environment
 - Directory in the `environments` folder specifying the namespace name, ClusterSet name and other details specific to that environment.
 - Branch in the source repo used to provide the source of truth for the Policies deployed.

## Kustomization configurations
There are a number of configurations controlling behavior of kustomize included to make the process more complete and easier to implement.  Notice there is little information in the specific environments/ENVIRONMENT_NAME kustomizations.

Kustomize configurations and purpose:
- **environments/ENVIRONMENT_NAME/kustomize-configs/policyset-suffixer.yml** - Specifies the suffix to be applied to all PolicySets generated by the PolicyGenerators.  This is used over the `suffix` specification in kustomize to control that it is only applied to the PolicySets
- **kustomize-configs/set-clusterset-references.yml** - Updates the clusterset specification label on the ManagedCluster (local-cluster) if included.  Also updates the clusterset specification on all Placements and ManagedClusterSetBindings.  Sets the name of the ManagedClusterSetBinding to match the name of the ClusterSet per RHACM requirements.
- **policies/kustomize-configs/namespace-namereference.yml** - Updates all dependencies specified in Policies with the Namespace specified in the environment.
- **policies/kustomize-configs/policyset-namereference.yml** - Updates the PolicySet name in all PlacementBinding to correct for name changed by the suffix specified in the environment.

## Example workflow 
New Policies and changes to existing Policies are expected to go through a similar workflow
1. Repo forked to Policy developer or administrator
2. In forked repo create a working branch from the first environment, Dev for this example
3. Add/Edit Policies in base directory, commit to forked repo working branch
4. Create a PR to the Dev environment
    forked working branch --> parent repo Dev branch
5. Review and approve/merge PR to Dev branch
6. In working repo create branch from QA branch.
7. Cherry pick changes from original working branch (or Dev branch if change PR has been merged)
8. Repeat steps #4 & 5 merging change to QA branch in parent repo
   forked working QA branch --> parent repo QA branch

## Limitations with this approach
Because this is meant to be a more simplistic and opinionated approach there are assumptions made in how clusters are configured and managed.  This repo example will use the following rules and guidelines for managing changes.
- All clusters in all environment have the same configuration. 
  - The only deviation from this is "Dev" environment as you may want developer tooling available such as `OpenShift Pipelines` that should not be available in other environments.
- All clusters are updated at the same time.  If you want to control when different clusters in the same environment are updated you should treat those clusters as separate environments.  QA1 and QA2 for example.  This will increase the overhead of managing the policy code and branches but would give you the control needed.

## Best practices
Every effort is made in these examples to follow best practies for Policies.  This includes using templates to ensure clsuter/object configuration is in a working order regardless of the state of the cluster.  For example, setting OpenShift Monitoring or other workloads to run on infra nodes should only happen if there are infra nodes in the cluster.  When the cluster is first created infra nodes may not have been created yet.  We don't want to have ACM policies create a situation where the cluster is not healthy because of missing infra nodes.  The policies should react and adjust the configuration once the infra nodes are created.

Similar to the infra node example we will attempt to use other practices showcasing techniques of good Policy creation habits.
