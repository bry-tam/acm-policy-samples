#!/bin/bash

# =============================================================================
# Script Name: run-policy-tools.sh
# Description: Launches podman using ArgoCD image for kustomize, ACM cli image for
#              PolicyTools and PolicyGenerator.  Also makes yq available.
#              This give all the tools needed to build PolicyGenerators and debug
#              policy templates.  Use ./build-policy-resolve.sh to run `kustomize build`
#              filtering the results to the specific policy before resolving the template
# =============================================================================

pull_secret=/home/bjarvis/discon/rh_pull
acm_version=2.17
argo_version=1.21
spoke_kubeconfig=/var/home/bjarvis/lab_setup/bry-aws/ocp420/acm/auth/kubeconfig
hub_kubeconfig=/var/home/bjarvis/lab_setup/bry-aws/ocp420/acm/auth/kubeconfig
src_dir=/var/home/bjarvis/src/bry-tam/acm-policy-samples


## pre-pull the images needed to be mounted as source
echo "Pulling required images for ACM and ArogCD"
podman pull --authfile ${pull_secret} --policy newer registry.redhat.io/rhacm2/acm-cli-rhel9:v${acm_version} > /dev/null
podman pull --authfile ${pull_secret} --policy newer docker.io/mikefarah/yq:latest > /dev/null
podman pull --authfile ${pull_secret} --policy newer registry.redhat.io/openshift-gitops-1/argocd-rhel9:${argo_version} > /dev/null

## launch the container with the tools and the policy source code 
podman run -it --rm  --user 0 --authfile ${pull_secret}   \
     --mount type=image,source=registry.redhat.io/rhacm2/acm-cli-rhel9:v${acm_version},destination=/mnt/acm   \
     --mount type=image,source=docker.io/mikefarah/yq:latest,destination=/mnt/yq-cli \
     -v ${spoke_kubeconfig}:/tmp/kubeconfig:Z   \
     -v ${hub_kubeconfig}:/tmp/hub_kubeconfig:Z   \
     -v ${src_dir}:/src:Z  \
     -v /home/bjarvis/tls-ca-bundle.pem:/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem:ro,Z \
     -e acm_version=${acm_version} -e argo_version=${argo_version} \
     --entrypoint /bin/bash  --workdir /src registry.redhat.io/openshift-gitops-1/argocd-rhel9:${argo_version}   -c 'mkdir -p "$HOME/kustomize/plugin/policy.open-cluster-management.io/v1/policygenerator" && \
      tar -xzf /mnt/acm/acm-cli/PolicyGenerator-rhel9.tar.gz -C "$HOME/kustomize/plugin/policy.open-cluster-management.io/v1/policygenerator" && \
      mkdir -p "$HOME/policytools" && \
      tar -xzf /mnt/acm/acm-cli/linux-amd64-policytools.tar.gz -C "$HOME/policytools" && \
      export KUSTOMIZE_PLUGIN_HOME="$HOME/kustomize/plugin" && \
      export PATH="$HOME/policytools:$PATH" && \
      export PATH="/mnt/yq-cli/usr/bin:$PATH" && \
      export KUBECONFIG="/tmp/kubeconfig" && \
      echo -e "\n\n******  ACM Policy Tools CLI Image  ******" && \
      echo -e "   ACM Version ${acm_version}\n   ArgoCD Version ${argo_version}\n" && \
      exec bash'
