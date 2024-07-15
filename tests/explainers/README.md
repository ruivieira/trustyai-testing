## Data Science Cluster

The `trustyai` field on the `DataScienceCluster` to test these images is:

```yaml
 trustyai:
      devFlags:
        manifests:
          - contextDir: config
            sourcePath: ''
            uri: https://api.github.com/repos/ruivieira/trustyai-service-operator/tarball/test/explainers
```

## Validations

### Model `explainer-test-a`

`InferenceService`:

```yaml
apiVersion: serving.kserve.io/v1beta1
kind: InferenceService
metadata:
  name: example-sklearn-isvc
  annotations:
    serving.kserve.io/deploymentMode: ModelMesh
spec:
  predictor:
    model:
      modelFormat:
        name: sklearn
      runtime: mlserver-1.x
      storageUri: "https://github.com/trustyai-explainability/model-collection/raw/main/explainer-test-a/model.joblib"
```

#### LIME

TrustyAI service LIME payload

```shell
curl -skv -X POST \
-H "Content-Type: application/json" \
-d "{
    \"predictionId\": \"$ID\",
    \"config\": {
        \"model\": {
            \"target\": \"${MODELMESH_SERVICE}.${EXPLAINER_NS}.svc.cluster.local:8033\",
            \"name\": \"${MODEL}\",
            \"version\": \"v1\"
        },
        \"explainer\": {
          \"n_samples\": 2000,
          \"normalize_weights\": \"true\",
          \"retries\": 2
        }
    }
}" \
http://localhost:8080/explainers/local/lime
```

| Input            | Output               | LIME Saliencies                                | Python TrustyAI Saliencies | Service Saliencies                                                                                                                                                                                                 |
|------------------|----------------------|------------------------------------------------|----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `[[10.0, 20.0]]` | `102.26996632145493` | `[('X1 <= 10.00', 0.0), ('X2 <= 20.00', 0.0)]` |                            | `{"timestamp":"2024-07-15T14:18:55.150+00:00","type":"explanation","saliencies":{"predict-0":[{"name":"inputs-0","score":0.0,"confidence":0.0},{"name":"inputs-1","score":0.6144254953400248,"confidence":0.0}]}}` |
|                  |                      |                                                |                            |                                                                                                                                                                                                                    |
|                  |                      |                                                |                            |                                                                                                                                                                                                                    |
#### SHAP

TrustyAI service SHAP payload

```shell
curl -skv -X POST \
-H "Content-Type: application/json" \
-d "{
    \"predictionId\": \"$ID\",
    \"config\": {
        \"model\": {
            \"target\": \"${MODELMESH_SERVICE}.${EXPLAINER_NS}.svc.cluster.local:8033\",
            \"name\": \"${MODEL}\",
            \"version\": \"v1\"
        },
        \"explainer\": {
          \"n_samples\": 2000
        }
    }
}" \
http://localhost:8080/explainers/local/shap
```

| Input            | Output               | SHAP Saliencies                                                                                                               | Python TrustyAI Saliencies | Service Saliencies                                                                                                                                                                                                 |
|------------------|----------------------|-------------------------------------------------------------------------------------------------------------------------------|----------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `[[10.0, 20.0]]` | `102.26996632145493` | `[102.26996632] .values =array([[74.71468144   1.5834439 ]]) .base_values = array([25.97184098]) .data = array([[10., 20.]])` |                            | `{"timestamp":"2024-07-15T14:20:55.532+00:00","type":"explanation","saliencies":{"predict-0":[{"name":"inputs-0","score":0.0,"confidence":0.0},{"name":"inputs-1","score":-0.09804606165315022,"confidence":0.0},{"name":"Background","score":102.26996632145493,"confidence":0.0}]}}` |
|                  |                      |                                                                                                                               |                            |                                                                                                                                                                                                                    |
|                  |                      |                                                                                                                               |                            |                                                                                                                                                                                                                    |

