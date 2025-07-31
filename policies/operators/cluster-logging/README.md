# Cluster Logging Operator
Installs the Cluster Logging operator and instance of `ClusterLogForwarder`.

Includes experimental (unsupported by Red Hat) multi-cluster logging.  With this the ACM Hub includes the full logging stack with a large Loki instance.  Each managed cluster would only have the Cluster Logging Operator which is setup to forward logs to the Loki instance on the Hub.  Each message has the cluster name added to the [labels on the log message](#adding-custom-labels-to-log-messages) so you can query by cluster. [more information](#more-info-on-multi-cluster-logging)

## Dependencies
  - [Loki Operator](../loki/)
  - [Cluster Observability](../cluster-observability/)
  - s3 Storage - Current configuration showcases using [ODF Operator](../data-foundation/)

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/logging/index)

#### **Adding custom labels to log messages**
  > With OpenShift Logging Operator you can configure custom labels to log messages before they are sent to Loki with a filter.
  >
  > The below example would add a label `cluster_name` to each log message with the name of the cluster as stored in the ClusterClaim "name".
  > ```
  >   filters:
  >     - name: ocp-multicluster-labels
  >       type: openshiftLabels
  >       openshiftLabels:
  >         cluster_name: '{{ fromClusterClaim "name" }}'
  > ```
  >
  > The filter needs to be referenced in any pipelines you want it included on the messages of.
  > ```
  >   pipelines:
  >     - name: app-logstore
  >       outputRefs:
  >       - otlp-loki-route-app
  >       inputRefs:
  >       - application
  >       filterRefs:
  >         - ocp-multicluster-labels
  > ```

#### **More info on multi-cluster logging**
  > The policies generated from `./multi-cluster-generator.yml` deploys a `ClusterLogging` and required token to forward logs to a LokiStack running on the Hub cluster.  As of ACM 2.13 this is not supported by Red Hat.
  >
  > The `./hub-template-auth` directory contains ServiceAccount and RBAC required for the multi-cluster logging configuration to read data from the hub inorder to properly configure a managed cluster to forward logs to Loki running on the hub.
  >
  > In this configuration Loki would not be deployed to the managed cluster, as such the multi-cluster policy would be used instead of the regular policy to deploy the logging operator on each managed cluster.

---
**Notes:**
  - Based on Cluster Logging 6.x
    - ./logs-6.x-migration creates a policy that will remove 5.x logging and ElasticSearch before install/upgrade to 6.x
  - Dependent on s3 storage for Loki, example uses ODF
  - Deploys Logfile Metric Exporter
  - Deploys unsupported/exterimental multi-cluster logging policies.  These are separate from the Cluster Logging policies.  If not desired remove from kustomization.yaml file.
