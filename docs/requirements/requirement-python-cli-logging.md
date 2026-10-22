**file**: docs/requirements/requirement-python-cli-logging.md
**Status**: Active (Version 1.0.0)
**Area**: python
**Key**: `requirement-python-cli-logging`
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

ChronicleLogger is constructed in `def main` and passed into the program. The package does not construct it at import time.

### 1.1 Human-facing

**In one sentence:** The program writes its own log when ChronicleLogger is installed. Opening the text menu keeps that log quiet so the screen stays readable.

## 2. Core Rules (Mandatory)

1. `def main` contains the construct `ChronicleLogger(`. A missing install prints a next step: `python -m pip install "ChronicleLogger>=1.3.1"` and returns 1.
2. `is_quiet` is true when `Cli.opens_text_screen` is true. `--debug` alone on a terminal still opens the menu, so the logger is quiet for that run.
3. `--json` and `--quiet` do not open the screen, so they do not force the logger quiet by the screen rule.
4. The dependency floor is `ChronicleLogger>=1.3.1` in `pyproject.toml`.
5. Domain human lines and JSON are `Output`. They are not a second logger.

## 3. Acceptance

- `tests/test_about.py` reads `cli.py` and requires the ChronicleLogger construct, and requires that CheckSystem methods are not defined in `cli.py`.
