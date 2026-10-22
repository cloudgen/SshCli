# Tests — SshCli

The live suite is Python. Product version **2.0.0**. The console script remains `sshd-cli`.

## Run

```sh
./tests/run.sh
```

The runner sets `PYTHONPATH` to `src` and runs `python3 -m unittest discover -s tests -v`. Exit **0** when every test passes.

`tests/legacy-shell/` is the `/bin/sh` suite for product **1.35.1**. `tests/run.sh` does not execute it.

## Layout

| File | Focus | TP families |
|------|--------|-------------|
| `run.sh` | Python unittest discover | — |
| `test_about.py` | About page and CheckSystem | **TP-ABOUT-01..16** |
| `test_hello.py` | Typed `hello` prints the welcome line and does not draw the menu. Typing `hello` on the menu shows that line. Removed video verbs stay unknown | **TP-HELLO** |
| `test_language.py` | Row 4, codes 41–53, leaf mode 0600, `SSHCLI_LANG` over `VIDEOJOIN_LANG` | **TP-LANG-01** |
| `test_tui.py` | Path label, clock line, wide-column colon | **TP-TUI-09** · **TP-TUI-10** |
| `test_domain.py` | Menu hide sentences, fix-config, dns, transfer plan, sudoers grant, server refuse, `rc-test`, empty-argv and `--json` gates | **TP-MENU-HIDE** · **TP-FIX** · **TP-DNS** · **TP-XFER** · **TP-SUDO** · **TP-SRV** · **TP-RC** · **TP-CLI-GATE** |

## Isolation

- Domain tests set `HOME` to a temporary directory before `Cli.run`, so automatic `fix-config` does not rewrite this login’s `~/.ssh/config`.
- Host names and addresses in tests are minted (`lab-a`, `ada`, `alice`, `203.0.113.10`). They are not this login’s Host aliases.
- Start and stop tests set `SSHD_CLI_SSHD` or `SSHD_CLI_PID`. `server.stop` calls `os.kill` when a pidfile exists and `SSHD_CLI_SSHD` is unset.
- `SSHD_CLI_SSH` plans download and upload. It does not run the real client.
- No public network. Nothing is installed into `/etc`.

## Ship unit under test

`src/SshCli` and the launcher `./sshd-cli`.

## Maps

Product TP map: `reviews/test-plan.md`  
RTM: `reviews/requirement-test-matrix.md`
