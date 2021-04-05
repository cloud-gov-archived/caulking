CAULKING_VERSION=1.2.0 2021-04-01
GITLEAKS_VERSION=7.2.1
NOW=$(shell date)
ME=$(shell whoami)

GIT_SUPPORT_PATH=  ${HOME}/.git-support
HOOKS=${GIT_SUPPORT_PATH}/hooks
PRECOMMIT=${GIT_SUPPORT_PATH}/hooks/pre-commit
PATTERNS=${GIT_SUPPORT_PATH}/gitleaks.toml
GITLEAKS= /usr/local/bin/gitleaks

INSTALL_TARGETS= ${PATTERNS} ${PRECOMMIT} ${GITLEAKS}

.PHONY: clean audit global_hooks

install: $(INSTALL_TARGETS) global_hooks

audit: /usr/local/bin/bats /usr/local/bin/pcregrep ${GITLEAKS} $(INSTALL_TARGETS)
	@test $$(gitleaks --version) =  ${GITLEAKS_VERSION} || make upgrade
	@echo ${CAULKING_VERSION}
	@echo "${ME} / ${NOW}"
	bats -p caulked.bats

clean:
	/bin/rm -rf ${GIT_SUPPORT_PATH}
	git config --global --unset hooks.gitleaks
	git config --global --unset core.hooksPath

clean_seekrets:
	/bin/rm -rf ${GIT_SUPPORT_PATH}/seekret-rules
	-git config --global --unset gitseekret.rulesenabled
	-git config --global --unset gitseekret.rulespath
	-git config --global --unset gitseekret.exceptionsfile
	-git config --global --unset gitseekret.version

hook pre-commit: ${GIT_SUPPORT_PATH}/hooks/pre-commit

global_hooks:
	git config --global hooks.gitleaks true
	git config --global core.hooksPath ${GIT_SUPPORT_PATH}/hooks

config patterns rules: ${GIT_SUPPORT_PATH}/gitleaks.toml

${PATTERNS}: local.toml ${GIT_SUPPORT_PATH}
	cat $< > $@

${PRECOMMIT}: pre-commit.sh ${HOOKS}
	install -m 0755 -cv $< $@

${GIT_SUPPORT_PATH} ${HOOKS}:
	mkdir -p $@ 

/usr/local/bin/bats:
	brew install bats-core

/usr/local/bin/pcregrep:
	brew install pcre

/usr/local/bin/%:
	brew install $(@F)

upgrade:
	@echo Simplify this code once we are all back to 7.2.1 or higher.
	brew rm gitleaks
	brew install gitleaks
	brew link gitleaks

FORCE:
