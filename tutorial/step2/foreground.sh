#!/bin/bash
echo waiting for background script to finish
while [ ! -f /tmp/setup2.log ]; do sleep 1; done

echo background script done, starting foreground script

echo "installing checkov..." >> /tmp/setup2.log
pipx install checkov

# Add pipx to PATH for current session
echo "exporting path var" >> /tmp/setup2.log
export PATH="$PATH:/root/.local/share/pipx/venvs/checkov"
echo 'export PATH="$PATH:/root/.local/share/pipx/venvs/checkov"' >> /root/.bashrc

echo "ensuring path" >> /tmp/setup2.log
pipx ensurepath

echo "restarting bash..." >> /tmp/setup2.log
source /root/.bashrc

echo "pipx installed and checkov configured!" >> /tmp/setup2.log

checkov