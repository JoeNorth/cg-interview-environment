#!/bin/bash

set -e

mkdir -p ~/.local/share/code-server/User
touch ~/.local/share/code-server/User/settings.json
cat << EOF > ~/.local/share/code-server/User/settings.json
{
  "extensions.autoUpdate": false,
  "extensions.autoCheckUpdates": false,
  "security.workspace.trust.enabled": false,
  "task.allowAutomaticTasks": "on",
  "telemetry.telemetryLevel": "off",
  "workbench.startupEditor": "terminal",
  "explorer.confirmDragAndDrop": false,
  "terminal.integrated.fontSize": 20,
  "editor.fontSize": 16
}

EOF

mkdir -p ~/environment/.vscode
cat << EOF > ~/environment/.vscode/settings.json
{
  "files.exclude": {
    "**/.*": true
  }
}
EOF

echo '{ "query": { "folder": "/home/ec2-user/environment" } }' > ~/.local/share/code-server/coder.json

code-server --install-extension redhat.vscode-yaml --force || true
code-server --install-extension ms-kubernetes-tools.vscode-kubernetes-tools --force || true