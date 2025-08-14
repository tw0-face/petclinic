FROM mcr.microsoft.com/devcontainers/java:1-21-bullseye

RUN sudo apt-get update && sudo apt-get install iptables -y

RUN mkdir -p /home/vscode/.signadot/

RUN chown vscode:vscode /home/vscode/.signadot/

COPY --chown=vscode:vscode manifests/signadot/config.yaml /home/vscode/.signadot/

# Install Signadot CLI
RUN curl -sSLf https://raw.githubusercontent.com/signadot/cli/main/scripts/install.sh | sh

COPY --chown=vscode:vscode manifests/signadot/dev /usr/local/bin/dev

RUN chmod +x /usr/local/bin/dev

RUN <<EOR

sudo tee -a /etc/bash.bashrc <<'BASH'

echo """
#######################################################
# Use: dev [service] to start development environment # 
#######################################################
"""

BASH

EOR