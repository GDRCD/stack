# Agent instructions

## Documentation

The canonical user documentation is maintained in Italian in the GDRCD website
repository:

- published documentation: https://docs.gdrcd.org/stack/panoramica
- source chapter: https://github.com/GDRCD/gdrcd.org/tree/main/apps/docs/docs/it/stack

Keep this repository's `README.md` limited to requirements, quick start, basic
usage, and links. Document user-facing behavior in the Stack chapter above and
keep `CHANGELOG.md` in English. Follow Keep a Changelog: use its standard
categories, keep pending changes under `Unreleased`, and add release dates and
comparison links when publishing a version. Apply these rules to the current
entry without rewriting historical releases.

## Validation

Run the isolated test suite with `make test`. Keep all shell code compatible
with Bash 3.2 and validate command metadata with `./stack __validate-specs`.
