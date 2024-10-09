# TLS testing

## Setup
### Prepare Open Data Hub

1. Install Open Data Hub 2.16
2. Install a `DSCI` with ModelMesh
3. Install the provided `DataScienceCluster`
   ```shell
    oc apply -f resources/dsc.yaml
   ```
   
### Install ModelMesh

Create the namespace
```shell
 export PROJ_NS="opendatahub-model"
 oc new-project $PROJ_NS
 oc apply -f resources/enable-uwm.yaml # optional
```
    
Create a PKCS8 secret according to the [ModelMesh instructions](https://github.com/kserve/modelmesh-serving/blob/main/docs/configuration/tls.md)
This secret will setup both MM and TrustyAI encryption.

```shell
export NS="opendatahub"  # the controller namespace where ModelMesh Serving was deployed
export SECRET_NAME="trustyai-certificate"
export TRUSTYAI_SERVICE="trustyai-service"
```
Create an OpenSSL configuration file named `openssl-san.config`.
The TrustyAI service name **must** match the value provided below. For instance, if creating a TrustyAI service called
`trustyai-service` in namespace `test`, the value below must be `trustyai-service.test.svc`
```shell
cat > openssl-san.config << EOF
[ req ]
distinguished_name = req
[ san ]
subjectAltName = DNS:modelmesh-serving.${PROJ_NS},DNS:localhost,IP:0.0.0.0,DNS:${TRUSTYAI_SERVICE}.${PROJ_NS}.svc
EOF
```
Use the following command to create a SAN key/cert:

```shell
openssl req -x509 -newkey rsa:4096 -sha256 -days 3560 -nodes \
    -keyout server.key \
    -out server.crt \
    -subj "/CN=${PROJ_NS}" \
    -extensions san \
    -config openssl-san.config
```

From there, you can create a secret using the generated certificate and key:

```shell
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  namespace: ${NS}
  name: ${SECRET_NAME}
type: kubernetes.io/tls
data:
  tls.crt: $(cat server.crt | base64 | tr -d '\n')
  tls.key: $(cat server.key | base64 | tr -d '\n')
  ca.crt: $(cat server.crt | base64 | tr -d '\n')
EOF
```

This will configure MM to use TLS for gRPC.
We now must make it available to a TrustyAI service by also applying it on the TrustyAI namespace

```shell
kubectl apply -f - <<EOF
---
apiVersion: v1
kind: Secret
metadata:
  namespace: ${PROJ_NS}
  name: ${SECRET_NAME}
type: kubernetes.io/tls
data:
  tls.crt: $(cat server.crt | base64 | tr -d '\n')
  tls.key: $(cat server.key | base64 | tr -d '\n')
  ca.crt: $(cat server.crt | base64 | tr -d '\n')
EOF
```

You must now configure ModelMesh and apply

```shell
oc apply -f resources/model-serving-config.yaml -n $NS
```

Deploy the model
```shell
oc patch namespace $PROJ_NS -p '{"metadata":{"labels":{"modelmesh-enabled":"true"}}}'
oc apply -f resources/storage-config.yaml -n $PROJ_NS
oc apply -f resources/ovms-1.x.yaml -n $PROJ_NS
oc apply -f resources/mlserver-1.x.yaml -n $PROJ_NS
oc apply -f resources/model-housing.yaml -n $PROJ_NS

```

Create a route to ModelMesh

```shell
oc apply -f resources/mm-route.yaml -n $PROJ_NS
```

### Install TrustyAI

1. Install a TrustyAI service
   ```shell
    oc apply -f resources/trustyai-cr.yaml -n $PROJ_NS
   ```

### Data

Populate with some data
```shell
sh ./data/01-upload-data.sh
```
   
## Validation

1. The `MM_PAYLOAD_PROCESSORS` variable on ModelMesh **must** start with `https` (not `http`)
2. Sending an inference requests to the model (protocol not important) should
   1. **Not cause an error** in the ModelMesh `mm` container logs
   2. **Be received** by the TrustyAI service (check either via logs, CSV inspection or endpoints)