**file**: docs/requirements/requirement-runtime-prerequisites.md
**Status**: Active (Version 1.0.0)
**Area**: python
**Key**: `requirement-runtime-prerequisites`
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

Say what must already be on the machine before a menu or an OpenSSH verb can succeed.

### 1.1 Human-facing

**In one sentence:** You need Python 3, the ChronicleLogger package, and a terminal for the menu. OpenSSH itself comes from the operating system, except on Termux where `sshd-cli install` can ask `pkg` for it.

## 2. Core Rules (Mandatory)

1. Python 3 is the runtime used by `./sshd-cli` and `python3 -m unittest`. The text menu needs `curses`.
2. ChronicleLogger `>=1.3.1` is required at process start. Pip may install it with the package.
3. OpenSSH client and server binaries are external. This program does not vendor them and does not wrap `apt`, `dnf`, `brew`, or `apk`.
4. Termux may install `openssh` and `termux-auth` with `pkg` from the `install` verb only.
5. A POSIX root login with systemd may call `systemctl` for start, stop, and restart of the existing ssh unit. This program does not write a unit file.
6. The menu does not require a network. `version-check`, `self-update`, and `self-install` do, because they call pip.

## 3. Acceptance

- A missing ChronicleLogger import in `def main` returns 1 and names the pip install line.
- `tests/test_about.py` exercises the host check without requiring a live sshd.
