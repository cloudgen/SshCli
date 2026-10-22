#!/bin/sh
# SshCli test runner. The live suite is Python. The shell suites under
# tests/legacy-shell are the previous /bin/sh ship unit and are not this runner.
set -eu
ROOT="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
export PYTHONPATH="${ROOT}/src${PYTHONPATH:+:$PYTHONPATH}"
python3 -m unittest discover -s tests -v
