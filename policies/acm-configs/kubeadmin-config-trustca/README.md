#  Kubeadmin Secret Configure CA Trust

## Description
Automatically updates the `certificate-authority-data` in Hive-managed kubeconfig secrets to use the
corporate CA bundle configured in the cluster proxy. Required when the initial cluster API certificate
is replaced with a corporate certificate chain, which causes the Hive-generated kubeconfig to stop
trusting the managed cluster endpoint.

## Dependencies
  - Corporate root CA configured as `trustedCA` in the hub cluster `Proxy` object
  - The CA ConfigMap must exist in `openshift-config` and contain a `ca-bundle.crt` key

## Details
ACM Minimal Version: 2.12

Documentation: [Knowledgebase](https://access.redhat.com/solutions/7076376)

Notes:
  - Deployed to hub only; acts on all Hive `Secret` resources with label `hive.openshift.io/secret-type=kubeconfig`
  - Skips secrets newer than 12 hours to allow initial day-2 configuration to complete before updating
  - Updates both the `kubeconfig` and `raw-kubeconfig` keys in each secret
  - When the root CA is rotated, include both old and new certificates in the ConfigMap to avoid
    a window where neither kubeconfig is trusted

## Implementation Details
The template:

1. Reads the hub `Proxy` object to find the `trustedCA` ConfigMap name
2. Loads the CA bundle from `openshift-config/<trustedCA-name>` using `fromConfigMap`
3. Iterates all Hive kubeconfig secrets, skipping any created less than 12 hours ago
4. For each eligible secret, decodes the kubeconfig, replaces the `certificate-authority-data`
   value with the new base64-encoded CA bundle, and emits a `musthave` patch

The 12-hour delay ensures ACM can complete initial cluster provisioning and day-2 configuration
before the API certificate replacement makes the original kubeconfig untrusted.
