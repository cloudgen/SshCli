# Review report — shell to Python TUI

**Date:** 2026-10-22  
**Product:** SshCli 2.0.0  
**Console script:** `sshd-cli`  
**Verdict:** Pass  
**Suite:** PASS=37 FAIL=0 SKIP=0 (`./tests/run.sh`, Python unittest, this workspace)

## Question

Convert the `/bin/sh` product to Python by bootstrapping from HelloTui, keep every HelloTui screen behavior, and carry every sshd-cli feature onto that menu.

## What was reviewed

- Package `src/SshCli/`, launcher `./sshd-cli`, `pyproject.toml` version 2.0.0.
- Menu numbers: front 1 client-side, 2 server-side, 3 system-log, 4 language, 5 sudoers, 8 self-management, 9 Exit. Children 31–33, 41–53, 82–87, 11–16, 18, 21–24, 51–55, 111–114.
- Typed `hello` still prints `Welcome to SshCli 2.0.0.` and does not draw the menu.
- Hide sentences for Termux, Git Bash, Windows cmd, and non-root POSIX.
- `fix-config` Alpine and Termux comment rules, dns unset limits, MSYS finished-file plan versus pipe, sudoers grant limited to `backup-config`, non-root start without sudo, `rc-test` does not invent `.zshrc`.
- Requirements index: Active Python rows and Retired shell rows. Domain 1.28.0 section 1.0. README, CHANGELOG, test plan, and this report.

## Evidence

`PYTHONPATH=src python3 -m unittest discover -s tests -v` reported `Ran 37 tests` and `OK`.

## Limits

- The legacy shell suite under `tests/legacy-shell/` was not re-run. Its last recorded result remains PASS=1142 on product 1.35.1.
- No live Windows, Termux, or Git Bash host was probed. Those classes were selected with `SSHD_CLI_HOST`.
- Start and wake used `/bin/true` as the stand-in binary. The suite did not signal a live sshd.
- Screenshots in `screenshots/` are still the 1.35.1 shell boards. The README says so and shows the 2.0.0 menu as text.

## Follow-up

None required for this conversion. A later capture can replace the historical PNGs when someone runs the Python menu on a terminal.
