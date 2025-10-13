# Ansible in Docker

A simple yet flexible Ansible environment in Docker.

It expects your Ansible project at path `/ansible`. You can build your own container and copy it there or simply use a volume mount.

All Ansible commands will be run as non-root user `ansible`. They will be executed via `virtualenv`, so you are still able to install additional Python packages from your Playbooks or Ad-Hoc commands.

## Adding your private key

Before any command is run, we copy whatever file is configured as `DEFAULT_PRIVATE_KEY_FILE` into the home directory of the `ansible` user and adjust its permissions.

We extract `DEFAULT_PRIVATE_KEY_FILE` from the effective configuration, so you can either configure it - for example - via environment variable `ANSIBLE_PRIVATE_KEY_FILE` or `ansible.cfg`.

After copying and chowning the file, we adjust the `ANSIBLE_PRIVATE_KEY_FILE` variable to point to the new file.

Eventually we start an `ssh-agent` and add the key to it. This makes working with password protected private keys much more convenient.

## Adding a vault password file

Before any command is run, we copy whatever file is configured as `DEFAULT_VAULT_PASSWORD_FILE` into the home directory of the `ansible` user and adjust its permissions.

We extract `DEFAULT_VAULT_PASSWORD_FILE` from the effective configuration, so you can either configure it - for example - via environment variable `ANSIBLE_VAULT_PASSWORD_FILE` or `ansible.cfg`.

After copying and chowning the file, we adjust the `ANSIBLE_VAULT_PASSWORD_FILE` variable, and therefore the configuration, to point to the new file.

## Configuring Ansible via Environment

Any given [Ansible environment variable](https://docs.ansible.com/ansible/latest/reference_appendices/config.html#ansible-configuration-settings) will be passed on to Ansible, just as it would be in a non-containerized environment. The only exceptions are `ANSIBLE_VAULT_PASSWORD_FILE` and `ANSIBLE_PRIVATE_KEY_FILE` for the reasons mentioned above.

## Example

The following exmaple shows how to:

* Mount Ansible project a volume at path `/ansible`
* Adding an existing private key
* Adding a vault password file

```bash
docker run -it --rm
  -v "${YOUR_ANSIBLE_PROJECT}:/ansible:ro"
  -v "${HOME}/.ssh/id_rsa:/ansible-support/id_rsa:ro"
  -v "${YOUR_VAULT_KEY_FILE}:/ansible-support/vault_key:ro"
  -e "ANSIBLE_PRIVATE_KEY_FILE=/ansible-support/id_rsa"
  -e "ANSIBLE_VAULT_PASSWORD_FILE=/ansible-support/vault_key"
  hypoport/ansible:12.1.0 ansible-playbook --help
```
