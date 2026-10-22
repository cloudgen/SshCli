**file**: docs/requirements/requirement-python-error-handling.md
**Status**: Active (Version 1.0.0)
**Area**: python
**Key**: `requirement-python-error-handling`
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

Failures are visible. A bad menu number does not end the program. A bad verb does.

### 1.1 Human-facing

**In one sentence:** A wrong word on the command line prints `ERROR:` and stops. A wrong number on the menu prints a sentence and lets you pick again. A domain problem prints `[ERROR]` and a next step.

## 2. Core Rules (Mandatory)

1. Unknown verb: stderr `ERROR: Unknown verb '<token>'.` plus `Next:`, status 1. This stays the HelloTui sentence under `--json`.
2. Domain `Output.error`: status 1. Human mode is stderr `[ERROR]`. JSON mode is stderr `{"type":"out_error","message":"...","code":"unknown"}` and no `[ERROR]`.
3. `[WARN]` is stderr and is not hidden by `--quiet`. `[INFO]` and `[OK]` are stdout and are hidden by `--quiet` and by `--json`.
4. A missing Host, a bad folder (empty, NUL, or starting with `-`), a missing upload directory, and `dns unset` of `dns` or `ip` are errors.
5. Non-root POSIX start, stop, and restart are errors and do not invoke `sudo`.
6. `--purpose` with no text is status 1 and `[ERROR]` before domain work.
7. Exit row 9 and a finished menu return 0. A menu that cannot open returns 1 after `ERROR:`.

## 3. Acceptance

- `tests/test_domain.py` covers the JSON error, the purpose flag, the unknown verb, unset of dns and ip, the non-root start refusal, and the bad folder.
