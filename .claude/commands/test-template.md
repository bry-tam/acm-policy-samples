Build and resolve an ACM policy template by running the kustomize → yq → policytools pipeline directly. Do NOT call build-template.sh.

## Step 1 — Gather arguments

Parse `$ARGUMENTS` for the following. If a required argument is missing, ask the user before continuing.

**Required:**
- `POLICY_PATH` — first positional argument; path to the policy directory (e.g. `policies/operators/metallb`)
- `--policy-name <name>` — name of the Policy resource to select from the kustomize output

**Optional (with defaults):**
- `--hub-namespace <ns>` — namespace on the Hub; default: `bry-tam-policies-prod`
- `--cluster-name <name>` — target cluster name for template resolution; default: `local-cluster`
- `--hub-kubeconfig <path>` — path to Hub kubeconfig; default: value of the `$KUBECONFIG` environment variable
- `--lint` — always enabled; cannot be disabled
- `--configpolicy-name <name>` — name of a specific ConfigurationPolicy to extract
- `--object-name <name>` — target object name
- `--object-namespace <ns>` — target object namespace
- `--debug` — print the constructed pipeline before running it

## Step 2 — Build the yq expression

If `--configpolicy-name` was provided:
```
select(.kind == "Policy" and .metadata.name == "<policy-name>").spec.policy-templates[].objectDefinition | select(.kind == "ConfigurationPolicy" and .metadata.name == "<configpolicy-name>")
```

Otherwise:
```
select(.kind == "Policy" and .metadata.name == "<policy-name>") | .metadata.namespace = "<hub-namespace>"
```

## Step 3 — Build the policytools arguments

Start with: `template-resolver --hub-namespace <hub-namespace> --cluster-name <cluster-name> --hub-kubeconfig <hub-kubeconfig> --lint`

Apply defaults for any argument not explicitly provided by the user:
- `--hub-namespace` → `bry-tam-policies-prod`
- `--cluster-name` → `local-cluster`
- `--hub-kubeconfig` → read the `$KUBECONFIG` environment variable at runtime using Bash (`echo $KUBECONFIG`) and use its value; if empty, omit the flag
- `--lint` → always included

Append any of the following that were provided:
- `--object-name <value>`
- `--object-namespace <value>`

## Step 4 — Execute

If `--debug` was provided, first display the full pipeline as text so the user can see what will run.

Then run using the Bash tool:
```
kustomize build --enable-alpha-plugins "<POLICY_PATH>" | yq '<yq-expression>' | policytools <policytools-args>
```

Display the output to the user.
