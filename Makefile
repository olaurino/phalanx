.PHONY: help
help:
	@echo "Make targets for Phalanx:"
	@echo "make clean - Remove generated files"
	@echo "make init - Set up dev environment (install pre-commit hooks)"
	@echo "make linkcheck - Check for broken links in documentation"
	@echo "make update - Update pinned dependencies and run make init"
	@echo "make update-deps - Update pinned dependencies"
	@echo "make update-deps-no-hashes - Pin dependencies without hashes"

.PHONY: clean
clean:
	rm -rf .mypy_cache .ruff_cache .tox docs/_build
	make -C docs clean

.PHONY: init
init:
	pip install --upgrade pip pre-commit tox
	pre-commit install
	pip install --editable .
	pip install --upgrade -r requirements/main.txt -r requirements/dev.txt
	rm -rf .tox

# This is defined as a Makefile target instead of only a tox command because
# if the command fails we want to cat output.txt, which contains the
# actually useful linkcheck output. tox unfortunately doesn't support this
# level of shell trickery after failed commands.
.PHONY: linkcheck
linkcheck:
	rm -rf docs/internals/api/
	sphinx-build --keep-going -n -T -b linkcheck docs	\
	    docs/_build/linkcheck				\
	    || (cat docs/_build/linkcheck/output.txt; exit 1)

.PHONY: update
update: update-deps init

.PHONY: update-deps
update-deps:
	pip install --upgrade pip-tools pip setuptools
	pip-compile --upgrade --resolver=backtracking --build-isolation \
	    --generate-hashes --allow-unsafe				\
	    --output-file requirements/main.txt requirements/main.in
	pip-compile --upgrade --resolver=backtracking --build-isolation \
	    --generate-hashes --allow-unsafe				\
	    --output-file requirements/dev.txt requirements/dev.in

# Useful for testing against a Git version of Safir.
.PHONY: update-deps-no-hashes
update-deps-no-hashes:
	pip install --upgrade pip-tools pip setuptools
	pip-compile --upgrade --resolver=backtracking --build-isolation \
	    --allow-unsafe						\
	    --output-file requirements/main.txt requirements/main.in
	pip-compile --upgrade --resolver=backtracking --build-isolation \
	    --allow-unsafe						\
	    --output-file requirements/dev.txt requirements/dev.in
