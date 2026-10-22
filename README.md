# SshCli — OpenSSH sshd and this login's SSH client, on a text menu

![Version](https://img.shields.io/badge/Version-2.0.0-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)
[![CIAO](https://img.shields.io/badge/Philosophy-CIAO%20(Caution%20%E2%80%A2%20Intentional%20%E2%80%A2%20Anti--fragile%20%E2%80%A2%20Over--engineered)-purple.svg)](https://github.com/cloudgen/ciao)
[![Stars](https://img.shields.io/github/stars/cloudgen/SshCli?style=flat-square)](https://github.com/cloudgen/SshCli)
[![Python](https://img.shields.io/badge/Python-3-blue?style=flat-square)]()
[![PyPI](https://img.shields.io/pypi/v/SshCli?style=flat-square)](https://pypi.org/project/SshCli/)

SshCli is the Python program behind the `sshd-cli` command. On a terminal, starting it with no arguments opens a text menu. The menu runs OpenSSH `sshd` on this machine and the OpenSSH client for this login (`~/.ssh/config`, `ssh`, and folder copy).

The typed verb `hello` prints one welcome line and does not draw the menu. The menu itself does not print that line until you type `hello`.

This tree is **2.0.0**. The last `/bin/sh` release is **1.35.1** and lives in `legacy/` for reference. Install and update go through `python -m pip`.

## Features

- Text menu on a terminal. The first row is the current folder and a local clock (`HH:MM:SS`) when the row has room
- Numbered rows line up in display columns. Wide characters count as two. A rounded input box sits along the bottom
- **client-side** (1): dns, ssh, download, upload. On POSIX Linux also backup-config and sync-config. On Termux, Git Bash, and Windows cmd, those two stay off the list and sync-from-remote (18) is shown
- **server-side** (2): status. start, stop, and restart when this login may run the daemon (Termux, Git Bash, Windows cmd, or POSIX root)
- **system-log** (3): view-log (31), clear-log (32), log-folder (33)
- **language** (4): thirteen languages, numbers 41–53, saved for the next run
- **sudoers** (5): a draft that allows only `backup-config`, numbers 51–55. Hidden on Termux, Git Bash, and Windows cmd
- **self-management** (8): version (82), about (83), and pip rows 84–87
- **Exit** (9)
- Typed verbs for the same work, plus `hello`, `fix-config`, `port`, `config`, `host-keys`, `auth-keys`, `wake-lock`, `wake-unlock`, `install` (Termux OpenSSH packages), and `rc-test`
- `fix-config` comments OpenSSH client keywords this OS does not support, and every run does that quietly for `~/.ssh/config`
- Download and upload of a folder as tar.gz. An MSYS or Git Bash reader uses a finished file. Other readers keep the pipe

## Advantages

1. **Menu or command.** `sshd-cli` on a terminal opens the menu and does not call pip. With no terminal and no verb, it prints help and returns 0. `sshd-cli hello` prints `Welcome to SshCli 2.0.0.` and does not draw the menu. `sshd-cli status` reports sshd without opening the menu.
2. **The HelloTui screen stays.** Path line, clock `HH:MM:SS`, display columns, the input box, Esc, and the language, log, and pip boards keep their numbers (3, 4, 8, 9 and the children under them).
3. **The login class is visible.** When sudoers, backup, or start/stop/restart cannot be offered, the menu prints an info line and omits those numbers. The typed command still refuses, and it does not wrap `sudo`.
4. **Lifecycle is pip.** `version-check`, `self-update`, `self-install`, and `self-uninstall` use `python -m pip`. `self-uninstall` on the command line needs `--force`. They do not use root.

## Quick Installation

**Python dependency:** `ChronicleLogger>=1.3.1` (required). Pip installs it with SshCli.

### PyPI (registry)

```bash
python -m pip install SshCli
```

This installs the console command **`sshd-cli`** and the package **`SshCli`**. The name in `pyproject.toml` is `SshCli`. This tree is **2.0.0**. The PyPI badge shows the index when that release is published.

### Local install (checkout)

```bash
git clone https://github.com/cloudgen/SshCli.git
cd SshCli
python3 -m venv venv
source venv/bin/activate
python -m pip install -e .
```

From this checkout, before that install, `./sshd-cli` runs the package in `src/`.

## Usage

On a terminal:

```text
sshd-cli
```

The English menu looks like this. The clock is local time in `HH:MM:SS`. `9` leaves. `0` on a submenu goes back. A number that is not on the list prints an error and lets you choose again.

```text
$ sshd-cli
Path: /tmp/work                                                        12:06:45

1. client-side     : this login OpenSSH client (~/.ssh/config, ssh, folders)
2. server-side     : this host OpenSSH sshd (listen, keys, port)
3. system-log      : view, clear, and the log folder
4. language        : display language for this menu
5. sudoers         : grant and drafts for passwordless sudo
8. self-management : version, about, and pip lifecycle
9. Exit            : leave

╭─────────────────────────────────────────────────────────────────────────────╮
│ >                                                                           │
╰─────────────────────────────────────────────────────────────────────────────╯
  SshCli 2.0.0  │  main menu  │  Up/Down  •  Enter
```

Row 5 is omitted on Termux, Git Bash, and Windows cmd. The menu then prints `sudoers not available for termux` (or `gitbash`, or `windows-cmd`) before the numbers.

**client-side** (1) on POSIX Linux:

```text
11. dns           : this login ~/.ssh/config Host list
12. ssh           : connect with a Host from that list
13. download      : tar.gz a remote folder into this directory
14. upload        : tar.gz a local folder onto that Host
15. backup-config : copy ~/.ssh/config to the project store
16. sync-config   : copy the project store back to ~/.ssh/config
 0. Back          : return to the main menu
```

**server-side** (2) when start, stop, and restart are available:

```text
21. status  : show whether sshd is listening
22. start   : start sshd for this login
23. stop    : stop sshd for this login
24. restart : stop sshd, then start it
 0. Back    : return to the main menu
```

**self-management** (8):

```text
82. version         : show the installed version
83. about           : version and this computer
84. version-check   : compare this install with pip
85. self-update     : upgrade this package with pip
86. self-uninstall  : remove this package with pip
87. self-install    : install this package with pip
 0. Back            : return to the main menu
```

Help, without opening the menu:

```bash
sshd-cli help
sshd-cli hello
sshd-cli status
sshd-cli --json status
```

`--json` prints one JSON object and no human line. `--json` or `--quiet` with no verb prints help and returns 0.

## Screenshots

The PNG files in `screenshots/` were captured from the **1.35.1** `/bin/sh` program. That menu numbered self-management as 6 and language as 7. The Python menu uses 8 and 4 for those boards. Use the text pictures above for 2.0.0.

Historical boards, same binary with a different detector, not photos of those machines:

- [POSIX front](https://raw.githubusercontent.com/cloudgen/SshCli/main/screenshots/front-posix.png)
- [Termux front](https://raw.githubusercontent.com/cloudgen/SshCli/main/screenshots/front-termux.png)
- [Git Bash front](https://raw.githubusercontent.com/cloudgen/SshCli/main/screenshots/front-git-bash.png)
- [Windows cmd front](https://raw.githubusercontent.com/cloudgen/SshCli/main/screenshots/front-windows-cmd.png)
- [Client](https://raw.githubusercontent.com/cloudgen/SshCli/main/screenshots/client.png)
- [Server](https://raw.githubusercontent.com/cloudgen/SshCli/main/screenshots/server.png)
- [Sudoers](https://raw.githubusercontent.com/cloudgen/SshCli/main/screenshots/sudoers.png)
- [Language](https://raw.githubusercontent.com/cloudgen/SshCli/main/screenshots/language.png)
- [Self-management](https://raw.githubusercontent.com/cloudgen/SshCli/main/screenshots/self-management.png)

Translated fronts from that same capture: `front-zh-Hans.png`, `front-zh-Hant.png`, `front-ja.png`, `front-ko.png`, `front-es.png`, `front-fr.png`, `front-pt.png`, `front-de.png`, `front-ru.png`, `front-ar.png`, `front-nl.png`, `front-el.png`.

## Examples

Welcome line, no menu:

```bash
sshd-cli hello
```

```text
Welcome to SshCli 2.0.0.
```

Add a Host in this login's `~/.ssh/config`, then connect. The name and address here are examples, not a machine on your network:

```bash
sshd-cli dns add dns lab-a ip 203.0.113.10 user alice
sshd-cli ssh lab-a
```

Comment keywords this OS does not support:

```bash
sshd-cli fix-config --input-file ./client-config --output-file ./client-config
```

Remove this package:

```bash
sshd-cli self-uninstall --force
```

## Platform Compatibility

| Login | Menu notes |
|-------|------------|
| POSIX Linux, root | sudoers, backup-config, sync-config, and start/stop/restart. A systemd unit is started with `systemctl` |
| POSIX Linux, not root | sudoers and backup stay. start/stop/restart stay off the server board. The typed commands refuse and do not wrap `sudo` |
| Termux | No sudoers and no backup-config. sync-from-remote is on the client board. `sshd-cli install` may run `pkg install -y openssh termux-auth`. start also takes a wake lock |
| Git Bash | Same row hiding as Termux. A gzip reader on this kind of host uses a finished archive and `scp` |
| Windows cmd | Same row hiding as Termux. `Windows_NT` alone keeps the streamed pipe |
| Cygwin | Not treated as Git Bash and not treated as Windows cmd |

macOS, Debian (including Ubuntu), Fedora and Red Hat, Alpine, BusyBox, and other Linux keep the streamed pipe for download and upload. Alpine comments active `GSSAPI*` client keywords. Termux comments active host-key and public-key algorithm keywords.

## Related Projects

- [OpenSSH](https://www.openssh.com/) — the client and the sshd this program runs
- [ChronicleLogger](https://pypi.org/project/ChronicleLogger/) — the required log package
- [CIAO](https://github.com/cloudgen/ciao) — the defensive style this project follows
- [SshCli](https://github.com/cloudgen/SshCli) — this repository. The command is `sshd-cli`

## Contributing

```bash
./tests/run.sh
```

The runner discovers Python tests under `tests/`. The old shell tests under `tests/legacy-shell/` are not that runner. Use a temporary home and minted Host names in new tests.

## License

MIT. See [LICENSE.md](LICENSE.md).

## Last Update

2026-10-22 — Python 2.0.0. The public repository is https://github.com/cloudgen/SshCli. The text menu keeps the HelloTui screen and carries the sshd-cli boards. The `/bin/sh` program remains available as `legacy/sshd-cli.sh` at 1.35.1.
