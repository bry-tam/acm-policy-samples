# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Does

This is a Red Hat Advanced Cluster Management (RHACM/ACM) policy samples repository. It uses the **PolicyGenerator** kustomize plugin to define policies once and deploy them across multiple cluster environments (dev → prod) via GitOps (ArgoCD).

## Validation Commands

CI runs these four scripts from `build/` on every push:

```bash
./build/validate-policies.sh           # Builds with kustomize + PolicyGenerator, validates with kubeconform
./build/validate-trailing-whitespace.sh
./build/validate-yaml-doc.sh           # All YAML must start with ---
./build/validate-end-of-file.sh        # All files must end with a blank newline
```

`validate-policies.sh` installs `kubeconform`, `kustomize`, and the PolicyGenerator plugin locally under `bin/` on first run. Set `OCM_REPOSITORY_OWNER` to override the default `stolostron` GitHub org.

To skip validation for a specific kustomization, add `skip_validation: true` to that `kustomization.yaml`.

## Architecture

### Environment Progression

```
policies/          ← single source of truth for all policies
environments/
  dev/             ← kustomize overlay: adds namespace suffix, sets ClusterSet refs
  prod/            ← same structure
```

Each environment overlay references `../../policies/` and applies transformers from `../../kustomize-configs/` plus its own `kustomize-configs/`. The transformers add an environment suffix to namespace and PolicySet names (e.g., `bry-tam-policies` → `bry-tam-policies-dev`).

### PolicyGenerator Pattern

Every policy directory contains:
- `generator.yml` — the `PolicyGenerator` manifest (the main definition)
- `kustomization.yaml` — must list `generator.yml` as a generator
- One or more manifest YAML files referenced by the generator
- `README.md` — required per policy

The `generator.yml` structure:
```yaml
apiVersion: policy.open-cluster-management.io/v1
kind: PolicyGenerator
metadata:
  name: gen-<name>
policyDefaults:
  namespace: bry-tam-policies
  remediationAction: enforce
  consolidateManifests: false
  policySets:
    - <set-name>
  categories:
    - "CM Configuration Management"
  controls:
    - "CM-2 Baseline Configuration"
  standards:
    - "NIST SP 800-53"
  policyLabels:
    policy_gen.name: <unique-identifier>
placementBindingDefaults:
  name: "<binding-name>"
policies:
  - name: <policy-name>
    description: "<required>"
    manifests:
      - path: manifest.yml
        name: unique-name-across-all-policies   # required if not using operatorpolicy
policySets:
  - name: <set-name>
    placement:
      placementName: "env-bound-placement"      # or env-bound-hub-placement / env-bound-nohub-placement
```

### Placement Types

Three base Placement resources are defined in `policies/acm-placements/`:
- `env-bound-placement` — all clusters in the ClusterSet
- `env-bound-hub-placement` — hub only (`local-cluster`)
- `env-bound-nohub-placement` — all clusters except hub

Feature-flag placements use the naming convention `ft-<LabelName>--<LabelValue>` (e.g., `ft-logging-type--Loki` targets clusters labeled `logging-type=Loki`).

### Policy Types

**OperatorPolicy** — used for all OLM-based operator installations. Must specify the complete subscription:
```yaml
subscription:
  channel: "stable-1.x"   # versioned channel preferred over "stable"
  name: ""
  namespace: ""
  source: ""
  sourceNamespace: ""
```

**ConfigurationPolicy** — used for cluster configuration. Supports `object-templates-raw` with Go template syntax and hub-side template expressions like `{{hub index $.ManagedClusterLabels "key" hub}}`.

### Policy Dependencies

Policies can declare dependencies that enforce ordering:
```yaml
dependencies:
  - name: other-policy-name
    compliance: Compliant
```

Manifests within a policy can use `extraDependencies` to depend on a sibling ConfigurationPolicy within the same policy.

## Format Requirements (Enforced by CI)

1. No trailing whitespace on any line
2. Blank line at end of every file
3. Every YAML file starts with `---`
4. Manifest `name` fields must be **unique across all policies** in the repo
5. Every policy must have a `description` field in the generator
6. Every policy directory must have a `README.md`
7. OperatorPolicies must specify complete subscription details including `channel`, `name`, `namespace`, `source`, and `sourceNamespace`
8. Security controls metadata must be set (`categories`, `controls`, `standards`)
9. Each policy must have a `policyLabels.policy_gen.name` label
