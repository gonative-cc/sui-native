
# used as pre-commit
lint-git:
	@git diff --name-only --cached | grep  -E '\.md$$' | xargs -r markdownlint-cli2
	@sui move build --lint
# note: prettier-move is run in the hook directly

# lint changed files
lint:
	@git diff --name-only | grep  -E '\.md$$' | xargs -r markdownlint-cli2
	@sui move build --lint

lint-all:
	@markdownlint-cli2 **.md
	@sui move build --lint

lint-fix-all:
	@markdownlint-cli2 --fix **.md
	@echo "Sui move lint will be fixed by manual"
	@bun run format:move-all


.PHONY: setup lint-git lint lint-all lint-fix-all


# add license header to every source file
add-license:
	@awk -i inplace 'FNR==1 && !/SPDX-License-Identifier/ {print "// SPDX-License-Identifier: MPL-2.0\n"}1' sources/*.move tests/*.move
.PHONY: add-license


###############################################################################
##                              Build & Test                                 ##
###############################################################################

build: .git/hooks/pre-commit
	@sui move build

test:
	@sui move test

test-coverage:
	echo TODO
# sui move test --coverage
# sui move coverage

.PHONY: test test-coverage

###############################################################################
##                                   Docs                                    ##
###############################################################################
# Variables for build output and module name
BUILD_DIR := build
PACKAGE_NAME := $(notdir $(CURDIR))
gen-docs:
	@sui move build --doc
	@cp -r ./$(BUILD_DIR)/$(PACKAGE_NAME)/docs/$(PACKAGE_NAME)/* ./docs

.PHONY: gen-docs

###############################################################################
##                                Infrastructure                             ##
###############################################################################

# To setup bitcoin, use Native Relayer.
