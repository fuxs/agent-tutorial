#!/bin/sh

for name in "$@"
do
    mkdir -p "$name"
    touch "$name/agent.py"
    cat <<EOF > "$name/__init__.py"
from . import agent

__all__ = ["agent"]
EOF
done