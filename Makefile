.PHONY: default
default:
	@echo "We're using Symbol to build this Standard ML project."
	@echo "Some available commands:"
	@echo ""
	@echo "  ./symbol make"
	@echo "  ./symbol make with=mlton"
	@echo "  ./symbol install"
	@echo ""
	@echo "You can learn more about Symbol here:"
	@echo "  https://github.com/jez/symbol"

shell_files := $(shell find . -type f -name '*.sh')

.PHONY: lint
lint:
	shellcheck --version
	shellcheck $(shell_files)

# There's no way to forward all `make` arguments to run-tests.sh
# to i.e. run a single test.
#
# When you want to do this, invoke `run-tests.sh` directly.
.PHONY: test
test:
	./run-tests.sh

.PHONY: clean
clean:
	rm -rf .symbol-work

