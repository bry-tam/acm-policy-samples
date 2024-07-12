The policies in "simple" and "advanced" showcase how to reload a deployment when a secret or configmap is updated.

### Simple policy
This policy tracks a specific configmap/secret and updates a specific deployment.  The use case would be limited.
> The simple policy example is currently broken and would need some adjustments to work.  The advanced is a much better way to acheive this.

### Advanced policy
This policy allows a more flexable use case.  Based loosely off https://github.com/stakater/Reloader

Some notable differences:
  - There is no auto watcher.  The deployment needs a label to enable reloading, and an annotation with the Secrets/ConfigMap to monitor.
  - It does not parse the Deployment to see if the ConfigMap/Secret is used as a volumeMount or an env reference.  
  - The last known resourceVersion of the ConfigMap/Secret is recorded for tracking purposes.  If this does not match the Deployment is updated with `kubectl.kubernetes.io/restartedAt` annotation on the pod template.  And the tracking ConfigMap is updated.
  - Only Deployments are currently reloaded


**Setup steps**
1. Label deployment with `acm.reloader.enabled: ''`
2. Annotate deployment with `acm.reloader.watchlist`
   1. The value is a JSON string in the format of
      ```
      [
        {
          "kind": "ConfigMap",
          "name": "booksecret",
          "apiVersion": "v1"
        }
      ]
      ```
    Example:
    ```
    kind: Deployment
    apiVersion: apps/v1
    metadata:
      annotations:
        acm.reloader.watchlist: '[{"kind": "ConfigMap","name": "blogsecret","apiVersion": "v1"},{"kind": "Secret","name": "blogsecret","apiVersion": "v1"}]'
    ```

