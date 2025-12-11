# Hosted Control Plane Policy example
The purpose of this policy is to illustrate how to update the authentication on a Hosted Control Plane (HCP) using ACM Policies.  This example is the same pattern that is needed to manage the configuration for an HCP cluster that is on the hosted cluster versus the managed cluster itself.


## Dependencies
  - None

## Details
ACM Minimal Version: 2.14

Documentation:
  - [HCP Authentication](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/hosted_control_planes/authentication-and-authorization-for-hosted-control-planes)

---
**Notes:**
  - The policy placement needs to target the hosting cluster, not the hosted managed cluster that you want to update the auth config for.
  - The policy uses the objectSelector to identify hosted managed clusters to apply the configuration for.
