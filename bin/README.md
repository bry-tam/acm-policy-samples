# bin

Helper scripts for building and debugging the policies in this repository.
They are meant to be used together: `run-policy-tools.sh` starts a container that
has all the required tooling, and `build-policy-resolve.sh` runs inside that
container to render a single policy and resolve its hub/managed-cluster templates.

| Script | Where it runs | Purpose |
| --- | --- | --- |
| [`run-policy-tools.sh`](#run-policy-toolssh) | Your workstation | Launch a podman container with `kustomize`, the `PolicyGenerator` plugin, `policytools`, and `yq` |
| [`build-policy-resolve.sh`](#build-policy-resolvesh) | Inside the container | Build a policy with `kustomize`, select it with `yq`, and resolve its templates with `policytools` |

## run-policy-tools.sh

Starts an interactive shell in a throwaway container that contains every tool
needed to build PolicyGenerator output and debug policy templates.

### What it does

1. Pulls the required images (`--policy newer`) using your Red Hat pull secret:
   - `registry.redhat.io/rhacm2/acm-cli-rhel9:v<acm_version>` - provides the
     `PolicyGenerator` kustomize plugin and `policytools`
   - `docker.io/mikefarah/yq:latest` - provides `yq`
   - `registry.redhat.io/openshift-gitops-1/argocd-rhel9:<argo_version>` - base
     image, provides `kustomize`
2. Runs the ArgoCD image as root (`podman run -it --rm --user 0`) with the ACM CLI
   and `yq` images mounted as image volumes (`/mnt/acm`, `/mnt/yq-cli`).
3. Inside the container it:
   - extracts `PolicyGenerator-rhel9.tar.gz` into
     `$HOME/kustomize/plugin/policy.open-cluster-management.io/v1/policygenerator`
     and sets `KUSTOMIZE_PLUGIN_HOME`
   - extracts `linux-amd64-policytools.tar.gz` into `$HOME/policytools` and adds
     it to `PATH`
   - adds `/mnt/yq-cli/usr/bin` to `PATH`
   - sets `KUBECONFIG=/tmp/kubeconfig`
   - prints the ACM and ArgoCD versions and drops you into `bash`

### Mounts

| Host path (variable) | Container path | Notes |
| --- | --- | --- |
| `spoke_kubeconfig` | `/tmp/kubeconfig` | Used as the default `KUBECONFIG` |
| `hub_kubeconfig` | `/tmp/hub_kubeconfig` | Pass to `build-policy-resolve.sh --hub-kubeconfig` |
| `src_dir` | `/src` | This repository; also the working directory |
| `/home/bjarvis/tls-ca-bundle.pem` | `/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem` | Read-only CA bundle |

### Configuration

The settings are hard-coded variables at the top of the script. Edit them for
your environment before running:

| Variable | Default | Description |
| --- | --- | --- |
| `pull_secret` | `/home/bjarvis/discon/rh_pull` | Pull secret used for `podman pull` and `podman run` |
| `acm_version` | `2.17` | ACM CLI image tag (`v<acm_version>`) |
| `argo_version` | `1.21` | OpenShift GitOps ArgoCD image tag |
| `spoke_kubeconfig` | `/var/home/bjarvis/lab_setup/bry-aws/ocp420/acm/auth/kubeconfig` | Kubeconfig for the managed (spoke) cluster |
| `hub_kubeconfig` | `/var/home/bjarvis/lab_setup/bry-aws/ocp420/acm/auth/kubeconfig` | Kubeconfig for the ACM hub |
| `src_dir` | `/var/home/bjarvis/src/bry-tam/acm-policy-samples` | Local checkout mounted at `/src` |

### Usage

```bash
./bin/run-policy-tools.sh
# inside the container:
./bin/build-policy-resolve.sh ...
```

Requires `podman` and access to `registry.redhat.io`.

## build-policy-resolve.sh

Renders a policy from a kustomize/PolicyGenerator directory and resolves its
templates against a hub and/or cluster. Run it inside the container started by
`run-policy-tools.sh`, where `kustomize`, `yq`, and `policytools` are on `PATH`.

### What it does

It runs this pipeline:

```bash
kustomize build --enable-alpha-plugins <POLICY_PATH> \
  | yq '<expression>' \
  | policytools template-resolver --hub-namespace <ns> [options]
```

The `yq` expression depends on whether `--configpolicy-name` is given:

- **Not given (default):** selects the `Policy` named `--policy-name` and sets
  its `metadata.namespace` to `--hub-namespace`.
- **Given:** selects the `Policy` named `--policy-name`, then extracts only the
  `ConfigurationPolicy` named `--configpolicy-name` from its `policy-templates`.

### Usage

```text
build-policy-resolve.sh [POLICY_PATH] --policy-name <name> --hub-namespace <ns> [OPTIONS]
```

| Argument / option | Required | Description |
| --- | --- | --- |
| `POLICY_PATH` | Yes | Directory containing the kustomization / PolicyGenerator config (single positional argument) |
| `--policy-name <name>` | Yes | Name of the `Policy` to select |
| `--hub-namespace <ns>` | Yes | Namespace of the policy on the hub |
| `--configpolicy-name <name>` | No | Extract only this `ConfigurationPolicy` from the policy |
| `--cluster-name <name>` | No | Target cluster name (passed to `policytools --cluster-name`) |
| `--hub-kubeconfig <path>` | No | Hub kubeconfig (e.g. `/tmp/hub_kubeconfig` in the container) |
| `--local-resources <path>` | No | Local resources for resolving lookups (passed to `policytools --local-resources`) |
| `--object-name <name>` | No | Name of the target object (`--object-name`) |
| `--object-namespace <ns>` | No | Namespace of the target object (`--object-namespace`) |
| `--lint` | No | Enable `policytools` linting |
| `--debug` | No | Print the full pipeline before executing it |
| `-h`, `--help` | No | Show usage |

Missing required arguments, an unknown option, more than one positional argument,
or a `POLICY_PATH` that is not a directory all print an error and exit non-zero.

### Examples

Render a policy and resolve its templates:

```bash
./bin/build-policy-resolve.sh policies/acm-configs --policy-name my-policy \
  --hub-namespace policies
```

Resolve a single ConfigurationPolicy against the hub and a managed cluster,
printing the command first:

```bash
./bin/build-policy-resolve.sh policies/acm-configs --policy-name my-policy \
  --configpolicy-name my-policy-config --hub-namespace policies \
  --cluster-name my-cluster --hub-kubeconfig /tmp/hub_kubeconfig --debug
```
