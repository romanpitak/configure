
.PHONY: test

tests/configure: src/configure.sh
	cp "$<" "$@"

test: tests/configure
	cd tests && ./test_variables.sh
