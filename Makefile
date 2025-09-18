setup-hooks:
	@cd .git/hooks; ln -s -f ../../contrib/git-hooks/* ./
	@pnpm install -g prettier @mysten/prettier-plugin-move

# add license header to every source file
add-license:
	@awk -i inplace 'FNR==1 && !/SPDX-License-Identifier/ {print "// SPDX-License-Identifier: MPL-2.0\n"}1' */sources/*.move */tests/*.move
# with reuse tool:
# docker run --rm --volume $(pwd):/data fsfe/reuse annotate --license MPL-2.0  */tests/*.move */sources/*.move  -s cpp


# used as pre-commit
lint-git:
	@git diff --name-only --cached --diff-filter=ACM | grep  -E '\.md$$' | xargs -r markdownlint-cli2


############

# All immediate subdirectories
SUBDIRS := $(wildcard */)

# Filter subdirectories that contain a Move.toml file
MOVE_SUBDIRS := $(foreach dir,$(SUBDIRS),$(if $(wildcard $(dir)Move.toml),$(dir)))


build-all:
	@for dir in $(MOVE_SUBDIRS); do \
		echo "==> building $$dir"; cd $$dir; sui move build; \
	done


test-all:
	@for dir in $(MOVE_SUBDIRS); do \
		echo "==> testing $$dir"; sui move test; \
	done
