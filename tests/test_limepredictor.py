"""KServe explainer test suite"""
import json
import requests
import joblib
from Typing import List

from kubernetes import config, dynamic
from kubernetes.dynamic.exceptions import ResourceNotFoundError
from kubernetes.client import api_client


def test_limepredictions(
     name: str, namespace: str, isvc_name: str, data: List, local_model_path
):
    """
    Test Python model to KServe Inference Service conversion
    """
    # Get Inference Service route
    try:
        k8s_client = config.load_incluster_config()
    except config.ConfigException:
        k8s_client = config.load_kube_config()
    dyn_client = dynamic.DynamicClient(api_client.ApiClient(configuration=k8s_client))
    route_api = dyn_client.resources.get(api_version="v1", kind="Route")
    try:
        service_hostname = route_api.get(name=isvc_name, namespace=namespace)
    except ResourceNotFoundError:
        print(f"Error accessing service {isvc_name} in namespace {namespace}.")

    # Request predictions
    response = requests.post(
        f"http://localhost:8080/v1/models/{name}:predict",
        data=json.dumps({"instances": [data]}),
        headers={
        "Host": service_hostname.status.url,
        "Content-Type": "application/json",
        },
        timeout=10
    )
    if response.status_code != 200:
        print(f"Error {response.status_code}: {response.reason}")
    else:
        isvc_output = response.json()["predictions"]

    # Load local model and compare outputs
    model = joblib.load(local_model_path)
    model_output = model(data).to_list()
    assert isvc_output == model_output
