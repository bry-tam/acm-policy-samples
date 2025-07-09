Installs the Cluster Logging operator and instance of `ClusterLogForwarder`.

Note:
  - Based on Cluster Logging 6.x
    - ./logs-6.x-migration creates a policy that will remove 5.x logging and ElasticSearch before install/upgrade to 6.x
  - Dependent on s3 storage for Loki, example is dependent on ODF
  - Dependent on operators:
    - Loki
    - Cluster Observability
  - Deploys Logfile Metric Exporter
  - Deploys unsupported/exterimental multi-cluster logging policies.  These are separate from the Cluster Logging policies.  If not desired remove from kustomization.yaml file.

**More info on multi-cluster logging**
The policies generated from `./multi-cluster-generator.yml` deploys a `ClusterLogging` and required token to forward logs to a LokiStack running on the Hub cluster.  As of ACM 2.13 this is not supported by Red Hat.

The `./hub-template-auth` directory contains ServiceAccount and RBAC required for the multi-cluster logging configuration to read data from the hub inorder to properly configure a managed cluster to forward logs to Loki running on the hub.

In this configuration Loki would not be deployed to the managed cluster, as such the multi-cluster policy would be used instead of the regular policy to deploy the logging operator on each managed cluster.

**Adding custom labels to log messages**
With OpenShift Logging Operator you can configure custom labels to log messages before they are sent to Loki with a filter.

The below example would add a label `cluster_name` to each log message with the name of the cluster as stored in the ClusterClaim "name".
```
  filters:
    - name: ocp-multicluster-labels
      type: openshiftLabels
      openshiftLabels:
        cluster_name: '{{ fromClusterClaim "name" }}'
```

The filter needs to be referenced in any pipelines you want it included on the messages of.
```
  pipelines:
    - name: app-logstore
      outputRefs:
      - otlp-loki-route-app
      inputRefs:
      - application
      filterRefs:
        - ocp-multicluster-labels
```
