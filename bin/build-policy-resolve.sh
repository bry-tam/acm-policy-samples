#!/bin/bash

# =============================================================================
# Script Name: build-policy-resolve.sh
# Description: Generates policy templates using kustomize, yq, and policytools.
# =============================================================================

# Function to display usage help
usage() {
    echo "Usage: $0 [POLICY_PATH] --policy-name <name> --hub-namespace <ns> [OPTIONS]"
    echo ""
    echo "Arguments:"
    echo "  [POLICY_PATH]                Path to the configuration directory (Required)"
    echo ""
    echo "Required Options:"
    echo "  --policy-name <name>         Name of the policy to select"
    echo "  --hub-namespace <ns>         Namespace on the Hub"
    echo ""
    echo "Optional Options:"
    echo "  --configpolicy-name <name>   Name of the specific ConfigurationPolicy to extract"
    echo "  --cluster-name <name>        Name of the target cluster"
    echo "  --hub-kubeconfig <path>      Path to the Hub kubeconfig file"
    echo "  --object-name <name>         Name of the target object"
    echo "  --object-namespace <ns>      Namespace of the target object"
    echo "  --lint                       Enable linting (Flag)"
    echo "  --debug                      Print the command before executing (Flag)"
    echo "  -h, --help                   Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 ./my-configs --policy-name my-pol --hub-namespace policies-ns --debug"
    exit 1
}

# Initialize variables
POLICY_PATH=""
POLICY_NAME=""
CONFIGPOLICY_NAME=""
CLUSTER_NAME=""
HUB_KUBECONFIG=""
HUB_NAMESPACE=""
OBJECT_NAME=""
OBJECT_NAMESPACE=""
LOCAL_RESOURCES=""
LINT=false
DEBUG=false

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --policy-name)
            POLICY_NAME="$2"
            shift; shift
            ;;
        --configpolicy-name)
            CONFIGPOLICY_NAME="$2"
            shift; shift
            ;;
        --cluster-name)
            CLUSTER_NAME="$2"
            shift; shift
            ;;
        --local-resources)
            LOCAL_RESOURCES="$2"
            shift; shift
            ;;
        --hub-kubeconfig)
            HUB_KUBECONFIG="$2"
            shift; shift
            ;;
        --hub-namespace)
            HUB_NAMESPACE="$2"
            shift; shift
            ;;
        --object-name)
            OBJECT_NAME="$2"
            shift; shift
            ;;
        --object-namespace)
            OBJECT_NAMESPACE="$2"
            shift; shift
            ;;
        --lint)
            LINT=true
            shift
            ;;
        --debug)
            DEBUG=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        -*)
            echo "Error: Unknown option: $1"
            usage
            ;;
        *)
            # Capture the unnamed argument as POLICY_PATH
            if [[ -z "$POLICY_PATH" ]]; then
                POLICY_PATH="$1"
                shift
            else
                echo "Error: Multiple positional arguments found. Only one [POLICY_PATH] is allowed."
                echo "Found: $POLICY_PATH and $1"
                exit 1
            fi
            ;;
    esac
done

# =============================================================================
# Validation
# =============================================================================

# Check Required Named Arguments
if [[ -z "$POLICY_NAME" || -z "$HUB_NAMESPACE" ]]; then
    echo "Error: Missing required named arguments."
    echo "You must provide: --policy-name and --hub-namespace"
    exit 1
fi

# Check Required Positional Argument (POLICY_PATH)
if [[ -z "$POLICY_PATH" ]]; then
    echo "Error: Missing required directory path [POLICY_PATH]."
    usage
fi

# Validate that POLICY_PATH is a valid directory
if [[ ! -d "$POLICY_PATH" ]]; then
    echo "Error: The path provided '$POLICY_PATH' is not a valid directory."
    exit 1
fi

# =============================================================================
# Command Construction
# =============================================================================

# 1. Build policytools arguments
PT_ARGS=("template-resolver" "--hub-namespace" "$HUB_NAMESPACE")

if [[ -n "$CLUSTER_NAME" ]]; then
    PT_ARGS+=("--cluster-name" "$CLUSTER_NAME")
fi

if [[ -n "$LOCAL_RESOURCES" ]]; then
    PT_ARGS+=("--local-resources" "$LOCAL_RESOURCES")
fi

if [[ -n "$HUB_KUBECONFIG" ]]; then
    PT_ARGS+=("--hub-kubeconfig" "$HUB_KUBECONFIG")
fi

if [[ -n "$OBJECT_NAME" ]]; then
    PT_ARGS+=("--object-name" "$OBJECT_NAME")
fi

if [[ -n "$OBJECT_NAMESPACE" ]]; then
    PT_ARGS+=("--object-namespace" "$OBJECT_NAMESPACE")
fi

if [[ "$LINT" == "true" ]]; then
    PT_ARGS+=("--lint")
fi

# 2. Build YQ Expression
if [[ -n "$CONFIGPOLICY_NAME" ]]; then
    # Scenario: ConfigurationPolicy extraction requested
    YQ_EXPRESSION="select(.kind == \"Policy\" and .metadata.name == \"$POLICY_NAME\").spec.policy-templates[].objectDefinition | select(.kind == \"ConfigurationPolicy\" and .metadata.name == \"$CONFIGPOLICY_NAME\")"
else
    # Scenario: Default Policy processing
    YQ_EXPRESSION="select(.kind == \"Policy\" and .metadata.name == \"$POLICY_NAME\") | .metadata.namespace = \"$HUB_NAMESPACE\""
fi

# =============================================================================
# Execution
# =============================================================================

# If Debug mode is on, print the pipeline
if [[ "$DEBUG" == "true" ]]; then
    echo "--- DEBUG MODE: Command Pipeline ---"
    echo "kustomize build --enable-alpha-plugins \"$POLICY_PATH\" | \\"
    echo "yq '$YQ_EXPRESSION' | \\"
    echo "policytools ${PT_ARGS[*]}"
    echo "------------------------------------"
fi

# Execute the pipeline
kustomize build --enable-alpha-plugins "$POLICY_PATH" | \
yq "$YQ_EXPRESSION" | \
policytools "${PT_ARGS[@]}"
