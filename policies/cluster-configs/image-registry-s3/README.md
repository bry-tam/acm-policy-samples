#  Image Registry

## Description
Configures the OpenShift internal image registry to use ODF S3 object storage via NooBaa.
Creates an `ObjectBucketClaim` for registry storage, builds the S3 access credentials and CA
bundle, and patches the image registry `Config` singleton to use the bucket.

## Dependencies
  - [Data Foundation Operator](../../operators/data-foundation/) — the `odf-operator-status` policy must be Compliant before this policy runs

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/registry/index#registry-configuring-storage-baremetal_configuring-registry-storage-baremetal)

Notes:
  - Applied only to clusters labeled `storage=odf` via the `ft-storage--odf` placement
  - The image registry is configured with 2 replicas and `managementState: Managed`
  - S3 storage `managementState` is set to `Unmanaged` so ODF manages the bucket lifecycle
  - The NooBaa S3 route in `openshift-storage` is used as the `regionEndpoint`

## Implementation Details
Four resources are applied in dependency order:

**`image-registry-config`** (OBC) — creates an `ObjectBucketClaim` named `obc-imageregistry` in
`openshift-config`. ODF provisions a NooBaa bucket and generates a `Secret` containing the S3
access key and secret key. Gates on the `odf-operator-status` policy being Compliant.

**`registry-s3-access-secret`** ← depends on OBC Compliant — reads `AWS_ACCESS_KEY_ID` and
`AWS_SECRET_ACCESS_KEY` from the OBC-generated `Secret` (`openshift-config/obc-imageregistry`)
and creates `image-registry-private-configuration-user` in `openshift-image-registry`. This is
the credential secret the registry operator reads to authenticate with S3.

**`image-registry-s3-bundle`** ← depends on OBC Compliant — creates a `ConfigMap` named
`image-registry-s3-bundle` in `openshift-config` with the
`config.openshift.io/inject-trusted-cabundle: 'true'` label so OpenShift automatically injects
the cluster CA bundle. This allows the registry to trust the NooBaa S3 TLS endpoint.

**`imageregistry-config`** ← depends on `registry-s3-access-secret` Compliant — looks up the
`ObjectBucket` to retrieve the provisioned bucket name, then patches the `Config` singleton
(`imageregistry.operator.openshift.io/v1`) to set the S3 storage backend using the NooBaa route
as the region endpoint and the CA bundle ConfigMap as the trusted CA.
