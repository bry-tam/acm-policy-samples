Installs the OpenShift Pipelines Operator.

Note:
  - Configures cleanup job to run every minute.  This should be updated to fit your environment.
  - Configures a pull-secret based off the cluster global pull-secret for every namespace labeled `tekton.rh-reg-auth: true`
