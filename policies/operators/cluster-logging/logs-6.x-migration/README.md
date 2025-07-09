This is an additional policy to the OpenShift Logging deployment.  The purpose is to assist in migrating from 5.x to 6.x version of the cluster logging.

The policy performs the following in order:
  1. Validates the version based on channel in the subscription.  Will only move forward if the channel is set to "6.x"
  2. Remove old ClusterLogForwarder and metrics exporter from `logging.openshift.io` apiVersion
  3. Remove old ClusterLogging from `logging.openshift.io` apiVersion
  4. Checks if ElasticSearch is deployed, will block if it exists.  The cluster-logging ElasticSearch should be created/managed by the ClusterLogging instance and should be removed as part of Step 3
  5. Remove any PVC and PVs used for logging
  6. Remove "openshift-operators-redhat" and "openshift-logging" namespaces.  This will ensure there are no orphaned items left in the cluster
  7. Remove all CRDs in group `logging.openshift.io`.  This is done because the 6.x reuses ClusterLogForwarder in a different group/apiVersion which leaving both results in oc get commands not behaving as expected.

**Note**: If you are going to remove this from the policies, you will need to also remove the dependency from the cluster-logging policy generator that references the "prepare-logging-migration"
