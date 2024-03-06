The policies in this directory are to configure cluster aspects directly related to managed clusters hosted in ARO.

**merge-rh-pull-secret**:
This policy is to configure a RH pull secret on an ARO cluster as defined in https://learn.microsoft.com/en-us/azure/openshift/howto-add-update-pull-secret

It is currently configured to copy the pull-secret from the hub and merge it with the pull-secret on the managed cluster.  It would be better if the RH pull secret originated from vault or other secure location.  Currently the policy would only work if the hub pull-secret contains the RH pull secret.

The resulting pull-secret on the managed clusters will be the `arosvc.azurecr.io` auth from the managed cluster and all other auths from the hub pull-secret.

