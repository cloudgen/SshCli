**file**: docs/requirements/requirement-python-cli-interface.md
**Status**: Active (Version 1.0.0)
**Area**: python
**Key**: `requirement-python-cli-interface`
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

One console script, `sshd-cli`, dispatches HelloTui verbs and the OpenSSH verbs. The menu is the empty-argument path on a terminal.

### 1.1 Human-facing

**In one sentence:** You type `sshd-cli`, or `sshd-cli` plus a verb such as `status` or `hello`. With no terminal and no verb, you get help and the program stops.

## 2. Core Rules (Mandatory)

1. Verbs include `help`, `version`, `about`, `hello`, `self-install`, `version-check`, `self-update`, `self-uninstall`, the domain verbs in `requirement-domain-sshd` §1.0, plus `menu` and `main`.
2. `language` is not a verb. A language is chosen on the menu.
3. Empty argv on a TTY opens the menu and does not run pip. Empty argv off a TTY prints help and returns 0.
4. `--json` or `--quiet` with no verb prints help, returns 0, and does not open the menu and does not install the package.
5. `--debug` alone on a TTY opens the menu. The logger is quiet while that screen is open.
6. `--purpose` with no text returns 1 and prints `[ERROR]` on stderr.
7. An unknown verb prints `ERROR: Unknown verb '<token>'.` and a Next line, and returns 1. That sentence stays even when `--json` is set.
8. Domain failures use `[ERROR]` / `[WARN]` / `[INFO]` / `[OK]`. With `--json`, a domain failure is one stderr JSON object `type` `out_error`, `code` `unknown`, and no human `[ERROR]` line. A domain success with `--json` is one stdout JSON object and no human line.
9. `--force` belongs only to `self-uninstall`.
10. `menu` and `main` open the menu on a TTY. Off a TTY they return 1 and name `sshd-cli status` as the next step.
11. There is no `curl | sh` installer and no `sudo` pip.

## 3. Acceptance

- `tests/test_hello.py` and `tests/test_domain.py` cover hello, unknown verbs, empty non-TTY help, `--json`, `--quiet`, `--debug`, and `--purpose`.
