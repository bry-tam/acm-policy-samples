# Create cluster using ACM Policy Generator

The purpose of this example is to show how to use kustommize with the Policy Generator as a method to create clusters.

Note there are a couple of trade offs to be considers, such as the MachinePool would have hard coded the replicas -- scaling the cluster with ACM eihter manually or with an autoscaler would cause a conflict.

If running the GitOps process with ArgoCD (OpenShift GitOps) be sure to properlyu integrate the Policy Generator with ArgoCD https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.7/html-single/governance/index#policy-gen-install-on-openshift-gitops

Also note there are a number of features used which were introduced in ACM 2.7.  The policies will not work in prior versions.

## Code layout
base: The base directory hosts most of the files needed to create a cluster.  This directory is included through kustomize, changes made here will impact every cluster.

hub-data: There is an expectation of the objects here will already exist on the ACM hub cluster.  You should not include this content in your source repo, it is provided here as an example.

ocp01: This is a sample of the files needed to create a cluster.  The kustomize will modify the files from base and include them in the policy generated from the parent generator.yml file.

## Creating a new cluster
The below steps will outline briefly what is required to create a cluster.
  1) Copy the `clusters/ocp01` directory and name it the name of the new cluster.
  2) Modify the `clusters/new-cluster/install-config-secret.yml' to fit the new cluster.  Be sure to update any references to `ocp01`.
  3) Modify `clusters/new-cluster/managedcluster.yml` updating all references to `ocp01`.  Additionally you can change the default **cluster set** value for the new cluster.
  4) Modify the `clusters/new-cluster/kustomization.yaml` file to update the references to `ocp01`.  If needed add additional modifications to update the base files.
  5) Add the new cluster directory to the `clusters/generator.yml` file.

**Additional notes**
  1) All policies will be generated in the `bry-tam-cluster-policies` namespace.  You can change this in the `clusters/kustomization.yaml` file.  
  2) All of the vsphere and environment infromation is read from the secret defined in `clusters/hub-data`.  The format of this secret matches what is created when using the ACM UI to add a Credential.  