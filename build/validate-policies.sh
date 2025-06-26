#!/bin/bash

KUBECONFORM=kubeconform
KC_VERSION=v0.6.4
KUSTOMIZE_VERSION=v5.3.0
GENERATOR_PATH=policy.open-cluster-management.io/v1/policygenerator
KUSTOMIZE_OUTPUT_ROOT=${PWD}/bin/.kustomize
export POLICY_GEN_ENABLE_HELM=true

# Validate the policy resource file under the directory provided
validatePolicies() {
  find $1 -name "*.yaml" | xargs kubeconform -schema-location 'schemas/{{ .ResourceKind }}_{{ .ResourceAPIVersion }}.json' -summary
}

# Validate the generator based policies under the directory provided
validatePolicyGenerator() {
  KPATH=`pwd`
  SETPATH=$1
  cd $SETPATH
  for kst in `find . -name "kustomization.y*ml"`; do
    project=`echo $kst | sed 's,/kustomization.*,,g'`

    # skip any kustomize files that are labeled with skip_validation: true
    if grep -q "skip_validation: true" $kst; then
      echo "Skipping validation for $kst."
      continue
    fi
    cd $project
    echo "Generating Policys $project"
          KUSTOMIZE_OUTPUT=${KUSTOMIZE_OUTPUT_ROOT}/${project}/kbout.yml
          mkdir -p "$(dirname ${KUSTOMIZE_OUTPUT})"
          OUTPUT=`kustomize build --enable-alpha-plugins --enable-helm > ${KUSTOMIZE_OUTPUT}`

          cd $KPATH
          cat ${KUSTOMIZE_OUTPUT} |  kubeconform -schema-location 'schemas/{{ .ResourceKind }}_{{ .ResourceAPIVersion }}.json' -schema-location default -summary

          cd $KPATH/$SETPATH
  done
  cd $KPATH
}

# Setup

# Go Setup
export GOBIN=${PWD}/bin
export PATH=${GOBIN}:${PATH}
mkdir -p ${GOBIN}

# Configure org for manual validation runs
if [ -z "${OCM_REPOSITORY_OWNER}" ]; then
  echo "Set OCM_REPOSITORY_OWNER=[github org], using stolostron by default"
  OCM_REPOSITORY_OWNER=stolostron
fi

set -euo pipefail  # exit on errors and unset vars, and stop on the first error in a "pipeline"

# Install kubeconform
echo "Installing kubeconform"
go install github.com/yannh/kubeconform/cmd/kubeconform@$KC_VERSION

# Get the CRDs needed for policy validation
if [ ! -d schemas ]; then
  echo "Getting Schema conversion tool"
  mkdir schemas
  cd schemas
  curl -s -o crd-schema.py https://raw.githubusercontent.com/yannh/$KUBECONFORM/$KC_VERSION/scripts/openapi2jsonschema.py
  chmod a+x crd-schema.py

  echo "Converting CRDs to Schemas"
  ./crd-schema.py https://raw.githubusercontent.com/${OCM_REPOSITORY_OWNER}/governance-policy-propagator/main/deploy/crds/policy.open-cluster-management.io_placementbindings.yaml
  ./crd-schema.py https://raw.githubusercontent.com/${OCM_REPOSITORY_OWNER}/governance-policy-propagator/main/deploy/crds/policy.open-cluster-management.io_policies.yaml
  ./crd-schema.py https://raw.githubusercontent.com/${OCM_REPOSITORY_OWNER}/governance-policy-propagator/main/deploy/crds/policy.open-cluster-management.io_policysets.yaml
  ./crd-schema.py https://raw.githubusercontent.com/${OCM_REPOSITORY_OWNER}/governance-policy-propagator/main/deploy/crds/policy.open-cluster-management.io_policyautomations.yaml
  ./crd-schema.py https://raw.githubusercontent.com/${OCM_REPOSITORY_OWNER}/placement/main/deploy/hub/0000_02_clusters.open-cluster-management.io_placements.crd.yaml
  ./crd-schema.py https://raw.githubusercontent.com/${OCM_REPOSITORY_OWNER}/placement/main/deploy/hub/0000_00_clusters.open-cluster-management.io_managedclusters.crd.yaml
  ./crd-schema.py https://raw.githubusercontent.com/${OCM_REPOSITORY_OWNER}/placement/main/deploy/hub/0000_00_clusters.open-cluster-management.io_managedclustersets.crd.yaml
  ./crd-schema.py https://raw.githubusercontent.com/${OCM_REPOSITORY_OWNER}/placement/main/deploy/hub/0000_01_clusters.open-cluster-management.io_managedclustersetbindings.crd.yaml


  cd ..
fi


# Check generator policies for each environment

# Install kustomize
echo "Installing kustomize"
GO111MODULE=on go install sigs.k8s.io/kustomize/kustomize/v5@$KUSTOMIZE_VERSION

# Install the Policy Generator kustomize plugin
export KUSTOMIZE_PLUGIN_HOME=${GOBIN}
if [ ! -d ${GOBIN}/policy-generator-plugin ]; then
echo "Downloading the generator"
PLATFORM=`uname | tr '[:upper:]' '[:lower:]'`
git clone --depth=1 https://github.com/${OCM_REPOSITORY_OWNER}/policy-generator-plugin ${GOBIN}/policy-generator-plugin
( cd ${GOBIN}/policy-generator-plugin; make build-binary )
chmod a+x ${GOBIN}/policy-generator-plugin/PolicyGenerator
mkdir -p ${KUSTOMIZE_PLUGIN_HOME}/${GENERATOR_PATH}
mv ${GOBIN}/policy-generator-plugin/PolicyGenerator ${KUSTOMIZE_PLUGIN_HOME}/${GENERATOR_PATH}/PolicyGenerator
fi

# Validate the generator projects

echo "Checking environment based policy sets"
validatePolicyGenerator environments

echo "Checking all policies"
validatePolicyGenerator policies

# Cleanup
rm -rf schemas
rm -rf ${KUSTOMIZE_OUTPUT_ROOT}
chmod -R 755 ${GOBIN}
rm -rf ${GOBIN}

# Done
