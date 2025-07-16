# Ansible Automation Platform
Installs the Ansible Automation Platform operator and configures an instance of `AnsibleAutomationPlatform`

## Dependencies
  - s3 Storage - Currently configured to use ODF
    - Current dependency on [ODF Operator policy](../data-foundation/)

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/latest/html-single/installing_on_openshift_container_platform/index)

---
**Notes:**
  - Deploys Ansible Platform Gateway along with other AAP components.
  - Does not deploy Ansible AI
