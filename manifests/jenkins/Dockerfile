FROM maven:3.9.9-eclipse-temurin-21-alpine

# Install required dependencies
RUN apk add --no-cache python3 py3-pip docker jq git curl bash

# Install gcloud cli
RUN wget -nv https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz \
  && mkdir -p /opt && cd /opt \
  && tar -xzf /google-cloud-cli-linux-x86_64.tar.gz \
  && rm /google-cloud-cli-linux-x86_64.tar.gz \
  && /opt/google-cloud-sdk/install.sh --usage-reporting=false --bash-completion=false --additional-components gke-gcloud-auth-plugin\
  && rm -rf ~/.config/gcloud \
  && rm -rf /opt/google-cloud-sdk/.install/.backup

ENV PATH="$PATH:/usr/local/bin/:/opt/google-cloud-sdk/bin/"

CMD ["sleep", "infinity"]