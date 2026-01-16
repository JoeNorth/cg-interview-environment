terraform_context='terraform'
module='-'
candidate=''
branch=main
shell_command=''
shell_simple_command=''
glob='-'

.PHONY: shell
shell:
	bash hack/shell.sh $(candidate)

.PHONY: ide
ide:
	bash hack/shell.sh $(candidate) ide

.PHONY: delete-environment
delete-environment:
	bash hack/shell.sh $(candidate) delete-environment

.PHONY: deploy-ide
deploy-ide:
	bash hack/deploy-ide-cfn.sh $(candidate) $(branch)

.PHONY: destroy-ide
destroy-ide:
	bash hack/destroy-ide-cfn.sh $(candidate) $(branch)