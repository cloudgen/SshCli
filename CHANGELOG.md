# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- README pictures of the numbered boards, captured from the 1.35.1 ship unit on a terminal. Translated front boards keep **5** sudoers, **6** self-management, and **7** language.

## [1.35.1] - 2026-10-16

### Fixed

- **MSYS gzip stdin.** When the process that reads a `download` or `upload` gzip is MSYS2 or Git Bash, the ship unit finishes the archive, checks it with `gzip -t`, copies the file with `scp`, extracts that file, then removes the archive. A short sleep is not the repair. Failure names gzip or tar. Windows cmd, macOS, Debian (including Ubuntu), Fedora and Red Hat, Termux, BusyBox, Alpine, and other Linux keep the streamed pipe. `Windows_NT` alone keeps the pipe. **TP-UL-01** .. **TP-UL-18** stay the non-MSYS pipe (fake `ssh`). **TP-OS-GB-01** .. **TP-OS-GB-04** and **TP-OS-CMD-01** cover the split. Law: `requirement-shell-windows-git-bash-cli-coding` **1.2.0** · `requirement-shell-windows-cmd-cli-coding` **1.0.1** · `requirement-domain-sshd` **1.27.6** · `requirement-shell-cli-interface` **1.14.16** · `requirement-shell-cli-language` **1.7.2**.

### Added

- **OS CLI coding homes** (recorded while the product was **1.35.0**, released with this note). Windows cmd, Alpine, BusyBox, and other POSIX Linux each have a shell requirement. Windows cmd keeps the streamed pipe. `Windows_NT` alone is not the MSYS ban. Alpine keeps the pipe and does not add an `apk` wrap. BusyBox keeps `busybox APPLET` and the pipe. Other Linux keeps the pipe and does not invent a package tool. Law: `requirement-shell-alpine-cli-coding` **1.0.0** · `requirement-shell-busybox-cli-coding` **1.0.0** · `requirement-shell-other-linux-cli-coding` **1.0.0** · `requirement-class-software-dev` **1.0.7** · `requirement-shell-script-coding` **1.1.5** · `requirement-shell-debian-cli-coding` **1.0.1** · `requirement-shell-fedora-redhat-cli-coding` **1.0.1** · `requirement-shell-macos-cli-coding` **1.0.1** · `requirement-shell-termux-cli-coding` **1.0.1**.

## [1.35.0] - 2026-10-14

### Added

- **CLI coding homes.** Fedora / Red Hat, Debian / Ubuntu, macOS, Termux, and Windows Git Bash each have a shell requirement. `sshd_fix_os_class` stays `alpine`, `termux`, or `posix`. No `dnf`, `apt`, or `brew` wrap. Law: `requirement-shell-fedora-redhat-cli-coding` **1.0.0** · `requirement-shell-debian-cli-coding` **1.0.0** · `requirement-shell-macos-cli-coding` **1.0.0** · `requirement-shell-termux-cli-coding` **1.0.0** · `requirement-shell-windows-git-bash-cli-coding` **1.0.0** · `requirement-class-software-dev` **1.0.6** · `requirement-shell-script-coding` **1.1.4** · `requirement-shell-termux-ish` **1.2.1**.

### Fixed

- **Missing sshd next step.** POSIX Linux names `dnf` (Fedora and RHEL) and `apt` (Debian and Ubuntu) in one sentence and says this program does not run that command. Git Bash, Windows cmd, and macOS each get their own next step. Termux still points at `sshd-cli install`. Test **TP-SSHD-17**. Law: `requirement-shell-exit-condition` **1.0.1**. Samples follow `VERSION` **1.35.0** (`requirement-shell-cli-language` **1.7.1**, `requirement-shell-cli-interface` **1.14.14**).

## [1.34.0] - 2026-10-14

### Changed

- **Front board numbers.** **5** sudoers (children **51–55**). On Termux / Git Bash / Windows cmd that row stays off the list and the menu still prints `[INFO] sudoers not available for termux` (or `gitbash` / `windows-cmd`) before the numbers. **6** self-management (children **61–67**). **7** language. Language rows **70–89** stay the block (not more than 20). Assigned **71** English (`en`) through **83** Greek (`el`), same order as 1.32.0. **70** and **84–89** stay unprinted. Front **8** is not a row. Tests **TP-CLI-14** · **TP-CLI-21** · **TP-CLI-22** · **TP-CLI-24** · **TP-SSHD-04** · **TP-CFG-04** · **TP-CFG-05** · **TP-CFG-09** · **TP-CFG-17**. Law: `requirement-shell-cli-default-interaction` **1.18.0** · `requirement-shell-cli-language` **1.7.0** · `requirement-shell-cli-interface` **1.14.13** · `requirement-domain-sshd` **1.27.4** · `requirement-shell-self-management` **1.1.3** · `requirement-shell-cli-self-install` **1.1.2** · `requirement-shell-config-backup` **1.0.3** · `requirement-sshd-config-backup` **1.1.3**.

## [1.33.0] - 2026-10-10

### Changed

- **Front board hide line.** On Termux / Git Bash / Windows cmd, row **7** sudoers stays off the numbered list. Before the numbers the menu prints `[INFO] sudoers not available for termux` (or `gitbash` / `windows-cmd`). The same sentence follows the saved menu language. POSIX Linux still numbers **7**. Tests **TP-SSHD-04** · **TP-CFG-04** · **TP-CFG-05** · **TP-CFG-09**. Law: `requirement-shell-cli-default-interaction` **1.17.0** · `requirement-shell-cli-language` **1.6.0** · `requirement-shell-cli-interface` **1.14.11** · `requirement-domain-sshd` **1.27.3**.

## [1.32.0] - 2026-10-02

### Changed

- **Menu languages.** Front **5** stays Language. Front **6** stays unused. Rows **50–69** stay the language block (not more than 20). Assigned order: **51** English (`en`), **52** Simplified Chinese (`zh-Hans`), **53** Traditional Chinese (`zh-Hant`), **54** Spanish (`es`), **55** Arabic (`ar`), **56** French (`fr`), **57** Portuguese (`pt`), **58** Russian (`ru`), **59** German (`de`), **60** Japanese (`ja`), **61** Korean (`ko`), **62** Dutch (`nl`), **63** Greek (`el`). **50** and **64–69** stay reserved and are not printed. Human `help` and `about` follow the saved code. Tests **TP-CLI-24**. Law: `requirement-shell-cli-default-interaction` **1.16.0** · `requirement-shell-cli-language` **1.5.0** · `requirement-shell-cli-interface` **1.14.10** · `requirement-domain-sshd` **1.27.2** · `requirement-shell-cli-storage` **1.3.4**.

## [1.31.0] - 2026-10-02

### Changed

- **Menu language number.** Front **5** Language replaces front **6**. Language rows are reserved **50–69** (not more than 20 languages). Assigned: **51** English (`en`), **52** Traditional Chinese (`zh-Hant`), **53** Spanish (`es`), **54** French (`fr`), **55** German (`de`), **56** Simplified Chinese (`zh-Hans`), **57** Japanese (`ja`), **58** Korean (`ko`). **50** and **59–69** stay reserved and are not printed. Front **6** is not a row. Tests **TP-CLI-24**. Law: `requirement-shell-cli-default-interaction` **1.15.0** · `requirement-shell-cli-language` **1.4.0** · `requirement-shell-cli-interface` **1.14.9** · `requirement-domain-sshd` **1.27.1**.

## [1.30.0] - 2026-09-30

### Added

- **`fix-config`.** Comments OpenSSH client keywords this OS does not support. Alpine comments an active `GSSAPI*` line (`Unsupported option "gssapiauthentication"` when the line stays active). Termux comments an active `HostKeyAlgorithms`, `PubkeyAcceptedAlgorithms`, or `PubkeyAcceptedKeyTypes` line. Another OS leaves those keywords active. Optional `--input-file` and `--output-file` follow the verb. Every run applies the same pass to `~/.ssh/config` and stays quiet when nothing else was asked to print. `dns` add, set, delete, and unset use the same comment rule. `ssh`, `download`, and `upload` do not pass `-o GSSAPIAuthentication`. Tests **TP-FIX-01..14** · **TP-DNS-52**. Law: `requirement-domain-sshd` **1.27.0** · `requirement-shell-cli-interface` **1.14.8** · `requirement-shell-cli-language` **1.3.1**.

## [1.29.0] - 2026-09-28

### Added

- **Menu language.** Front **6** Language offers **61** English (`en`), **62** Traditional Chinese (`zh-Hant`), **63** Spanish (`es`), **64** French (`fr`), **65** German (`de`), **66** Simplified Chinese (`zh-Hans`), **67** Japanese (`ja`), and **68** Korean (`ko`). The choice is saved in `~/.local/sshd-cli/language` (mode 0600). Default stays English. `SSHD_CLI_LANG` set to an accepted code wins for that run and does not write the file. Human `help` and `about` follow that language. The version one-liner and JSON about stay English. Command names stay the words you type. Tests **TP-CLI-24**. Law: `requirement-shell-cli-language` **1.2.0** · `requirement-shell-cli-default-interaction` **1.13.0** · `requirement-shell-cli-storage` **1.3.3** · `requirement-shell-cli-interface` **1.14.7** · `requirement-domain-sshd` **1.26.6**.

## [1.28.0] - 2026-09-28

### Changed

- **No command after switches.** On a terminal, `sshd-cli` with no command opens the numbered menu. `--debug` or `--force` with no command is the same line: the menu opens and the CLI is not placed. `--quiet` or `--json` with no command, and the same line with no terminal, places the CLI (`self-install`). A named command such as `sshd-cli --debug status` stays that command. Tests **TP-CLI-14** · **TP-CLI-23**. Law: `requirement-shell-cli-zero-arguments` · `requirement-shell-cli-default-interaction` · `requirement-shell-cli-self-install`.

## [1.27.0] - 2026-09-27

### Changed

- **Cache folder.** Each login and each process gets its own leaf. Linux (including Termux): `/dev/shm/cache/cache-${APP_NAME}-${login}-$$`, then `/tmp/cache/cache-${APP_NAME}-${login}-$$`, then `${HOME}/.cache/cache-${APP_NAME}-$$`. Git Bash: `/tmp/cache/cache-${APP_NAME}-${login}-$$`, then `${HOME}/AppData/Local/Temp/cache-${APP_NAME}-$$` (no 2nd fallback). Mac: `/tmp/cache/cache-${APP_NAME}-${login}-$$`, then `${HOME}/Library/Caches/cache-${APP_NAME}-$$`, then `${HOME}/cache/cache-${APP_NAME}-$$`. Skipping a tier prints no warning and no error. `about` prints **Cache folder used**, **preferred**, **1st fallback**, and **2nd fallback** when that host has one, plus **Persistence storage** `${HOME}/.local/${APP_NAME}`. On Termux the cache folder is scratch only. Law: `requirement-shell-cli-storage` **1.3.0**. Suite **TP-CLI-06** · **TP-CLI-12** · **TP-CLI-19** · **TP-CLI-20**.

## [1.26.0] - 2026-09-27

### Changed

- On Termux, `old-openssh yes` writes `HostKeyAlgorithms +ssh-rsa,ssh-dss` and `PubkeyAcceptedAlgorithms +ssh-rsa,ssh-dss` as **comments**. An active keyword makes the Termux OpenSSH client error. `dns show` still reports `old-openssh: yes` for those comments.
- Menu **12** / `ssh`, before it connects, reads that Host stanza. Commented `HostKeyAlgorithms` or `PubkeyAcceptedAlgorithms` adds `-o HostKeyAlgorithms=+ssh-rsa`. Active lines do not add that option. Tests **TP-DNS-50** · **TP-DNS-51** · **TP-SSH-10**.

## [1.25.0] - 2026-09-27

### Changed

- TTY **sudoers** moves from client **17** to the front board **7** (`grant and drafts for passwordless sudo`). POSIX Linux shows it; Termux / Git Bash / Windows cmd keep the row hidden. Choosing hidden **7** warns and reprints the front board.
- Sudoers verbs follow the new parent: **71** `generate-sudoer-request`, **72** `submit-sudoer-request`, **73** `print-sudoers`, **74** `print-sudoers-install-script`, **75** `remove-project-sudoers`. Typed verb names are unchanged. Client board keeps **15** `backup-config` and **16** `sync-config`. Tests **TP-CLI-14** · **TP-CFG-17** · **TP-SSHD-04**.

## [1.24.0] - 2026-09-17

### Added

- **`self-install`**: place this CLI only. When `$0` is the script (not `sh`/`bash`/`zsh`), copy it into cache as `sshd-cli-<random>`, mode **0700** (local) or **0755** (global), then move to bin — no download. TTY self-management **87**. Tests **TP-SI-01** .. **TP-SI-06**. Law: `requirement-shell-cli-self-install`.

### Changed

- Non-interactive empty argv (`curl | sh`, quiet, json) **self-installs the CLI** and does **not** run payload `install` (Termux `pkg` / start sshd). Payload stays `sshd-cli install`.
- Portable catalogs: **well-known-cli-verb** (`self-install` = CLI place; `install` = local place or payload) and **well-known-menu** (TTY **81** `install`, **87** `self-install`).

## [1.23.0] - 2026-09-17

### Changed

- Preferred scratch/cache leaf is **`/dev/shm/cache/${APP_NAME}-${USERNAME}`** (for example `/dev/shm/cache/sshd-cli-adm01`). `about` **Storage (effective)** no longer uses `/dev/shm/sshd-cli-<user>` (that looks like a ram-drive project folder). Parent `/dev/shm/cache` is created first (prefer mode 1777). Fallback chain is unchanged. Law: `requirement-shell-cli-storage` **1.2.0**. Tests **TP-CLI-12** · **TP-CLI-19** · **TP-CLI-20**.

## [1.22.0] - 2026-09-16

### Changed

- TTY numbered tree: after a **finished command** (self-update, about, status, dns, …) the **front board** (1 / 2 / 8 / 9) is shown again instead of the submenu that launched it. **0** Back and a wrong number stay on that layer. A typed command name on the front board also returns to the front board (does not exit). Tests **TP-CLI-22**.

## [1.21.0] - 2026-09-14

### Added

- **`upload [N|name] [folder]`**: tar.gz a **local** folder over ssh and extract it under the remote ssh user’s home (`tar xzf - -C "$HOME"`). TTY: Host pick, then **user [default]** (same as `ssh` / `download`), then numbered previous **local** folders or a typed path. Local `~/folder` expands against this login `HOME` for tar only; remote dest stays `"$HOME"`. Memory: `~/.local/sshd-cli/upload-folders` (mode 600), not the download file. TTY client row **14**. Tests **TP-UL-01** .. **TP-UL-18**.

## [1.20.1] - 2026-09-14

### Fixed

- TTY self-management **82 version** (and typed `version` on a numbered board) runs **about** diagnostics instead of reprinting the header version. Argv `sshd-cli version` and `--json version` stay a one-liner (`"type":"version"`). Tests **TP-CLI-21**. Incident **INC-20260914-001**.

## [1.20.0] - 2026-09-14

### Changed

- TTY main menu is a **tree**: front **1 client-side**, **2 server-side**, **8 self-management**, **9 Exit**. Client verbs **11…**, server **21…**, self-management **81…**. Every submenu **0** Back. Command numbers stay unique (child prefix = parent). Each row is **number** + **bold** short + *italic* long. Independent law: `requirement-shell-cli-default-interaction`. Tests **TP-CLI-14** · **TP-SSHD-03..05** · **TP-SSHD-16** · **TP-DNS-13** · **TP-DNS-20** · **TP-DNS-21** · **TP-DNS-47** · **TP-CFG-04** · **TP-CFG-05** · **TP-CFG-17**.

## [1.19.2] - 2026-09-13

### Changed

- TTY numbered menus **warn and show the same list again** when the choice is unknown or out of range (main menu, sudoers submenu, dns action menu, Host pick, unset extra-settings picker, download folder pick). A wrong number is no longer a crash. Exit / empty still leave that layer. Tests **TP-SSHD-05** · **TP-SSHD-16** · **TP-DNS-47** · **TP-DNS-48** · **TP-DNS-49** · **TP-CFG-17** · **TP-DL-17**.
- POSIX Linux TTY row **10** is `sudoers: grant and drafts for passwordless sudo` (dropped trailing `backup-config` from the label).

## [1.19.1] - 2026-09-12

### Fixed

- **`download`** accepts a remote **`~/folder`** (the ssh user’s home, not this login). Remote `tar` uses `"$HOME"/'folder'` so tilde expands. `~` alone and `~user/…` still fail closed. Tests **TP-DL-14** · **TP-DL-15** · **TP-DL-16**. Incident **INC-20260912-002**.

## [1.19.0] - 2026-09-12

### Added

- TTY **`download`**: after the numbered Host pick, prompt **user [default]** (same contract as **`ssh`**: Host `User` if set, else this login). Enter keeps the default; `""` omits `-l`. Then the remote folder prompt. Tests **TP-DL-10** · **TP-DL-11** · **TP-DL-12** · **TP-DL-13**.

### Fixed

- Invalid TTY download user `Next:` names `download`, not only `ssh`. Download ssh-fail `Next:` includes `-l` when a user was chosen.

## [1.18.0] - 2026-09-12

### Added

- TTY main menu numbers **`ssh` (6)** and **`download` (7)** so interactive empty argv can open a Host without typing the verb. Termux / Git Bash / Windows cmd: **`sync-from-remote` is 8**, Exit **9**. POSIX Linux: backup-config **8**, sync-config **9**, sudoers **10**, Exit **99**.
- TTY **`ssh`**: after the numbered Host pick, prompt **user [default]** (Host `User` if set, else this login). Enter keeps the default; `""` omits `-l`. Tests **TP-SSH-08** · **TP-SSH-09**.

## [1.17.0] - 2026-09-12

### Added

- **`ssh [N|name]`**: pick a concrete Host from this login `~/.ssh/config` and run the OpenSSH client with that alias (User / Port / keys from the stanza apply). TTY lists Hosts; `--json` prints the alias and does not start a session.
- **`download [N|name] [folder]`**: pick a Host, then a remote folder. If this Host has previous folders, they appear as a numbered list; type a number or a new path. Remote `tar.gz` over ssh, extract into the current directory. Remembers paths per Host in `~/.local/sshd-cli/download-folders` (mode 600). Tests **TP-SSH-01..07** · **TP-DL-01..09** (fake `SSHD_CLI_SSH`; no real SSH).

## [1.16.0] - 2026-09-12

### Added

- **`dns unset <n|name> field …`**: drop extra settings on a `~/.ssh/config` Host (user, port, identity-file, identities-only, termux, old-openssh) without deleting the Host name or HostName. Example: `sshd-cli dns unset win user` omits the `User` line and keeps `Host win` / `HostName`. TTY action menu row **4 Unset**. `clear` is an unlisted alias. Tests **TP-DNS-39..46**.

## [1.15.0] - 2026-09-11

### Added

- **`sync-from-remote [SPEC]`**: Type 0 `scp` of a remote `/var/sshd-cli/config` into this login `~/.ssh/config` (mode 600). SPEC is `user@host`, host, IPv4, or `user@domain`. Last successful SPEC is stored as `${HOME}/.local/sshd-cli/preferred-remote` (mode 600) and used as the TTY default. Available on Termux / Git Bash / Windows cmd (menu row 6). Tests **TP-CFG-10..16**. Fake `SSHD_CLI_SCP` in CI (no real SSH).

## [1.14.0] - 2026-09-11

### Added

- **`backup-config`** copies this login `~/.ssh/config` into `/var/sshd-cli/config` (`sudo -n /usr/local/bin/sshd-cli backup-config` when dest needs root). **`sync-config`** copies that store back to `~/.ssh/config` as this login, mode **600**, no sudo.
- Sudoers workflow: `print-sudoers`, `print-sudoers-install-script`, `generate-sudoer-request`, `submit-sudoer-request`, `remove-project-sudoers`. Grant is **`sshd-cli backup-config` only** (NOPASSWD). JSON body + fragment dual.
- TTY menu on Termux / Git Bash / Windows cmd prints `[INFO] backup-config and sync-config not available for …` **before** the numbered list and omits those rows. POSIX Linux numbers them 6 / 7 / 8 (sudoers).
- Tests **TP-CFG-01..09**. Law: `requirement-sshd-config-backup`, `requirement-sudoer-json-file`, `requirement-three-layer-privilege-model`, `requirement-shell-sudo-command`.

## [1.13.4] - 2026-09-11

### Fixed

- **Git Bash storage:** `/dev/shm` mkdir is fail-soft. When that child cannot be created, the resolver uses `$HOME/AppData/Local/Temp/cache/${APP_NAME}-${USERNAME}` (else `/c/Users/${USERNAME}/AppData/Local/Temp/cache/…`) with no extra `[ERROR]`. Die only if every root fails. Incident **INC-20260911-001**. Tests **TP-CLI-19** · **TP-CLI-20**.

## [1.13.3] - 2026-09-10

### Added

- Windows companion **`setup-windows-ssh-server.ps1`** (Git Bash launcher **`setup-windows-ssh-server.sh`**): OpenSSH Server for a **normal (non-admin) user**. SSH session shell: Git Bash / Windows PowerShell / pwsh / cmd. `-User`, `-Shell`, `-PublicKeyFile`, `-SkipPause`. Git Bash is found via the Git for Windows registry (`bin\bash.exe`, not mintty).
- README: Git Bash detect is `MSYSTEM` or `uname` MINGW/MSYS (not `$0=/bin/bash`, not `[ -d /c/ ]`). Native Windows consoles from Git Bash use **winpty** (`winpty grok`). `HOME` looking like `/c/…` is typical after detect.

## [1.13.2] - 2026-09-09

### Fixed

- **dns tests mint Host names and IPv4 per run** (`t_rand_host` / `t_rand_ip`). Suite source no longer freezes this-login aliases or LAN addresses (**PP-A-26** / **PP-C-21**; term `synthetic-test-fixture`). Incident **INC-20260909-003**. Tests **TP-DNS-37** (last Host delete) · **TP-DNS-38** (no IPv4 literals in suite source).

## [1.13.1] - 2026-09-09

### Fixed

- **`self-update` is CLI-only:** after a successful binary place it no longer auto-starts OpenSSH sshd or runs `sshd -t` on `/etc/ssh/sshd_config`. A missing `/run/sshd` (or any host sshd config test failure) no longer turns a completed CLI update into `[ERROR]`. Use `sshd-cli start` when you want the daemon.
- POSIX Linux **`install`** still best-effort starts sshd, but **MUST NOT** `out_die` the CLI install if `sshd -t` / `/run/sshd` / unit start fails (warn instead). Does not rewrite `/etc/ssh/sshd_config`. Incident **INC-20260909-002**. Test **TP-SSHD-15**.

## [1.13.0] - 2026-09-09

### Added

- Type 0 **`rc-test`**: prove PATH / profile ensure in `--root` tmp (`--file bashrc|profile --case create|modify|noop`). Help lists it under **Tests (local folder; not install)**. Product law: `requirement-shell-path-and-shell-support`.
- Tests **TP-LC-27** (sibling PATH), **TP-LC-28** (uninstall keeps shared PATH), **TP-LC-29** (heal missing PATH), **TP-LC-30** (uninstall keeps `.profile`), **TP-LC-31** (`rc-test`), **TP-CLI-18** (help testers heading).
- Incident **INC-20260909-001** (path-ensure without `rc-test`; uninstall `sed` too wide).

### Changed

- Uninstall strips only `# Added by sshd-cli installer` comments; shared PATH line only if `USER_BIN` is empty.
- `path_add_bashrc` may add this product’s comment when a sibling already wrote the exact PATH line (no second export).
- `path_ensure_profile` honors `PROFILE`; zsh/fish honor `ZSHRC` / `FISH_CONFIG` and the exact PATH line.

### Fixed

- Claiming PATH ensure without a routed tester (**PP-A-24**). Uninstall matching any installer comment (**PP-A-25**).

## [1.12.0] - 2026-09-09

### Added

- TTY / `termux yes` **as Termux** Host bundle now writes simpler **Ciphers** `aes128-ctr,aes256-ctr` and **MACs** `hmac-sha2-256` (with Port **8022** and keep-alives). Some Termux OpenSSH `sshd` versions reply too slowly; the client then aborts with **Bad packet length** / **Connection corrupted**.
- `dns show` treats a keep-alive-only stanza (no those Ciphers/MACs) as **termux: no**. `set termux no` strips Ciphers/MACs with the keep-alives.
- Tests **TP-DNS-36**. Terms **termux-openssh** · **ssh-connection-corrupt**.

### Changed

- TTY **as Termux** info line names the simpler ciphers and the slow-sshd corrupt-session reason.

## [1.11.0] - 2026-09-09

### Added

- `BASHRC` env: `install` PATH ensure writes that file (default `~/.bashrc`). Tests/CI can point it at a file in a random temp folder.
- Tests **TP-LC-20** (create if missing), **TP-LC-21** (modify a dongle `.bashrc` in that folder), **TP-LC-22** (no-op when VERSION comments and the exact `export PATH=` line already match). Help Environment lists `BASHRC`.
- Law/proof molds require those three bashrc PATH-ensure cases whenever the feature is claimed (`LM-PATH-AND-SHELL-SUPPORT`, `LM-SELF-MANAGEMENT`, `LM-IDEMPOTENCY`, `PM-INSTALL-LIFECYCLE-TEST-PLAN`).

### Changed

- `path_add_bashrc` treats the file as already good only when the exact `export PATH="<USER_BIN>:$PATH"` line is present (not merely a `USER_BIN` substring).

## [1.10.0] - 2026-09-08

### Added

- POSIX Linux systemd unit path: when `ssh.service` or `sshd.service` is loaded, `start` / `stop` / `restart` call `systemctl` as a **root login**. `status` / `about` print the unit name and active state. Tests **TP-SSHD-09** .. **TP-SSHD-14**.

### Changed

- Help `start` row names the Linux `systemctl` path. There is still **no** routed `systemctl` / `enable-service` verb and **no** in-tool `sudo`. Termux is unchanged (`sshd -f`).

## [1.9.1] - 2026-09-08

### Fixed

- POSIX Linux `start` / `stop` / not-writable errors no longer name **Termux** as a next step. Next step is **re-run as root** (**INC-20260908-001**, **TP-SSHD-06**, **TP-SSHD-07**).
- POSIX Linux human `start` (including already-running) no longer says the observed pid is a session daemon or “not a systemd” service. It says this CLI does not **manage** systemd, and listen-after-reboot is the distro unit (**INC-20260908-002**, **TP-SSHD-08**).

## [1.9.0] - 2026-09-08

### Added

- On POSIX Linux (not Termux / Git Bash / Windows cmd), the TTY menu shows start / stop / restart (rows **2** / **3** / **4**) **only as root**. A non-root login gets `[INFO] start/stop/restart sshd features are not available for non-root in <OS-Name>` before the numbered list. `dns` stays row **5**. Tests **TP-SSHD-03** .. **TP-SSHD-05**.

### Changed

- Hidden numbers **2** / **3** / **4** are unknown choices. Typed `start` / `stop` / `restart` at the prompt still run the handlers (fail-closed without root; no in-tool `sudo`).

## [1.8.0] - 2026-09-08

### Added

- TTY `dns` add/edit asks **as Termux (Y/n)**. Yes writes Port **8022**, `ServerAliveInterval 15`, `ServerAliveCountMax 12`, `TCPKeepAlive yes`, `IPQoS none` and skips the Port prompt. No prompts **Port** as before.
- TTY walk always asks **identity-file** and **identities-only** (default `yes` when identity-file is set on add).
- TTY **Old OpenSSH (Y/n)**. Yes writes `HostKeyAlgorithms +ssh-rsa,ssh-dss` and `PubkeyAcceptedAlgorithms +ssh-rsa,ssh-dss`.
- Non-interactive operands: `termux yes|no`, `old-openssh yes|no`, `identity-file`, `identities-only`. Add without those operands does **not** write the bundles.
- Tests **TP-DNS-27** .. **TP-DNS-35**.

### Changed

- `dns show` prints identity-file, identities-only, termux, and old-openssh. Help `dns` row names the new fields.

## [1.7.0] - 2026-09-07

### Added

- On Termux, `start` (including already-running) acquires an **Android wake lock** (`termux-wake-lock`) so sshd can keep listening with the screen off. Missing helper warns and still starts sshd.
- `wake-lock` re-acquires the lock (idempotent). `wake-unlock` releases it (does **not** run on `stop` — the lock is Termux-wide). Off Termux both are a success no-op.
- Tests **TP-TX-08** .. **TP-TX-16**.

### Changed

- Termux-ish law records the wake-lock decision: auto-acquire **and** Type 0 verbs. Help lists `wake-lock` / `wake-unlock`.

## [1.6.0] - 2026-09-07

### Added

- TTY `dns` (main menu row 5) shows this login’s Host names, then an **action menu**: **1 Edit**, **2 Add**, **3 Delete**, **9 Exit**. Host pick is the next screen (`0` to leave).
- `dns delete N` / `dns rm N` removes that concrete Host stanza (backup + atomic replace). TTY confirms (y/N); `--force` or a non-interactive named command does not prompt. JSON is one success object.
- Tests **TP-DNS-21** .. **TP-DNS-26**.

### Changed

- TTY no longer treats the first number after the Host list as “update this row”. Action first, then pick.

### Fixed

- Missing Edit / Add / Delete step so operators could only update.

## [1.5.1] - 2026-09-07

### Fixed

- TTY main menu numbers `dns` as row **5** (`SSH names (dns): this login ~/.ssh/config Host list`). The Host list was already in 1.5.0 as `sshd-cli dns` / typing `dns` at the prompt, but the numbered list hid it so an update-and-open of `sshd-cli` looked unchanged.
- Choosing **5** runs the same TTY Host pick as `sshd-cli dns`. Leave that pick with `0` / empty (row 9 is a Host when the list is long). `port` / `config` / `host-keys` / `auth-keys` stay typed.

### Changed

- Domain menu rows are status, start, stop, restart, **dns**, then Exit 9. Test **TP-DNS-20**.

## [1.5.0] - 2026-09-07

### Added

- `dns` — this login’s `~/.ssh/config` as an SSH name/IP list. Numbered concrete `Host` rows; `show` details (`user` empty → `empty`, empty port → `22`); TTY field-by-field edit with current values as defaults; token `""` means empty.
- Non-interactive: `dns list`, `dns show N`, `dns set N ip … user "" port …`, `dns add dns NAME ip …`. `--json dns list` emits `@items`. `dns edit` off a terminal fails closed with Next: `dns set`.
- Tests **TP-DNS-01** .. **TP-DNS-19**.

### Changed

- Domain law includes this-login ssh_config Host management (not `/etc/hosts`, not `Host *`, not session mux).
- Interactive vs non-interactive matrix covers `dns` pick/walk vs list/set.

### Fixed

- TTY `dns` pick: `9` is Host row 9 when the list has nine or more entries. Leave with `0`, `q`, `exit`, or Enter.
- `dns add` inserts the new Host **before** a trailing `Host *` / `Match` (OpenSSH first-match), via atomic replace (not `>>`).
- `dns set` / `edit` keep extra Host aliases, parse `Key=value` and `Key = value`, and rewrite those keywords in `Key value` form.

## [1.4.2] - 2026-09-06

### Added

- Human `start` (and already-running no-op) explains that sshd is a **background daemon for this session**, not a boot service; after a reboot run `sshd-cli start`. Termux names Termux:Boot as an operator-owned `~/.termux/boot/` hook. POSIX Linux names the distro sshd unit.
- Tests **TP-SSHD-01** (launch is `sshd -f`, no service-manager verbs) and **TP-SSHD-02** (Termux stub start names the daemon / reboot hint).

### Changed

- `start` stays OpenSSH daemonize (`sshd -f`; no `-D`). Product law forbids systemd / `termux-services` / `sv-enable` / `add-crontab` / `enable-service` verbs.
- Help and menu `start` rows say **background daemon**, not a boot service.
- README Features / Examples / Platform Compatibility: daemon vs reboot; Termux:Boot is optional and operator-owned.

## [1.4.1] - 2026-09-06

### Added

- Named law `requirement-shell-termux-ish` (Termux `pkg` detect/invoke; Git Bash and Windows cmd are the same this-login-only class).
- Tests **TP-LC-18** / **TP-LC-19** (Git Bash / Windows cmd mock: `pkg` not invoked) and **TP-CSUM-01** (companion link on install).

### Changed

- Help heading is “Self-management (this login)” — not a Type 0 catalog line. `menu` help names the `main` alias.
- README and requirement leads use people language. POSIX Linux root install is the same one-liner **as root**; Termux / Git Bash / Windows cmd are not told to use `sudo curl | sh`.
- Coverage maps (`reviews/test-plan.md`, `what-to-review.md`, RTM) match live tests: this product **has** an online channel; empty argv is TTY menu / non-TTY install-ensure.

### Fixed

- Idempotency practice no longer treats a second bare `sshd-cli` on a terminal as “already installed” (that path is the menu).
- Ghost citations removed (`requirement-bootstrap-chain`, `tests/test_install_lifecycle.sh`, `TP-INST-MAYBE-01`).

## [1.4.0] - 2026-09-05

### Added

- `install` (and non-interactive empty-argv ensure) **starts sshd** when it finishes. Termux fail-closed if `sshd` is still missing. POSIX Linux warns and still succeeds the CLI install when system sshd needs root.

### Fixed

- `status` Connect line used a `<this-host>` placeholder. It now reads **`ifconfig wlan0`** inet (then other ifaces). No placeholder host.

## [1.3.1] - 2026-09-05

### Fixed

- `status` Connect line used a `<this-host>` placeholder when `ip -4 -o` failed on Termux. It now reads the inet address from **`ifconfig wlan0`** (then other ifaces). No placeholder host in the ship unit.

## [1.3.0] - 2026-09-05

### Changed

- Terminal menu rows are **status**, **start**, **stop**, **restart**, then **Exit 9**. `port` / `config` / `host-keys` / `auth-keys` stay typed commands.
- `status` (and start) print a recommended connect line `ssh -p <port> <user>@<lan-ipv4>` from live `id -un` and a non-loopback IPv4.

## [1.2.0] - 2026-09-05

### Changed

- Empty argv on a **terminal** opens the numbered domain **menu** (same as `sshd-cli menu`).
- Empty argv **non-interactive** (`curl | sh`, quiet, json, no TTY) still **install-ensure**.

## [1.1.0] - 2026-09-05

### Added

- **`install` companion (always, including already-installed CLI):** create `~/.bashrc` if missing and add `USER_BIN` to PATH; create `~/.profile` if missing so a login shell sources `~/.bashrc` (never overwrite an existing `.profile` body).
- **Termux:** `install` runs `pkg install -y openssh termux-auth`. POSIX Linux does not wrap `apt`.
- Tests **TP-LC-11..16** for login rc and Termux `pkg` (mocked).

### Changed

- Help `install` row names login rc and Termux packages.
- Domain law no longer lists wrapping Termux `pkg` as a non-goal.

## [1.0.0] - 2026-09-05

### Added

- First specialized product **sshd-cli**, bootstrapped from origin **selfmanaged** 1.2.3 (A → B only).
- **Purpose:** simplify Termux to install OpenSSH sshd.
- Self-install / self-update / self-uninstall / about / help (architecture inheritance).
- Domain commands: `status`, `start`, `stop`, `restart`, `port`, `config`, `host-keys`, `auth-keys`, `menu`.
- Termux-first path resolve (`PREFIX`); Linux system sshd fails closed without a root login (no in-tool sudo).
- Product law: `requirement-class-software-dev`, shell lifecycle REQs, `requirement-shell-script-coding`, `requirement-domain-sshd`.
- GitHub home: `cloudgen/sshd-cli`.

### Notes

- Bootstrap origin **selfmanaged** is frozen as architecture reference. Do not reverse-copy this tree onto A.
