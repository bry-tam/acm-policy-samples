#  Application Deployment Reload

## Description
Automatically restarts `Deployment` pods when a watched `ConfigMap` or `Secret` changes.
Deployments opt in by adding a label and an annotation listing the resources to monitor.
Inspired by the [Reloader](https://github.com/stakater/Reloader) pattern but implemented
entirely as an ACM policy using hub-side templates.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: None

Notes:
  - Deployed to clusters using the `ft-app--reload` feature-flag placement
  - Only `Deployment` resources are supported; `StatefulSet` and `DaemonSet` are not monitored
  - The policy does not inspect whether the ConfigMap or Secret is actually mounted or used as an env reference
  - Tracking state is stored in a `ConfigMap` named `acm-reload-tracker` in the `default` namespace

## Implementation Details
Two `ConfigurationPolicy` resources work together:

**`app-reload-tracker` (inform)** — scans all `Deployment` resources labeled `acm.reloader.enabled`
and builds an `acm-reload-tracker` ConfigMap recording the current `resourceVersion` of each watched
ConfigMap or Secret. Keys use the format:
```
<deployment>--<apiVersion>--<kind>--<namespace>--<name>: '<resourceVersion>'
```
This policy is `inform` only and acts as the source of truth for what versions were last seen.

**`tracker-app-reload` (enforce)** — runs only when `app-reload-tracker` is `NonCompliant`
(i.e. a tracked resource version has changed). For each labeled `Deployment` it compares the
current `resourceVersion` of each watched resource against the value in `acm-reload-tracker`.
If a version mismatch is found, it patches the Deployment's pod template with:
```yaml
kubectl.kubernetes.io/restartedAt: '<timestamp>'
```
This triggers a rolling restart. It then writes the updated versions back to `acm-reload-tracker`.

**Opting a Deployment into reload watching:**

1. Add the label:
```yaml
labels:
  acm.reloader.enabled: ""
```

2. Add the watchlist annotation (JSON array of resources to monitor):
```yaml
annotations:
  acm.reloader.watchlist: |
    [
      {"kind": "ConfigMap", "name": "my-config", "apiVersion": "v1"},
      {"kind": "Secret",    "name": "my-secret",  "apiVersion": "v1"}
    ]
```
