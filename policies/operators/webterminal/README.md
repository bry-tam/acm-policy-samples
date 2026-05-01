---
# Web Terminal Operator

## Description
Deploys the Web Terminal Operator, which provides an in-browser terminal experience in the OpenShift console via `DevWorkspace` instances. This policy installs the operator only; `DevWorkspace` instances are created on demand by console users.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/web_terminal/latest)

Notes:
  - Does not configure a `DevWorkspace` instance; terminals are created on demand through the console UI

## Implementation Details

**`web-terminal`** — installs the `OperatorPolicy` into the `openshift-operators` namespace.
