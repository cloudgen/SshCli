**file**: docs/requirements/requirement-python-about.md
**Status**: Active (Version 1.0.0)
**Area**: python
**Key**: `requirement-python-about`
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

`about` shows who this program is and what this computer is. The page is English.

### 1.1 Human-facing

**In one sentence:** `sshd-cli about` on a terminal opens the about page. The page names SshCli, the version, the author, and a check of this computer. It does not print JSON.

## 2. Core Rules (Mandatory)

1. Identity is SshCli, version 2.0.0, author Wilgat Wong, homepage `https://github.com/cloudgen/SshCli`, basic usage `sshd-cli status`, last update 2026-10-22.
2. The star box and the host check belong to `AboutPage` and `CheckSystem`. `cli.py` does not define the check methods.
3. The about page has no `--json` stream of its own.
4. Menu row 83 is about. The typed verb `about` opens the page on a terminal and prints the text off a terminal.
5. The page does not claim a media tool, FFmpeg, or a file list.

## 3. Acceptance

- `tests/test_about.py` (TP-ABOUT-01 through TP-ABOUT-16).
