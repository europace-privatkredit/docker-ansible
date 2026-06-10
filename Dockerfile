# syntax=docker/dockerfile:1
# check=skip=SecretsUsedInArgOrEnv
FROM python:3.14-slim

ENV ANSIBLE_HOST_KEY_CHECKING="False"
ENV ANSIBLE_VERSION="14.0.0"

ARG TARGETARCH

ENTRYPOINT ["/docker-entrypoint.sh"]

ADD aws_cli.pub /

RUN if [ "${TARGETARCH}" = "amd64" ]; then \
    export SESSION_MANAGER_TARGET="ubuntu_64bit"; \
  elif [ "${TARGETARCH}" = "arm64" ]; then \
    export SESSION_MANAGER_TARGET="ubuntu_arm64"; \
  else \
    echo "Unsupported architecture: ${TARGETARCH}}" &>2; return 1; \
  fi && \
  mkdir /ansible && mkdir /ansible-support && \
  apt-get update && apt-get -y upgrade && apt-get -y install git gosu tar unzip rsync openssh-client curl gpg && rm -rf /var/lib/apt/lists/* && \
  echo "Downloading https://s3.amazonaws.com/session-manager-downloads/plugin/latest/${SESSION_MANAGER_TARGET}/session-manager-plugin.deb" && \
  curl -s "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/${SESSION_MANAGER_TARGET}/session-manager-plugin.deb" -o "session-manager-plugin.deb" && \
  dpkg -i session-manager-plugin.deb && \
  rm session-manager-plugin.deb && \
  groupadd --system ansible && useradd --system -g ansible ansible && \
  python3 -m venv /home/ansible/venv && \
  . /home/ansible/venv/bin/activate && \
  pip --no-cache-dir install --upgrade pip && \
  pip --no-cache-dir install --upgrade docker ansible==${ANSIBLE_VERSION} hvac jmespath boto3 && \
  gpg --import /aws_cli.pub && \
  curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "awscliv2.zip" && \
  curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip.sig" -o "awscliv2.sig" && \
  gpg --verify awscliv2.sig awscliv2.zip && \
  unzip awscliv2.zip && \
  ./aws/install && \
  rm -rf awscliv2.zip awscliv2.sig aws && \
  chown -R ansible:ansible /home/ansible/venv && \
  mkdir /home/ansible/.ssh && \
  chown ansible:ansible /home/ansible/.ssh && \
  chmod 0700 /home/ansible/.ssh && \
  ansible --version

COPY ./docker-entrypoint.sh /

WORKDIR /ansible
