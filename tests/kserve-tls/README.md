# KServe Inference Logger TLS

## ODH init

Create a DSCi with

```shell
apiVersion: dscinitialization.opendatahub.io/v1
kind: DSCInitialization
metadata:
  finalizers:
    - dscinitialization.opendatahub.io/finalizer
  labels:
    app.kubernetes.io/created-by: opendatahub-operator
    app.kubernetes.io/instance: default
    app.kubernetes.io/managed-by: kustomize
    app.kubernetes.io/name: dscinitialization
    app.kubernetes.io/part-of: opendatahub-operator
  name: default-dsci
spec:
  applicationsNamespace: opendatahub
  devFlags:
    logmode: production
  monitoring:
    managementState: Managed
    namespace: opendatahub
  serviceMesh:
    auth:
      audiences:
        - 'https://kubernetes.default.svc'
    controlPlane:
      metricsCollection: Istio
      name: data-science-smcp
      namespace: istio-system
    managementState: Managed
  trustedCABundle:
    customCABundle: ''
    managementState: Managed
```

or

```shell
oc apply -f resources/dsci.yaml
```

Create a DSC with

```shell
apiVersion: datasciencecluster.opendatahub.io/v1
kind: DataScienceCluster
metadata:
  name: default-dsc
  labels:
    app.kubernetes.io/created-by: opendatahub-operator
    app.kubernetes.io/instance: default
    app.kubernetes.io/managed-by: kustomize
    app.kubernetes.io/name: datasciencecluster
    app.kubernetes.io/part-of: opendatahub-operator
spec:
  components:
    codeflare:
      managementState: Removed
    kserve:
      serving:
        ingressGateway:
          certificate:
            type: OpenshiftDefaultIngress
        managementState: Managed
        name: knative-serving
      devFlags:
        manifests:
          - contextDir: config
            sourcePath: overlays/development
            uri: 'https://github.com/ruivieira-forking/kserve/tarball/release-v0.12.1-dev'
      managementState: Managed
      defaultDeploymentMode: Serverless
    modelregistry:
      registriesNamespace: odh-model-registries
      managementState: Removed
    trustyai:
      devFlags:
        manifests:
          - contextDir: config
            sourcePath: overlays/odh
            uri: 'https://github.com/ruivieira/trustyai-service-operator/tarball/RHOAIENG-12337-kserve-cm-dev'
      managementState: Managed
    ray:
      managementState: Removed
    kueue:
      managementState: Removed
    workbenches:
      managementState: Removed
    dashboard:
      managementState: Removed
    modelmeshserving:
      managementState: Managed
    datasciencepipelines:
      managementState: Removed
    trainingoperator:
      managementState: Removed
```

or

```shell
oc apply -f dsc.yaml
```

## Test with no TLS

Patch the KServe config:

```shell
kubectl patch configmap inferenceservice-config -n opendatahub --type merge --patch-file=resources/patch-no-tls.json
```

Create a namespace called `test`.

Deploy model storage:

```shell
oc apply -f resources/model-storage-container.yaml -n test
```

Apply serving runtime:

```shell
oc apply -f resources/ovms-1.x.yaml -n test
```

Apply model:

```shell
oc apply -f resources/model_alpha.yaml -n test
```

Deploy TrustyAI service:

```shell
oc apply -f resources/trustyai-cr.yaml -n test
```

## Test with TLS

Patch the KServe config:

```shell
kubectl patch configmap inferenceservice-config -n opendatahub --type merge --patch-file=resources/patch-tls.json
```

Create a namespace called `test`.

Deploy model storage:

```shell
oc apply -f resources/model-storage-container.yaml -n test
```

Apply serving runtime:

```shell
oc apply -f resources/ovms-1.x.yaml -n test
```

Apply model:

```shell
oc apply -f resources/model_alpha.yaml -n test
```

Deploy TrustyAI service:

```shell
oc apply -f resources/trustyai-cr.yaml -n test
```

## Notes

* Remember to delete the entire namespace between runs, to ensure no left-overs (config maps, etc) are left behind.