
# All immediate subdirectories inside /packages
SUBDIRS := $(wildcard */)
MAKE_SUBDIRS := $(foreach dir,$(SUBDIRS),$(if $(wildcard $(dir)Makefile),$(dir)))
MOVE_SUBDIRS := $(foreach dir,$(SUBDIRS),$(if $(wildcard $(dir)Move.toml),$(dir)))


.PHONY: setup-hooks lint-git

setup-hooks:
	@cd .git/hooks; ln -s -f ../../contrib/git-hooks/* ./
	@bun install -g prettier @mysten/prettier-plugin-move

.git/hooks/pre-commit: setup


# used as pre-commit
lint-git:
	@git diff --name-only --cached --diff-filter=ACM | grep  -E '\.md$$' | xargs -r markdownlint-cli2

# add license header to every source file
add-license:
	@awk -i inplace 'FNR==1 && !/SPDX-License-Identifier/ {print "// SPDX-License-Identifier: MPL-2.0\n"}1' **/sources/*.move **/tests/*.move
# with reuse tool:
# docker run --rm --volume $(pwd):/data fsfe/reuse annotate --license MPL-2.0  */tests/*.move */sources/*.move  -s cpp

.PHONY: add-license


############

print-packages:
	@for p in $(MAKE_SUBDIRS); do \
		echo $$p; done

format-move-all:
	@bun run format:move-all

test-move-all:
	bash ./contrib/run-move-tests.sh test

build-move-all:
	bash ./contrib/run-move-tests.sh build

publish-all:
	@bun run scripts/publish.ts

.PHONY: print-packages format-move build-all test-all publish-all
