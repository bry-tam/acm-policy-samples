# Red Hat Developer Hub Operator
Installs the Developer Hub operator and instance of `Backstage`.


## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_developer_hub/latest)

---
**Notes:**
  - Attempts to configure all ACM managed clusters with ManagedServiceAccount for use by DevHub.  Each cluster is added to the DevHub config with the token from the MSA.
  - Does not include any health checks for backstage.
  - Limited testing.  Operator install is complete, but configuration of `Backstage` likely needs more review.
