# OpenShift Pipelines Operator
Installs the OpenShift Pipelines Operator.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_openshift_pipelines/latest)

---
**Notes:**
  - Configures cleanup job to run every minute.  This should be updated to fit your environment.
  - Configures a pull-secret based off the cluster global pull-secret for every namespace labeled `tekton.rh-reg-auth: true`
