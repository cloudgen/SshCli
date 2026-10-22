**file**: docs/requirements/requirement-python-packaging.md
**Status**: Active (Version 1.0.0)
**Area**: python
**Key**: `requirement-python-packaging`
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

setuptools builds SshCli. The version string has one home.

### 1.1 Human-facing

**In one sentence:** `pip install` of this tree installs a command named `sshd-cli`. The package name is SshCli. The version in this tree is 2.0.0.

## 2. Core Rules (Mandatory)

1. `pyproject.toml` `[project].name` is `SshCli`. `version` is `2.0.0`. The same string is `src/SshCli/__init__.py` `__version__`.
2. The console script is `sshd-cli = SshCli.cli:main`.
3. The dependency is `ChronicleLogger>=1.3.1`. Requires-Python matches the HelloTui floor (`>=2.7`, excluding 3.0 through 3.4). The running code uses Python 3.
4. Homepage and repository are `https://github.com/cloudgen/SshCli`. Issues are `https://github.com/cloudgen/SshCli/issues`.
5. Author is Wilgat Wong, `wilgat.wong@gmail.com`. License is MIT.
6. The checkout launcher `./sshd-cli` inserts `src` on `sys.path` and calls `SshCli.cli.main`. It is not a copy of `legacy/sshd-cli.sh`.
7. Do not bump the version for a requirements-only edit. 2.0.0 is the Python generation. 1.35.1 remains the last `/bin/sh` version.

## 3. Acceptance

- `python3 -c "import SshCli; print(SshCli.__version__)"` with `PYTHONPATH=src` prints `2.0.0`.
- `./sshd-cli help` prints the console name `sshd-cli`.
