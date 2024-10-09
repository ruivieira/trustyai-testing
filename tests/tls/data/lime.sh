MODEL="housing"
TOKEN=$(oc whoami -t)
TRUSTYAI_ROUTE=$(oc get route trustyai-service -n opendatahub-model -o jsonpath='{.spec.host}{.spec.path}')
ID_LOWEST=$(curl -H "Authorization: Bearer ${TOKEN}" -sk ${TRUSTYAI_ROUTE}/info/inference/ids/${MODEL}?type=organic | jq -r '.[-1].id')

echo "Requesting LIME for ${ID_LOWEST}"
curl -sk -H "Authorization: Bearer ${TOKEN}" -X POST \
-H "Content-Type: application/json" \
-d "{
    \"predictionId\": \"$ID_LOWEST\",
    \"config\": {
        \"model\": {
            \"name\": \"${MODEL}\",
            \"version\": \"v1\"
        },
        \"explainer\": {
          \"n_samples\": 75
        }
    }
}" \
${TRUSTYAI_ROUTE}/explainers/local/lime