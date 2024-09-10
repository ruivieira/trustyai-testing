# Detoxify in disconnected

Steps to download the required models from HuggingFace so that they can be copied to the disconnected cluster.

## Create enviroment

Create a Python venv using (from this `README.md`'s folder)

```shell
python -m venv .env
source .env/bin/activate
```

Install the necessary Python dependencies

```shell
pip install huggingface-hub ipython
```

Download the required models for offline use. These are:
- `facebook/bart-large`, tokenizer and base model
- `trustyai/gminus`, `trustyai/gplus` TrustyAI's expert and anti-expert models

Start `ipython`

```shell
ipython
```

From the Python shell run

```python
from huggingface_hub import snapshot_download

snapshot_download(repo_id="facebook/bart-large", local_dir="models/bart")
snapshot_download(repo_id="trustyai/gminus", local_dir="models/gminus")
snapshot_download(repo_id="trustyai/gplus", local_dir="models/gplus")
```

You should now have a sub-folder called `models` with three other folders inside `bart`, `gminus`, `gplus`.

## Copying to Minio

> Make sure you have `mc` [installed](https://min.io/docs/minio/linux/reference/minio-mc.html#install-mc)

Assuming you have Minio instance running at `<minio-server-url>`, with credentials `<access-key>` and `<secret-key>`, you can now copy the files.

```shell
mc alias set detoxminio <minio-server-url> <access-key> <secret-key>
mc cp --recursive ./models detoxminio/trustyai-detox-models/models
```

## Copying to the notebook

From the Jupyter Lab instance, use `boto` (already installed in the image) to copy the files:

```python
import boto3
from botocore.client import Config

s3_client = boto3.client(
    's3',
    endpoint_url=<minio-server-url>,
    aws_access_key_id=<access-key>,
    aws_secret_access_key=<secret-key>)
)
```

Download the files

```python
import os

def download_files(bucket_name, prefix, local_dir):
    paginator = s3_client.get_paginator('list_objects_v2')
    for page in paginator.paginate(Bucket=bucket_name, Prefix=prefix):
        for obj in page.get('Contents', []):
            file_key = obj['Key']
            local_file_path = os.path.join(local_dir, file_key)

            local_file_dir = os.path.dirname(local_file_path)
            if not os.path.exists(local_file_dir):
                os.makedirs(local_file_dir)

            print(f"Downloading {file_key} to {local_file_path}")
            s3_client.download_file(bucket_name, file_key, local_file_path)

download_files('trustyai-detox-models', 'models/', './models')
```

## Use Detoxification notebook

Provided the models are available from the Jupyter notebook, run the example [Detoxify notebook](./Detoxify.ipynb) found in this directory.