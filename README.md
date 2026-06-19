# Ansible in Docker

A flexible Ansible environment in Docker, batteries included.

## What's included

- **Ansible** community package 14.0.0
- **AWS CLI v2** (with signature verification)
- **AWS Session Manager Plugin** (for SSM-based SSH tunnels)
- **boto3**, **hvac**, **jmespath**, **docker** Python packages
- **ssh-agent** support for private key and forwarded agent socket workflows
- Runs as non-root user `ansible` inside a **virtualenv**, so playbooks can install additional Python packages without permission issues

## Ansible project

Mount your Ansible project at `/ansible` — that's also the working directory, so relative paths in `ansible.cfg` and inventory files resolve as expected.

```bash
-v "${YOUR_ANSIBLE_PROJECT}:/ansible:ro"
```

## SSH authentication

### Option A: Private key file

Mount a private key and point `ANSIBLE_PRIVATE_KEY_FILE` at it. The entrypoint copies it into the `ansible` user's home, fixes permissions, and adds it to a fresh `ssh-agent` — so password-protected keys work without manual interaction.

```bash
docker run -it --rm \
  -v "${YOUR_ANSIBLE_PROJECT}:/ansible:ro" \
  -v "${HOME}/.ssh/id_rsa:/ansible-support/id_rsa:ro" \
  -e "ANSIBLE_PRIVATE_KEY_FILE=/ansible-support/id_rsa" \
  hypoport/ansible:14.0.0 ansible-playbook site.yml
```

You can also configure `DEFAULT_PRIVATE_KEY_FILE` via `ansible.cfg` instead of the environment variable.

### Option B: SSH agent socket (e.g. 1Password, forwarded agent)

Pass an existing agent socket into the container via `SSH_AUTH_SOCK`. The entrypoint makes the socket accessible to the `ansible` user automatically.

```bash
docker run -it --rm \
  -v "${YOUR_ANSIBLE_PROJECT}:/ansible:ro" \
  -v "${SSH_AUTH_SOCK}:/tmp/ssh-agent.sock" \
  -e "SSH_AUTH_SOCK=/tmp/ssh-agent.sock" \
  hypoport/ansible:14.0.0 ansible-playbook site.yml
```

## Ansible Vault

Mount a vault password file and point `ANSIBLE_VAULT_PASSWORD_FILE` at it. The entrypoint copies it into the `ansible` user's home and fixes permissions.

```bash
docker run -it --rm \
  -v "${YOUR_ANSIBLE_PROJECT}:/ansible:ro" \
  -v "${YOUR_VAULT_KEY_FILE}:/ansible-support/vault_key:ro" \
  -e "ANSIBLE_VAULT_PASSWORD_FILE=/ansible-support/vault_key" \
  hypoport/ansible:14.0.0 ansible-playbook site.yml
```

You can also configure `DEFAULT_VAULT_PASSWORD_FILE` via `ansible.cfg`.

## AWS access

Mount your AWS config directory or pass credentials as environment variables. AWS CLI and boto3 are both available.

```bash
docker run -it --rm \
  -v "${YOUR_ANSIBLE_PROJECT}:/ansible:ro" \
  -v "${HOME}/.aws:/aws-config:ro" \
  -e "AWS_CONFIG_FILE=/aws-config/config" \
  -e "AWS_SHARED_CREDENTIALS_FILE=/aws-config/credentials" \
  -e "AWS_PROFILE" \
  hypoport/ansible:14.0.0 ansible-playbook site.yml
```

Or with short-lived credentials:

```bash
docker run -it --rm \
  -v "${YOUR_ANSIBLE_PROJECT}:/ansible:ro" \
  -e "AWS_ACCESS_KEY_ID" \
  -e "AWS_SECRET_ACCESS_KEY" \
  -e "AWS_SESSION_TOKEN" \
  -e "AWS_DEFAULT_REGION" \
  hypoport/ansible:14.0.0 ansible-playbook site.yml
```

## Ansible configuration via environment

Any [Ansible environment variable](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ansible-configuration-settings) is passed through to Ansible unchanged. The exceptions are `ANSIBLE_PRIVATE_KEY_FILE` and `ANSIBLE_VAULT_PASSWORD_FILE`, which are rewritten by the entrypoint to point at copies owned by the `ansible` user.

## Releasing

```bash
docker buildx build --platform linux/amd64,linux/arm64 -t hypoport/ansible:<version> --push .
```
