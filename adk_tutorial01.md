# Agent development with ADK

## Select a GCP project

<walkthrough-project-setup></walkthrough-project-setup>

### Open the code in the Editor

Execute the following command to open the code in the editor:

```sh
cloudshell ws .
```

### Activate APIs

You have to activate some APIs once, before you can run our examples.

* Vertex AI API
* Cloud Run Admin API

Please copy the following snippet to the Cloud Shell and execute it.

<walkthrough-enable-apis
apis="aiplatform.googleapis.com,run.googleapis.com"></walkthrough-enable-apis>

## Python packet management

We use `uv` for Python packet and project management.

Please copy the following snippet to the Cloud Shell and execute it. This will
install `uv` to your Cloud Shell instance.

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
the location and we want to use Vertex AI. Copy the following command to the
Cloud Shell and execute it.

```shell
cat <<EOF > .env
GOOGLE_CLOUD_PROJECT="<walkthrough-project-name/>"
GOOGLE_CLOUD_LOCATION="us-central1"
GOOGLE_GENAI_USE_VERTEXAI="True"
EOF
```

Open the file in the editor with the following button:

<walkthrough-editor-open-file filePath=".env">Open
.env</walkthrough-editor-open-file>

## First agent

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

## Run the agent

Now you can execute the agent in the CLI with the following command.

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

## FastAPI server

You can test your agent with a local FastAPI server. Execute the following
command:

```sh
adk api_server
```

First, you have to initialize a session for a user. Take a closer look at the
URL. It references a user id `user_123` with a session id `session_abc` for the
app `first_agent`.

```sh
curl -X POST http://0.0.0.0:8000/apps/first_agent/users/user_123/sessions/session_abc \
    -H "Content-Type: application/json" \
    -d '{"state": {"preferred_language": "English", "visit_count": 5}}'
```

Now you can send your request to the agent referencing the initialized session.

```shell
curl -X POST http://0.0.0.0:8000/run_sse \
    -H "Content-Type: application/json" \
    -d '{
    "app_name": "first_agent",
    "user_id": "user_123",
    "session_id": "session_abc",
    "new_message": {
        "role": "user",
        "parts": [{
        "text": "Which is the latest phone from google?"
        }]
    },
    "streaming": false
    }'
```

## MCP

The Model Context Protocol MCP is an open protocol that standardizes how
applications provide context to LLMs
([Introduction](https://modelcontextprotocol.io/introduction)).

You will create a MCP server and an agent connecting to it.

### MCP Server

The following code provides a service with 4 basic arithmetic operations. Open
the file  <walkthrough-editor-open-file filePath="mcp_server/server.py">mcp_server/server.py</walkthrough-editor-open-file>
and paste the following Python code:

```python
from fastmcp import FastMCP
import asyncio

mcp = FastMCP("Calculator Server")


@mcp.tool()
def add(a: int, b: int) -> int:
    """Add parameter a to b"""
    return a + b


@mcp.tool()
def subtract(a: int, b: int) -> int:
    """Subtract parameter b from a"""
    return a - b


@mcp.tool()
def multiply(a: int, b: int) -> int:
    """Multiply parameter a with b"""
    return a * b


@mcp.tool()
def divide(a: int, b: int) -> int:
    """Divide parameter a by b"""
    return a / b


if __name__ == "__main__":
    asyncio.run(mcp.run_sse_async(host="0.0.0.0", port=8080))

```

The folder contains 2 other files:

* <walkthrough-editor-open-file filePath="mcp_server/Procfile">mcp_server/Procfile</walkthrough-editor-open-file> used by Cloud Run to run the web server
* <walkthrough-editor-open-file filePath="mcp_server/requirements.txt">mcp_server/requirements.txt</walkthrough-editor-open-file> the Python dependencies

```sh
gcloud run deploy mcp-server \
--project=<walkthrough-project-id/> \
--source mcp_server \
--region us-central1 \
--allow-unauthenticated
```

It takes some time to build and deploy the container image.

## MCP agent

Copy the following code to <walkthrough-editor-open-file filePath="mcp_server/server.py">mcp_server/server.py</walkthrough-editor-open-file>.

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool.mcp_toolset import MCPToolset, SseServerParams

# replace this namespace with yours
NAMESPACE="000000000000"

async def create_agent():
    tools, exit_stack = await MCPToolset.from_server(
        connection_params=SseServerParams(
            url=f"https://mcp-server-{NAMESPACE}.us-central1.run.app:8080/sse",
        ),
    )
    agent = Agent(
        name="calculator",
        model="gemini-2.0-flash",
        instruction="""You are a helpful AI assistant designed
          to provide accurate and useful information.""",
        tools=tools,
    )
    return agent, exit_stack


root_agent = create_agent()

```

Run the following command in the Cloud Shell to get the namespace of your Cloud
Run service instance.

```sh
gcloud run services describe mcp-server \
--project=<walkthrough-project-id/> \
--region=us-central1 \
--format="value(metadata.namespace)"
```

Copy the number and replace the value in the line `NAMESPACE="000000000000"`

Now you can execute the agent in the CLI with the following command.

```sh
adk run calculator
```

Ask the following questions:

>*How can you help me?*
>
>*Add 100 to 200*
>
>*Subtract 50 and divide by 5*

Press Control-D to exit the agent.

Optional: stop and delete the MCP server with the following command

```sh
gcloud run services delete mcp-server \
--project=<walkthrough-project-id/> \
--region=us-central1 \
--quiet
```



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
