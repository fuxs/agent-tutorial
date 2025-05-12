# First tutorial

## Select a project

<walkthrough-project-setup></walkthrough-project-setup>

## Open the Cloud Shell

We will use the Cloud Shell in this tutorial.

<walkthrough-open-cloud-shell-button></walkthrough-open-cloud-shell-button>

### Install uv

We use `uv` for Python packet and project management.

Copy the following line and execute it in the Cloud Shell.


```shell
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Co

```
agents
├── .venv
│   ├── bin
│   ├── lib
│   └── pyvenv.cfg
├── .python-version
├── README.md
├── main.py
├── pyproject.toml
└── uv.lock
```

```sh
uv init agents &&
cd agents &&
uv venv &&
uv add google-adk &&
mkdir -p daisy &&
touch daisy/{agent.py,tools.py} &&
cat <<EOF > .env
GOOGLE_CLOUD_PROJECT="<walkthrough-project-name/>"
GOOGLE_CLOUD_LOCATION="us-central1"
GOOGLE_GENAI_USE_VERTEXAI="True"
EOF
cat <<EOF > daisy/__init__.py
from . import agent
EOF
if [ -x "$(command -v cloudshell)" ]; then
  cloudshell ws .
fi
```

Open the file 
<walkthrough-editor-open-file filePath="agents/daisy/agent.py">agent.py</walkthrough-editor-open-file>
and paste the following code:
```py
from google.adk.agents.llm_agent import LlmAgent

root_agent = LlmAgent(
    model="gemini-2.0-flash",
    name="daisy_agent",
    instruction="You name is Daisy and you are an expert for flowers.",
)
```

```sh
uv run adk run daisy
```

```sh
uv run adk web --port 8080
```

```sh
uv run adk deploy cloud_run \
--project=<walkthrough-project-id/> \
--region=us-central1 \
--service_name=daisy-agent-service \
--with_ui \
daisy/
```

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
  --project=<walkthrough-project-id/> \
  --region=us-central1 \
  --source Dockerfile \
  --concurrency 4 \ 
  --cpu 8 \
  --set-env-vars OLLAMA_NUM_PARALLEL=4 \
  --gpu 1 \
  --gpu-type nvidia-l4 \
  --max-instances 1 \
  --memory 32Gi \
  --no-allow-unauthenticated \
  --no-cpu-throttling \
  --no-gpu-zonal-redundancy \
  --timeout=600
```

## Third step

## Conclusion

Done!