terraform_context='terraform'
module='-'
environment=''
shell_command=''
shell_simple_command=''
glob='-'

.PHONY: shell
shell:
	bash hack/shell.sh $(environment)

.PHONY: ide
ide:
	bash hack/shell.sh $(environment) ide

.PHONY: delete-environment
delete-environment:
	bash hack/shell.sh $(environment) delete-environment

.PHONY: deploy-ide
deploy-ide:
	bash hack/deploy-ide-cfn.sh $(environment)

.PHONY: destroy-ide
destroy-ide:
	bash hack/destroy-ide-cfn.sh $(environment)