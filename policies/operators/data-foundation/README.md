# OpenShift Data Foundation Operator
Deploys ODF and configures a StorageSystem based on AWS.  Will need to be updated for your environment.

**Note:** only configures and deploys MultiCloud Object Gateway to make s3 compatible storage available.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_openshift_data_foundation/latest)

---
**Notes:**
  - Version of operator set to match cluster.  Will automatically update when cluster is upgraded.
  - Deploys a standalone MultiCloud Object Gateway.
    - To deploy full ODF ceph/rook based storage update the StorageCluster appropriately.
    - Storage backend is configured for AWS based deployments.
  - `StorageSystem` is no longer needed in 4.19+.  Will only deploy in older versions.
