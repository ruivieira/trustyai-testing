#!/usr/bin/env bash

MODEL_ROUTE=$(oc get route housing -n opendatahub-model -o jsonpath='{.spec.host}')
TOKEN=$(oc whoami -t)
echo "Using ${MODEL_ROUTE}"


curl -kv -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" ${MODEL_ROUTE}:8008/infer -d ./@input-data-small.json
