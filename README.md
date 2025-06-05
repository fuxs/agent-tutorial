# Agent Tutorial

Click the following button to open the Cloud Shell with a tutorial in this tab.
Trust the repo and confirm it. Authorize Cloud Shell and follow the instructions
in the tutorial on the right hand side.

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.png)](https://ssh.cloud.google.com/cloudshell/open?cloudshell_git_repo=https://github.com/fuxs/agent-tutorial.git&cloudshell_tutorial=adk_tutorial01.md)

## Useful links

* <a target="_blank" href="https://google.github.io/adk-docs/">Agent Development Kit documentation</a>
* <a target="_blank" href="https://shell.cloud.google.com/?show=ide%2Cterminal">Cloud Shell in new tab</a>
* <a target="_blank" href="https://console.cloud.google.com/welcome">Cloud Console in new tab</a>

## Troubleshooting

### Access error

An access error message can have multiple reasons. First check, if the required
APIs are activated. Execute the following command in the Cloud Shell.

```shell
gcloud services enable \
    aiplatform.googleapis.com \
    run.googleapis.com
```

In some rare cases, an authentication update may be necessary. If this occurs,
please run the following command in Cloud Shell and adhere to the provided
instructions.

```shell
gcloud auth login
```

### Launch the tutorial again

You can launch the tutorial with the following command in the Cloud Shell.

```shell
cloudshell launch-tutorial ~/cloudshell_open/agent-tutorial/adk_tutorial01.md
```

### Command `uv` not found

Install `uv` with the following command in the Cloud Shell.

```shell
curl -LsSf https://astral.sh/uv/install.sh | sh
```

If the command `uv` still cannot be found execute the next command.

```shell
source ~/.local/bin/env
```
