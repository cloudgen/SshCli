**file**: docs/requirements/requirement-python-oop.md
**Status**: Active (Version 1.0.0)
**Area**: python
**Key**: `requirement-python-oop`
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

Each screen job and each OpenSSH job has a class. `def main` stays next to class `Cli`.

### 1.1 Human-facing

**In one sentence:** The menu, the language, the log, about, pip, and OpenSSH are separate classes. The command line calls them. It does not reimplement them.

## 2. Core Rules (Mandatory)

1. `Cli` parses and dispatches. `Tui` owns the screen session. `MenuPainter` owns the frame and the row tables. `MenuModel` owns keystrokes. `MenuSession` runs until Exit. `MenuLanguage` owns the codes. `SystemLog` owns log files. `SelfManage` owns pip. `AboutPage` and `CheckSystem` own the about page.
2. `Domain` is the one object the CLI and the menu call for OpenSSH work. It holds `Host`, `FixConfig`, `Dns`, `Transfer`, `Server`, `Sudoers`, `Backup`, and `RcPath`.
3. `Output` is the domain printer. HelloTui unknown-verb text stays on `Cli.report_error`.
4. A class that needs the logger receives it. Modules do not construct ChronicleLogger except `def main`.

## 3. Acceptance

- The classes above exist under `src/SshCli/`. `tests/test_about.py` checks that the host check is not copied into `cli.py`.
