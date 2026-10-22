**file**: docs/requirements/requirement-python-coding-style.md
**Status**: Active (Version 1.0.0)
**Area**: python
**Key**: `requirement-python-coding-style`
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

Python in this tree stays readable, fails closed, and does not hide a shell coding rule inside a comment.

### 1.1 Human-facing

**In one sentence:** The program checks the inputs it can check, says what to type next when something is wrong, and does not wrap an administrator command for you.

## 2. Core Rules (Mandatory)

1. Product source comments cite live `requirement-*.md` keys. They do not cite a skill or a template as the behavior.
2. Domain errors name a next command. They do not exit the process from a nested menu; the menu shows the result and returns to the board.
3. Temp files for `fix-config` use `tempfile.mkstemp` in the destination directory and `os.replace`.
4. Do not call `sudo`, `apt`, `dnf`, `brew`, or `apk`. Termux OpenSSH install is the one `pkg` invocation, and only when the login is Termux.
5. Tests mint Host names and addresses. They do not copy this login's Host aliases or LAN addresses.
6. A test that would start or stop sshd sets `SSHD_CLI_SSHD` or `SSHD_CLI_PID` so it does not signal a live daemon.

## 3. Acceptance

- `tests/test_domain.py` uses minted names (`lab-a`, `203.0.113.10`) and fake binaries (`/bin/true`) for start and wake.
