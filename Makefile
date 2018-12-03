prefix := $(HOME)/.local

.PHONY: default
default:
	./symbol make with=mlton

.PHONY: install
install:
	./symbol install prefix=$(prefix)

shell_files := $(shell find . -type f -name '*.sh')

.PHONY: lint
lint:
	shellcheck --version
	shellcheck $(shell_files)

.PHONY: test
test:
	./run-tests.sh

.PHONY: clean
clean:
	rm -rf .symbol-work

