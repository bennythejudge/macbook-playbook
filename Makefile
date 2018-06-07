LOCAL_PROJECT_DIRECTORY         := $(shell pwd)
ANSIBLE_DIRECTORY               := .
ANSIBLE_PLAYBOOKS_DIRECTORY     := $(ANSIBLE_DIRECTORY)
ANSIBLE_ROLES_DIRECTORY         := $(ANSIBLE_DIRECTORY)/roles
ANSIBLE_INVENTORY               := $(ANSIBLE_DIRECTORY)/hosts
ANSIBLE_VERBOSE                 := -vv
ANSIBLE_VAULT_PASSWORD_FILE     := $(ANSIBLE_DIRECTORY)/.ansible_vault_password
ANSIBLE_SENSITIVE_CONTENT_FILES := \
  $(ANSIBLE_ROLES_DIRECTORY)/ssh-keys/files/id_rsa \
  $(ANSIBLE_ROLES_DIRECTORY)/ssh-keys/files/id_rsa.pub \
  $(ANSIBLE_ROLES_DIRECTORY)/s3cmd/files/.s3cfg \
  $(ANSIBLE_ROLES_DIRECTORY)/dotfiles/vars/environment.yml \
  $(ANSIBLE_ROLES_DIRECTORY)/prey/vars/api_key.yml \
  $(ANSIBLE_ROLES_DIRECTORY)/aws-credentials/files/.aws/credentials \
  $(ANSIBLE_ROLES_DIRECTORY)/aws-credentials/files/.aws/config


ANSIBLE_COMMAND := \
	ansible-playbook $(ANSIBLE_VERBOSE) \
		-i $(ANSIBLE_INVENTORY) \
		--extra-vars "local_project_directory=$(LOCAL_PROJECT_DIRECTORY)"

ANSIBLE_COMMAND_LOCAL := \
	ansible-playbook $(ANSIBLE_VERBOSE) \
		-i $(ANSIBLE_INVENTORY) \
		--extra-vars "local_project_directory=$(LOCAL_PROJECT_DIRECTORY)"

ANSIBLE_COMMAND_LOCAL_WITH_VAULT := \
	$(ANSIBLE_COMMAND_LOCAL) --vault-password-file $(ANSIBLE_VAULT_PASSWORD_FILE)

VAULT_COMMAND := \
	ansible-vault --vault-password-file $(ANSIBLE_VAULT_PASSWORD_FILE)

.PHONY: \
	upgrade_pip \
	upgrade_ansible \
	bootstrap \
	converge \
	encrypt \
	decrypt \
	encrypt_pre_commit

upgrade_pip:
	@sudo pip install --upgrade pip

# https://github.com/pypa/pip/issues/3165#issuecomment-146666737
upgrade_ansible:
	@sudo -H pip install --upgrade ansible --ignore-installed six

bootstrap:
	@xcode-select --install
	@sudo xcodebuild -license
	@sudo easy_install pip
	@sudo pip install ansible
	@$(ANSIBLE_COMMAND_LOCAL_WITH_VAULT) $(ANSIBLE_PLAYBOOKS_DIRECTORY)/bootstrap.yml
	@test -s $(ANSIBLE_VAULT_PASSWORD_FILE) \
		|| echo ATTENTION: Please create '$(PWD)/$(ANSIBLE_VAULT_PASSWORD_FILE)' with this project\'s Ansible Vault password

converge:
	@$(ANSIBLE_COMMAND_LOCAL_WITH_VAULT) $(ANSIBLE_PLAYBOOKS_DIRECTORY)/main.yml

encrypt:
	@$(VAULT_COMMAND) encrypt $(ANSIBLE_SENSITIVE_CONTENT_FILES)

decrypt:
	@$(VAULT_COMMAND) decrypt $(ANSIBLE_SENSITIVE_CONTENT_FILES)

encrypt_pre_commit: encrypt
	@git add $(ANSIBLE_SENSITIVE_CONTENT_FILES)

list-secrets:
	echo ${ANSIBLE_SENSITIVE_CONTENT_FILES} | xargs -n 1 ls

show-secrets:
	echo ${ANSIBLE_SENSITIVE_CONTENT_FILES} | xargs -n 1 create
