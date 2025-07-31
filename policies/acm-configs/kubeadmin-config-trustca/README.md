# kubeadmin Secret Configure CA Trust
The `acm-kubeadmin-trustca` Policy will perform an automatic update of the CA in the admin kubeconfig secrets.

When the cluster is created through Hive the kubeconfig contains the CA for the initial cluster certificates. This is typically
replaced with a corporate based certificate chain. In such environments it would also be expected for the trustedCA to be configured
in the cluster proxy.

When the api.cluster.domain.com certificate is replaced the generated kubeconfig in ACM no longer trusts the managed cluster endpoint.
This results in the hub no longer able to perform functions like scaling MachinePools.

This policy will use the CA configured in the cluster proxy and replace the "certificate-authority-data" found in the kubeconfig-admin secrets.
There is a delay of 12 hours so that new clusters so that ACM can perform initial management as needed before and during day-2 configuration policies being
applied.

## Dependencies
  - Root trust CA configured in cluster proxy
  - When the root trust CA is updated/replaced both the old and new certificate will be included in the ConfigMap

## Details
ACM Minimal Version: 2.12

Documentation: [Knowledgebase](https://access.redhat.com/solutions/7076376)

---
**Notes:**
  -
