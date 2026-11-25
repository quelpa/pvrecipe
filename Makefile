EMACS ?= emacs

.PHONY: all test clean

all: test

test:
	$(EMACS) -Q -batch -L . -l test/pvrecipe-test.el -f ert-run-tests-batch-and-exit

# Clean up any compiled byte-code files
clean:
	rm -f *.elc test/*.elc
