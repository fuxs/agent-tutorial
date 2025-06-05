#!/bin/sh
if [ -z ${GOOGLE_CLOUD_PROJECT+x} ];
then
    echo "Please run the 'gcloud config set ...' command first"
    exit
fi

# change dir
cd ~/cloudshell_open/agent-tutorial/
# open workspace
cloudshell ws .
# enable apis
gcloud services enable aiplatform.googleapis.com run.googleapis.com
# install uv
curl -LsSf https://astral.sh/uv/install.sh | sh
# install python packages
uv sync
# activate python environment
source .venv/bin/activate
# write the .env file
cat <<EOF > .env
GOOGLE_CLOUD_PROJECT="$GOOGLE_CLOUD_PROJECT"
GOOGLE_CLOUD_LOCATION="us-central1"
GOOGLE_GENAI_USE_VERTEXAI="True"
EOF
