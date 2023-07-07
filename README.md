# acm-policy-samples

## Background
RHACM does not have a control process that enables managing changes to Policies through the managed cluster environments.  Many users have requirements that Policy changes should be deployed to Dev --> QA --> Prod clusters in sequence to allow testing.  This workflow also allows blocking changes except during maintenance windows.  

The customer requirements are in contradiction to Policies that should be applied to every cluster.  When a new Policy that deployed to all clusters is created, or an existing edited, we want to make sure those changes can be controlled where and when they are deployed.

Additionally we don't want to have to manage multiple copies of the same Policy, such as using directories would cause.  

## General repo layout
.
├── base
│   ├── acm-placements
│   ├── cluster-configs
│   └── kustomization.yaml
├── kustomization.yaml
├── overlays
│   └── prod
└── README.md

The file structure is based on a typical kustomize enviroment.
 - base: Holds the Policy definitions.  It is expected most if not all policies would be applied to all environments.  This means Policies should have business logic defined in them such that the same policy deployed to QA and Prod would exhibit expected behaviors.  This also allows testing the logic as policies are moved between environments.  
 - overlays/ENVIRONMENT_NAME: holds the kustomize overlay for specified environment.  Here we set the namespace name to deploy the policies in and the suffix for the PoliySet naming override.


## Managing changes between environments and naming conventions
 Using a kustomize approach with appropriate branches allows a better workflow when moving changes between environments.  Assuming one ACM Hub will manage all clusters this appraoch allows the same policy to be reused for each environment.  Branches allow us to control when changes to the policy are perculated through the stack.

 The name of the Policies will not change between environments, however they will be deployed to a separate namespace and PolicySet.  Each PolicySet will point to a Placement of the same name, however the ClusterSet targetted will control which clusters are deployed to.

 Each environment will consist of the following items:
 - ClusterSet containing all clusters in that environment
 - Directory in the overlay folder specifying the namespace name, ClusterSet name and other details specific to that environment.
 - Branch in the source repo used to provide the source of truth for the Policies deployed.

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


## Best practices
Every effort is made in these examples to follow best practies for Policies.  This includes using templates to ensure clsuter/object configuration is in a working order regardless of the state of the cluster.  For example, setting OpenShift Monitoring or other workloads to run on infra nodes should only happen if there are infra nodes in the cluster.  When the cluster is first created infra nodes may not have been created yet.  We don't want to have ACM policies create a situation where the cluster is not healthy because of missing infra nodes.  The policies should react and adjust the configuration once the infra nodes are created.

Similar to the infra node example we will attempt to use other practices showcasing techniques of good Policy creation habits.