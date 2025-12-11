###  Secondary Scheduler Operator

#### Description
Deploys the secondary scheduler operator and an example schedule

#### Dependencies
- None

#### Details
ACM Minimal Version: 2.12
Documentation: [Docs](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/nodes/controlling-pod-placement-onto-nodes-scheduling#secondary-scheduler)

Notes:
  - The example scheduler creates a configuration that ignores pod resources when scheduling workloads.
    - This likely shouldn't be used in production.  While the scheduler ignores the request values the kubelet does not.  When a node does not have any resources left to run the pod on the kubelet fails the pod.  This results in a cycle of create/fail pods at a high rate.
