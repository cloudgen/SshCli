**file**: docs/requirements/requirement-python-readme.md
**Status**: Active (Version 1.0.0)
**Area**: python
**Key**: `requirement-python-readme`
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

The root README is the user document for SshCli 2.0.0. It is not the agent map.

### 1.1 Human-facing

**In one sentence:** The README tells a person how to install `sshd-cli` with pip and how to open the menu.

## 2. Core Rules (Mandatory)

1. Sections, in order: title and badges, opening, Features, Advantages, Quick Installation, Usage (including a text picture of the menu with `HH:MM:SS`), Screenshots, Examples, Platform Compatibility, Related Projects, Contributing, License, Last Update.
2. The version badge says 2.0.0. The last update is 2026-10-22. The repository link is `https://github.com/cloudgen/SshCli`.
3. Installation is `python -m pip`. There is no `curl | sh`, no `setup.sh`, and no `sudo` pip.
4. The text picture shows rows 1, 2, 3, 4, 5, 8, and 9. It does not show shell rows 6 and 7.
5. Pictures under `screenshots/` are the 1.35.1 shell boards. The README says that, and it does not present them as the Python menu.
6. The README does not name a host SSH vault, a live Host alias, or a LAN address.
7. Harness inventories stay in `AGENTS.md` and `docs/`. They are not copied into the README.

## 3. Acceptance

- Root `README.md` contains those sections and the clock token `HH:MM:SS`.
