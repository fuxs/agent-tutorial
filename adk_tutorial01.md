# Agent development with ADK

## Select a project

<walkthrough-project-setup></walkthrough-project-setup>

## Open the Cloud Shell

We will use the Cloud Shell in this tutorial. Please click on the button if it
is not already open.

<walkthrough-open-cloud-shell-button></walkthrough-open-cloud-shell-button>

### Activate APIs

We have to activate some APIs once, before we can run our examples.

* Vertex AI API
* Cloud Run Admin API

Please copy the following snippet to the Cloud Shell and execute it.

<walkthrough-enable-apis apis="aiplatform.googleapis.com,run.googleapis.com"></walkthrough-enable-apis>

## Python Packet Management

We use `uv` for Python packet and project management.

Please copy the following snippet to the Cloud Shell and execute it.

```sh
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Activate the `uv` command with the following command.

```sh
source $HOME/.local/bin/env
```

Run `uv sync` to install all required packages. These are the following:

* google-adk
* google-genai 

```sh
uv sync
```

Activate the current virtual Python environment.

```sh
source .venv/bin/activate
```

## Configuration

The examples require some information to execute. We provide a GCP project-id,
the location and we want to use Vertex AI.

```shell
cat <<EOF > .env
GOOGLE_CLOUD_PROJECT="<walkthrough-project-name/>"
GOOGLE_CLOUD_LOCATION="us-central1"
GOOGLE_GENAI_USE_VERTEXAI="True"
EOF
````

## First Agent

Now you will develop your first agent. A minimal setup requires two files in a
separate directory:

```text
first_agent
├── __init__.py
└── agent.py
```

The file <walkthrough-editor-open-file filePath="first_agent/__init__.py">first_agent/__init__.py</walkthrough-editor-open-file> is needed to treat this directory as a module.

Open the file <walkthrough-editor-open-file filePath="first_agent/agent.py">first_agent/agent.py</walkthrough-editor-open-file>
and paste the following Python code:

```python
from google.adk.agents import LlmAgent
from google.adk.tools import google_search

INSTRUCTION = """Your name is Bob and you are an expert for mobile phones. Use
            the Google search tool whenever you need actual data."""

root_agent = LlmAgent(
    model="gemini-2.0-flash-exp",
    name="first_agent",
    description="An expert for all kind of mobile phones.",
    instruction=INSTRUCTION,
    tools=[google_search],
)
```

Now you can execute the client in the CLI with the following command.

```sh
adk run first_agent
```

Ask the following question:

>*How can you help me?*

Press Control-D to exit the agent.

The selected model supports multi-modal conversations with audio and video.
Therefore you have to start the agent in the web-server:

```sh
adk web --port 8080
```

Open the agent in the web preview by pushing the following button: <walkthrough-web-preview-icon></walkthrough-web-preview-icon>

Select first_agent in the drop-down list in the left top corner.

## Deploy on Cloud Run


```sh
uv run adk deploy cloud_run \
--project=<walkthrough-project-id/> \
--region=us-central1 \
--service_name=daisy-agent-service \
--with_ui \
daisy/
```

When called for the first time, you will bes asked to create an Artifact
Registry Docker repository. Please confirm the creation of a new repository with
`Y` when you are asked.

Do not allow unauthenticated invocations to our `daisy-agent-service` with `N`.

```sh
gcloud run services proxy daisy-agent-service \
--project=<walkthrough-project-id/> \
--region=us-central1 \
--port 8080
```

```sh
gcloud config set project <walkthrough-project-id/>
```
```sh
TOKEN=$(gcloud auth print-identity-token)
APP_URL=$(gcloud run services list --format="value(status.address.url)" --filter="metadata.name=daisy-agent-service")
```

```sh
curl -X GET -H "Authorization: Bearer $TOKEN" $APP_URL/list-apps
```

```sh
curl -X POST -H "Authorization: Bearer $TOKEN" \
    $APP_URL/apps/daisy/users/user_123/sessions/session_abc \
    -H "Content-Type: application/json" \
    -d '{"state": {"preferred_language": "English", "visit_count": 5}}'
```

```shell
curl -X POST -H "Authorization: Bearer $TOKEN" \
    $APP_URL/run_sse \
    -H "Content-Type: application/json" \
    -d '{
    "app_name": "daisy",
    "user_id": "user_123",
    "session_id": "session_abc",
    "new_message": {
        "role": "user",
        "parts": [{
        "text": "How can I water my roses?"
        }]
    },
    "streaming": false
    }'
```

<walkthrough-project-id/>

## Second step

```shell
cat <<EOF > Dockerfile
FROM ollama/ollama:latest

ENV OLLAMA_HOST 0.0.0.0:8080
ENV OLLAMA_MODELS /models
ENV OLLAMA_DEBUG false
ENV OLLAMA_KEEP_ALIVE -1
ENV MODEL gemma3:4b
# stores the model weights in the image
RUN ollama serve & sleep 5 && ollama pull $MODEL

# Start Ollama
ENTRYPOINT ["ollama", "serve"]
EOF
```


```sh
gcloud run deploy ollama-gemma \
  --project=<walkthrough-project-id/>  \
  --region=us-central1 \
  --source=. \
  --concurrency=4 \
  --cpu=8 \
  --set-env-vars=OLLAMA_NUM_PARALLEL=4 \
  --gpu=1 \
  --gpu-type=nvidia-l4 \
  --max-instances=1 \
  --memory=32Gi \
  --no-allow-unauthenticated \
  --no-cpu-throttling \
  --no-gpu-zonal-redundancy \
  --timeout=600
```

```sh
gcloud run services proxy ollama-gemma --port=9090
```

## Third step

## Conclusion

Done!