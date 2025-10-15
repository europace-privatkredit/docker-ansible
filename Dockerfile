# syntax=docker/dockerfile:1
# check=skip=SecretsUsedInArgOrEnv
FROM python:3.13-slim

ENV ANSIBLE_HOST_KEY_CHECKING="False"
ENV ANSIBLE_VERSION="12.1.0"

ARG TARGETARCH

ENTRYPOINT ["/docker-entrypoint.sh"]

RUN if [ "${TARGETARCH}" = "amd64" ]; then \
    export SESSION_MANAGER_TARGET="ubuntu_64bit"; \
  elif [ "${TARGETARCH}" = "arm64" ]; then \
    export SESSION_MANAGER_TARGET="ubuntu_arm64"; \
  else \
    echo "Unsupported architecture: ${TARGETARCH}}" &>2; return 1; \
  fi && \
  mkdir /ansible && mkdir /ansible-support && \
  pip3 --no-cache-dir install --upgrade pip && \
  pip3 --no-cache-dir install --upgrade docker ansible==${ANSIBLE_VERSION} hvac jmespath boto3 awscli && \
  apt update && apt -y install git gosu tar rsync openssh-client curl && rm -rf /var/lib/apt/lists/* && \
  echo "Downloading https://s3.amazonaws.com/session-manager-downloads/plugin/latest/${SESSION_MANAGER_TARGET}/session-manager-plugin.deb" && \
  curl -s "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/${SESSION_MANAGER_TARGET}/session-manager-plugin.deb" -o "session-manager-plugin.deb" && \
  dpkg -i session-manager-plugin.deb && \
  rm session-manager-plugin.deb && \
  groupadd --system ansible && useradd --system -g ansible ansible && \
  python3 -m venv --system-site-packages /home/ansible/venv && \
  chown -R ansible:ansible /home/ansible/venv && \
  mkdir /home/ansible/.ssh && \
  chown ansible:ansible /home/ansible/.ssh && \
  chmod 0700 /home/ansible/.ssh && \
  ansible --version

COPY ./docker-entrypoint.sh /

WORKDIR /ansible
