# TLS testing

## Setup
### Prepare Open Data Hub

1. Install Open Data Hub 2.15
2. Install a `DSCI`.
   1. No KServe needed or Service Mesh for this example
3. Install the provided `DataScienceCluster`
   ```shell
    oc apply -f resources/dsc.yaml
   ```
   
### Install ModelMesh

1. Create the namespace
   ```shell
    export NS="opendatahub-model"
    oc new-project $NS
    oc apply -f resources/enable-uwm.yaml # optional
    oc apply -f resources/model-serving-config.yaml -n opendatahub
    oc label namespace $NS "modelmesh-enabled=true" --overwrite=true
    oc apply -f resources/secret.yaml -n $NS
    SECRETKEY=$(openssl rand -hex 32) && sed -i "s/<secretkey>/$SECRETKEY/g" resources/sample-minio.yaml
    oc apply -f resources/ovms-1.x.yaml -n $NS
    oc apply -f resources/model-alpha-onnx.yaml -n {{ODH_NS}}
   ```

### Install TrustyAI

1. Install a TrustyAI service
   ```shell
    oc apply -f resources/trustyai-cr.yaml -n $NS
   ```
   
## Validation

1. The `MM_PAYLOAD_PROCESSORS` variable on ModelMesh **must** start with `https` (not `http`)
2. Sending an inference requests to the model (protocol not important) should
   1. **Not cause an error** in the ModelMesh `mm` container logs
   2. **Be received** by the TrustyAI service (check either via logs, CSV inspection or endpoints)