
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


###############################################################################
##                              Build & Test                                 ##
###############################################################################

build:
	@sui move build

test:
	@sui move test

test-coverage:
	echo TODO
# sui move test --coverage
# sui move coverage

.PHONY: build test test-coverage

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
