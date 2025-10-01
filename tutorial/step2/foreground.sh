#!/bin/bash

echo "Setting up pipx and checkov..." > /tmp/setup2.log

echo "installing pipx..." >> /tmp/setup2.log
apt install -y pipx

echo "installing checkov..." >> /tmp/setup2.log
pipx install checkov

# Add pipx to PATH for current session
echo "exporting path var" >> /tmp/setup2.log
export PATH="$PATH:/root/.local/share/pipx/venvs/checkov"
echo 'export PATH="$PATH:/root/.local/share/pipx/venvs/checkov"' >> /root/.bashrc

echo "ensuring path" >> /tmp/setup2.log
pipx ensurepath

echo "restarting bash??..." >> /tmp/setup2.log
source .bashrc

echo "pipx installed and checkov configured!" >> /tmp/setup2.log