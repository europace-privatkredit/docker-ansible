#!/bin/sh

# Fork the SSH agent socket so the ansible user can access it without relaxing
# permissions on the original socket (e.g. from 1Password)
if [ -S "${SSH_AUTH_SOCK}" ]; then

  ANSIBLE_SSH_AUTH_SOCK="/tmp/ssh-auth-sock-ansible"
  socat UNIX-LISTEN:"${ANSIBLE_SSH_AUTH_SOCK}",fork,reuseaddr UNIX-CONNECT:"${SSH_AUTH_SOCK}" &
  SOCAT_PID=$!
  trap 'kill ${SOCAT_PID} 2>/dev/null; rm -f ${ANSIBLE_SSH_AUTH_SOCK}' EXIT
  while [ ! -S "${ANSIBLE_SSH_AUTH_SOCK}" ]; do sleep 1; done
  chown ansible:ansible "${ANSIBLE_SSH_AUTH_SOCK}"
  export SSH_AUTH_SOCK="${ANSIBLE_SSH_AUTH_SOCK}"

fi

PRIVATE_KEY_FILE=$(gosu ansible /home/ansible/venv/bin/ansible-config dump | grep DEFAULT_PRIVATE_KEY_FILE | cut -d = -f 2 | awk '{$1=$1};1')
if [ -f "${PRIVATE_KEY_FILE}" ]; then

  # Copy key to Ansible home and take ownership
  PRIVATE_KEY_FILE_BASENAME=$(basename ${PRIVATE_KEY_FILE})
  cp "${PRIVATE_KEY_FILE}" "/home/ansible/.ssh/${PRIVATE_KEY_FILE_BASENAME}"
  chmod 0600 "/home/ansible/.ssh/${PRIVATE_KEY_FILE_BASENAME}"
  chown -R ansible:ansible "/home/ansible/.ssh/${PRIVATE_KEY_FILE_BASENAME}"
  export ANSIBLE_PRIVATE_KEY_FILE="/home/ansible/.ssh/${PRIVATE_KEY_FILE_BASENAME}"

  # Add key to ssh-agent
  eval $(gosu ansible ssh-agent)
  gosu ansible ssh-add "${ANSIBLE_PRIVATE_KEY_FILE}"

fi

VAULT_PASSWORD_FILE=$(gosu ansible /home/ansible/venv/bin/ansible-config dump | grep DEFAULT_VAULT_PASSWORD_FILE | cut -d = -f 2 | awk '{$1=$1};1')
if [ -f "${VAULT_PASSWORD_FILE}" ]; then

  # Copy vault password to Ansible home and take ownership
  VAULT_PASSWORD_FILE_BASENAME=$(basename ${VAULT_PASSWORD_FILE})
  cp "${VAULT_PASSWORD_FILE}" "/home/ansible/${VAULT_PASSWORD_FILE_BASENAME}"
  chmod 0600 "/home/ansible/${VAULT_PASSWORD_FILE_BASENAME}"
  chown -R ansible:ansible "/home/ansible/${VAULT_PASSWORD_FILE_BASENAME}"
  export ANSIBLE_VAULT_PASSWORD_FILE="/home/ansible/${VAULT_PASSWORD_FILE_BASENAME}"

fi

ANSIBLE_COMMANDS=$(find /home/ansible/venv/bin/ -name 'ansible*' -exec basename {} \;)
for ansible_command in $ANSIBLE_COMMANDS; do
  if [ "$1" = "${ansible_command}" ]; then
    rm -rf /home/ansible/.ansible
    . /home/ansible/venv/bin/activate
    exec gosu ansible "$@"
  fi
done

exec "$@"
