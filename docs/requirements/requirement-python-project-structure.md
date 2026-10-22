**file**: docs/requirements/requirement-python-project-structure.md
**Status**: Active (Version 1.0.0)
**Area**: python
**Key**: `requirement-python-project-structure`
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

The Python package, the tests, and the retired shell program each have one place.

### 1.1 Human-facing

**In one sentence:** The program you run lives in `src/SshCli`. The old shell program is under `legacy/`. Tests are Python.

## 2. Core Rules (Mandatory)

1. Import package: `src/SshCli/`. Domain modules: `src/SshCli/domain/`.
2. Checkout launcher: `./sshd-cli`. It is Python.
3. Live tests: `tests/test_*.py` and `tests/run.sh`. `tests/run.sh` sets `PYTHONPATH=src` and runs `python3 -m unittest discover -s tests`.
4. Retired shell tests and the 1.35.1 script live under `tests/legacy-shell/` and `legacy/`. The live runner does not execute them.
5. `docs/` stays the agent knowledge base and is not imported by the package.

## 3. Acceptance

- `tests/run.sh` discovers the Python tests and does not call the legacy shell suite.
