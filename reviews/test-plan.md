# Test plan — sshd-cli

Maps **TP-*** coverage to `tests/`.  
**Suite entry:** `./tests/run.sh`  
**Ship unit:** `src/sshd-cli`  
**Product VERSION:** 1.35.1  
**Last plan update:** 2026-10-16  
**Last suite run:** PASS=1142 FAIL=0 SKIP=0 (`./tests/run.sh`, 2026-10-16, product 1.35.1). **TP-OS-GB-01** .. **TP-OS-GB-04** and **TP-OS-CMD-01** passed. Prior run: PASS=1107 FAIL=0 SKIP=0 (`./tests/run.sh`, 2026-10-14, product 1.35.0). **TP-SSHD-17** passed: a missing sshd names `dnf` on Fedora and RHEL and `apt` on Debian and Ubuntu, and says this program does not run that command. Git Bash, Windows cmd, and macOS each have their own next step. Prior run: PASS=1100 FAIL=0 SKIP=0 (`./tests/run.sh`, 2026-10-14, product 1.34.0). **TP-CLI-14**, **TP-CLI-21**, **TP-CLI-24**, **TP-SSHD-04**, and **TP-CFG-04** / **05** / **09** / **17** passed: front **5** sudoers (**51–55**), **6** self-management (TTY **62** runs about), **7** language block **70–89** (assigned **71–83**); front **8** warns; Termux / Git Bash / Windows cmd omit row **5**. Prior run: PASS=1099 FAIL=0 SKIP=0 (`./tests/run.sh`, 2026-10-10, product 1.33.0). **TP-SSHD-04**, **TP-CFG-04**, **TP-CFG-05**, and **TP-CFG-09** passed: Termux / Git Bash / Windows cmd print `sudoers not available for termux` / `gitbash` / `windows-cmd` before the front numbers and omit row **7**. Prior run: PASS=1091 FAIL=0 SKIP=0 (`./tests/run.sh`, 2026-10-02, product 1.32.0). **TP-CLI-14** and **TP-CLI-24** passed: front **5** language, block **50–69** (assigned **51–63**); **50**, **64**, and **69** do not write the file; front **6** warns and does not open the language board. Earlier: PASS=1065 FAIL=0 SKIP=0 (`./tests/run.sh`, 2026-10-02, product 1.31.0), assigned **51–58**. Earlier: PASS=844 FAIL=22 SKIP=0 (`./tests/run.sh`, 2026-09-28, product 1.28.0). Those 22 were TP-DL-* `tar xzf` cases. The 1.31.0 run’s TP-DL-* cases passed.

Status: **have** = automated today · **todo** = needed · **optional** · **n/a** · **skip** (environment)

---

## Baseline coverage

| Area | Status | Evidence |
|------|--------|----------|
| Syntax `sh -n` | have | TP-CLI-01 |
| version / help / about human + JSON | have | TP-CLI-02..06 |
| Empty argv and switch-only: non-TTY CLI self-install / TTY menu | have | TP-CLI-07, TP-CLI-14, TP-CLI-22, TP-CLI-23, TP-SI-01..06, TP-SSHD-03..05, TP-SSHD-16 |
| Unknown + quiet + set -u HOME | have | TP-CLI-08..11 |
| Per-login per-process cache folder + persistence | have | TP-CLI-06, TP-CLI-12, TP-CLI-19, TP-CLI-20 |
| `backup-config` / `sync-config` / `sync-from-remote` / sudoers grant | have | TP-CFG-01..17 |
| Channel verbs routed (`self-update`, `version-check`); no public network in CI | have | TP-CLI-04, TP-CLI-10 |
| Trimmed parent verbs fail closed | have | TP-CLI-13 |
| Local install / idempotent / uninstall / mode 0755 / login rc / Termux pkg | have | TP-LC-01..19 |
| Android wake lock (auto on start + `wake-lock` verb) | have | TP-TX-08..16 |
| sshd start is a background daemon (not a service manager) | have | TP-SSHD-01, TP-SSHD-02 |
| POSIX Linux systemd unit path (`systemctl` start/stop/restart) | have | TP-SSHD-09..14 |
| this-login `~/.ssh/config` dns-ip list / show / set / add / delete / unset | have | TP-DNS-01..49 |
| OpenSSH client `ssh` Host pick | have | TP-SSH-01..09 |
| remote folder `download` tar.gz into cwd | have | TP-DL-01..17 |
| local folder `upload` tar.gz onto a Host | have | TP-UL-01..18 |
| Automatic companion link on install (file://) | have | TP-CSUM-01 |
| Backup / restore / sudoers emit | n/a | Absent by design (not a backup product) |
| Online curl against public GitHub | n/a | Core suite stays offline; channel is `file://` in CI |

This product **is** online-installable (`SCRIPT_URL`, `self-update`, `version-check`, companion `.sha256`). Core CI does **not** hit the public network.

---

## TP rows

### TP-CLI (CLI surface)

| TP-ID | Intent | Suite | Primary requirement(s) | Status |
|-------|--------|-------|------------------------|--------|
| TP-CLI-01 | `sh -n` ship unit | `tests/test_cli.sh` | requirement-shell-cli-interface | **have** |
| TP-CLI-02 | version human | test_cli | requirement-shell-cli-interface | **have** |
| TP-CLI-03 | version JSON | test_cli | requirement-shell-output-requirements | **have** |
| TP-CLI-04 | help lists this-login + domain verbs; no backup/restore/sudoers; no CHECKSUM | test_cli | requirement-shell-cli-interface · requirement-domain-sshd · requirement-shell-automatic-checksum | **have** |
| TP-CLI-18 | help lists `rc-test` under testers heading apart from operational verbs | test_cli | requirement-shell-cli-interface · requirement-shell-path-and-shell-support | **have** |
| TP-CLI-05 | help JSON short | test_cli | requirement-shell-output-requirements | **have** |
| TP-CLI-06 | about JSON cache_used / cache_preferred / cache_fallback / cache_fallback_2 / persistence_storage + `sshd_platform`; human Cache folder used, preferred, 1st, 2nd + Persistence storage; no CHECKSUM | test_cli | requirement-shell-cli-storage · requirement-domain-sshd | **have** |
| TP-CLI-07 | empty argv non-interactive CLI self-install | test_cli | requirement-shell-cli-zero-arguments · requirement-shell-cli-self-install · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-SI-01 | `self-install` copies from script `$0` (dead SCRIPT_URL) | test_cli | requirement-shell-cli-self-install | **have** |
| TP-SI-02 | local dest mode **0700** after self-install | test_cli | requirement-shell-cli-self-install | **have** |
| TP-SI-03 | NI empty argv is self-install (not payload banner) | test_cli | requirement-shell-cli-self-install · requirement-shell-cli-zero-arguments | **have** |
| TP-SI-04 | interpreter `$0` (`cat \| sh`) uses channel download | test_cli | requirement-shell-cli-self-install | **have** |
| TP-SI-05 | second `self-install` already-installed no-op | test_cli | requirement-shell-cli-self-install | **have** |
| TP-SI-06 | help lists `self-install` | test_cli | requirement-shell-cli-self-install · requirement-shell-cli-interface | **have** |
| TP-CLI-08 | unknown fail-closed | test_cli | requirement-shell-cli-interface | **have** |
| TP-CLI-09 | quiet suppresses version | test_cli | requirement-shell-output-requirements | **have** |
| TP-CLI-10 | `self-update` / `version-check` are **known** commands (no network) | test_cli | requirement-shell-cli-interface · requirement-shell-self-management | **have** |
| TP-CLI-11 | env -u HOME version | test_cli | class / requirement-shell-script-coding | **have** |
| TP-CLI-12 | Linux preferred `/dev/shm/cache/cache-${APP_NAME}-${login}-$$`; Git Bash and Mac chains and about lines; silent skip of preferred; leaf mode 0700; persistence `${HOME}/.local/${APP_NAME}`; live dir exists | test_cli | requirement-shell-cli-storage | **have** |
| TP-CLI-19 | Git Bash: `/tmp/cache` mkdir fail-soft → `${HOME}/AppData/Local/Temp/cache-${APP_NAME}-$$`; no cache ERROR | test_cli | requirement-shell-cli-storage | **have** |
| TP-CLI-20 | static: resolver names Git Bash Temp, shm cache, Mac Library/Caches; `util_cache_try_dir`; no mid-chain mkdir `out_die` | test_cli | requirement-shell-cli-storage · requirement-shell-script-coding | **have** |
| TP-CFG-01 | Type 0 `backup-config` into `SSHD_CLI_ROOT` | test_config_backup | requirement-shell-config-backup | **have** |
| TP-CFG-02 | `sync-config` dest mode 600 | test_config_backup | requirement-shell-config-backup | **have** |
| TP-CFG-03 | missing source fail-closed + Next | test_config_backup | requirement-shell-config-backup | **have** |
| TP-CFG-04 | Termux hide + INFO | test_config_backup | requirement-shell-config-backup · requirement-shell-sudoer | **have** |
| TP-CFG-05 | Git Bash hide + INFO | test_config_backup | requirement-shell-config-backup · requirement-shell-sudoer | **have** |
| TP-CFG-06 | `print-sudoers --allow-test-local` backup-config only | test_config_backup | requirement-shell-sudoer | **have** |
| TP-CFG-07 | `generate-sudoer-request` JSON grant | test_config_backup | requirement-shell-sudoer | **have** |
| TP-CFG-08 | `restore-config` unknown | test_config_backup | requirement-shell-config-backup | **have** |
| TP-CFG-09 | Windows cmd menu INFO | test_config_backup | requirement-shell-config-backup · requirement-shell-sudoer | **have** |
| TP-CFG-10 | `sync-from-remote` missing SPEC fail-closed | test_config_backup | requirement-shell-config-backup | **have** |
| TP-CFG-11 | invalid SPEC / extra `@` fail-closed | test_config_backup | requirement-shell-config-backup | **have** |
| TP-CFG-12 | fake scp `user@host` copies config | test_config_backup | requirement-shell-config-backup | **have** |
| TP-CFG-13 | dest mode 600 | test_config_backup | requirement-shell-config-backup | **have** |
| TP-CFG-14 | preferred-remote saved mode 600 | test_config_backup | requirement-shell-config-backup | **have** |
| TP-CFG-15 | TTY empty Enter uses stored default | test_config_backup | requirement-shell-config-backup | **have** |
| TP-CFG-16 | `--json` type/host fields | test_config_backup | requirement-shell-config-backup | **have** |
| TP-CFG-17 | TTY front **5** sudoers submenu unknown choice warns and redisplays; verbs **51–55** | test_config_backup | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-CLI-13 | backup/restore/sudoers verbs unknown | test_cli | requirement-shell-cli-interface | **have** |
| TP-CLI-14 | empty argv interactive → front 1/2/5/6/7/9 (sudoers **5**, self-management **6**, language **7**; no install); client 11 dns / 12 ssh / 13 download / 14 upload; no client **17** | test_cli | requirement-shell-cli-default-interaction · requirement-shell-cli-zero-arguments · requirement-domain-sshd | **have** |
| TP-CLI-23 | switch-only: TTY `--debug` / `--force` menu and no install; `--quiet` / `--json` / non-TTY `--debug` self-install; TTY `--json` places the CLI; `--debug status` stays status | test_cli | requirement-shell-cli-zero-arguments · requirement-shell-cli-default-interaction · requirement-shell-cli-self-install | **have** |
| TP-CLI-24 | Menu **7** language, block **70–89** (at most 20; **70** and **84–89** unprinted): **71** English, **72** Simplified Chinese, **73** Traditional Chinese, **74** Spanish, **75** Arabic, **76** French, **77** Portuguese, **78** Russian, **79** German, **80** Japanese, **81** Korean, **82** Dutch, **83** Greek, file `language` mode 600, unrecognized line stays English, `SSHD_CLI_LANG` overrides the file, Japanese and Korean `help` and `about` | test_cli | requirement-shell-cli-language · requirement-shell-cli-default-interaction · requirement-shell-cli-storage | **have** |
| TP-CLI-21 | TTY **62** / typed `version` run about; argv `version` stays thin JSON type | test_cli | requirement-shell-cli-default-interaction · requirement-shell-cli-interface · **INC-20260914-001** | **have** |
| TP-CLI-22 | Finished TTY leaf redisplays the **front board** (not the submenu); typed leaf on front stays on front | test_cli | requirement-shell-cli-default-interaction | **have** |
| TP-CLI-15 | status Connect: live ssh -p user@ipv4; no `<this-host>` | test_cli | requirement-domain-sshd | **have** |

### TP-SSHD (domain start: Termux daemonize / Linux systemd unit)

| TP-ID | Intent | Suite | Primary requirement(s) | Status |
|-------|--------|-------|------------------------|--------|
| TP-SSHD-01 | Start launch is `sshd -f`; help/dispatcher have no systemd / termux-services / sv-enable / add-crontab / enable-service | `tests/test_cli.sh` | requirement-domain-sshd · requirement-shell-cli-interface | **have** |
| TP-SSHD-02 | Termux stub install/start names background daemon, reboot re-start, Termux:Boot operator hook | `tests/test_local_lifecycle.sh` | requirement-domain-sshd | **have** |
| TP-SSHD-03 | POSIX Linux non-root TTY **server** submenu hides **22/23/24**; INFO names OS; status stays **21** | `tests/test_cli.sh` | requirement-shell-cli-default-interaction · requirement-domain-sshd | **have** |
| TP-SSHD-04 | Termux mock TTY server submenu still shows **22/23/24**; client **11** dns; no non-root INFO | `tests/test_cli.sh` | requirement-shell-cli-default-interaction · requirement-domain-sshd · requirement-shell-termux-ish | **have** |
| TP-SSHD-05 | POSIX Linux non-root: numbered **22** is unknown (does not start); warns and redisplays; **0** Back then **9** Exit | `tests/test_cli.sh` | requirement-shell-cli-default-interaction · requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-SSHD-06 | POSIX Linux non-root `stop` error names re-run as root; no Termux | `tests/test_cli.sh` | requirement-domain-sshd | **have** |
| TP-SSHD-07 | Ship-unit start/stop/writable die copy is host-local (no “use Termux”) | `tests/test_cli.sh` | requirement-domain-sshd | **have** |
| TP-SSHD-08 | POSIX Linux `start` already-running does not deny systemd / session-daemon | `tests/test_cli.sh` | requirement-domain-sshd | **have** |
| TP-SSHD-09 | systemd host detect: `/run/systemd/system` + `systemctl`; Termux class never true | `tests/test_cli.sh` | requirement-domain-sshd | **have** |
| TP-SSHD-10 | Unit name: `ssh.service` before `sshd.service`; skip LoadState not-found | `tests/test_cli.sh` | requirement-domain-sshd | **have** |
| TP-SSHD-11 | Source unit path invokes `systemctl start` | `tests/test_cli.sh` | requirement-domain-sshd | **have** |
| TP-SSHD-12 | Source unit path invokes `systemctl stop` / `restart` | `tests/test_cli.sh` | requirement-domain-sshd | **have** |
| TP-SSHD-13 | Termux mock `start` never invokes `systemctl` | `tests/test_cli.sh` | requirement-domain-sshd · requirement-shell-termux-ish | **have** |
| TP-SSHD-14 | Dispatcher has no routed verb `systemctl` / `enable-service` | `tests/test_cli.sh` | requirement-domain-sshd · requirement-shell-cli-interface | **have** |
| TP-SSHD-15 | `self-update --force` still exit 0 when stub `sshd -t` would fail; no sshd_config ERROR | `tests/test_local_lifecycle.sh` | requirement-domain-sshd · requirement-shell-self-management | **have** |
| TP-SSHD-16 | TTY unknown menu token warns and redisplays; then Exit | `tests/test_cli.sh` | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |

### TP-DNS (this login ~/.ssh/config Host list)

| TP-ID | Intent | Suite | Primary requirement(s) | Status |
|-------|--------|-------|------------------------|--------|
| TP-DNS-01 | help lists `dns` | `tests/test_dns.sh` | requirement-domain-sshd · requirement-shell-cli-interface | **have** |
| TP-DNS-02 | numbered list; `Host *` omitted | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-03 | show: user empty → `empty`; port set | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-04 | show by name; empty port displays 22 | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-05 | non-interactive `set` ip | test_dns | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-DNS-06 | `""` clears user; omit User line | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-07 | JSON list `@items` | test_dns | requirement-domain-sshd · requirement-shell-output-requirements | **have** |
| TP-DNS-08 | `edit` without TTY fail-closed Next `dns set` | test_dns | requirement-shell-interactive-vs-noninteractive | **have** |
| TP-DNS-09 | missing n fail-closed | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-10 | non-interactive `add` | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-11 | bare `dns` non-TTY lists (no hang) | test_dns | requirement-shell-interactive-vs-noninteractive | **have** |
| TP-DNS-12 | INTERACTIVE field walk; `""` clears ip | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-13 | action Edit then pick `9` is Host row 9 (not action Exit) | test_dns | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-DNS-14 | add inserts before trailing `Host *` | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-15 | extra Host aliases kept on set | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-16 | `Key=value` / `Key = value` parse; set does not corrupt User | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-17 | Match / Include skipped on list | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-18 | after `COMMAND=dns`, token `dns` is a field name | test_dns | requirement-domain-sshd · requirement-shell-cli-interface | **have** |
| TP-DNS-19 | add without dns name Next mentions add | test_dns | requirement-domain-sshd · requirement-shell-cli-interface | **have** |
| TP-DNS-20 | TTY menu row 5 opens Edit/Add/Delete/Unset action menu | test_dns | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-DNS-21 | TTY Edit then Host 1 | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-22 | non-interactive `delete`; `Host *` kept | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-23 | TTY delete cancel | test_dns | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-DNS-24 | TTY delete yes | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-25 | delete without n fail-closed | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-26 | JSON delete one object; other stanzas kept | test_dns | requirement-domain-sshd · requirement-shell-output-requirements | **have** |
| TP-DNS-27 | non-interactive `add termux yes` writes Port 8022 + keep-alive / IPQoS + Ciphers/MACs bundle | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-28 | `old-openssh yes` writes HostKeyAlgorithms / PubkeyAcceptedAlgorithms +ssh-rsa,ssh-dss | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-50 | Termux `old-openssh yes` writes those lines as comments; show stays yes | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-51 | Termux `old-openssh no` removes the commented algorithm lines | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-52 | posix dns set keeps active `GSSAPI*`; alpine dns set/add comments those lines and keeps other extra keys | test_dns | requirement-domain-sshd | **have** |
| TP-FIX-01 | help lists `fix-config` with `--input-file` and `--output-file` | test_fix_config | requirement-domain-sshd · requirement-shell-cli-interface | **have** |
| TP-FIX-02 | a flag before the verb is an unknown command | test_fix_config | requirement-domain-sshd · requirement-shell-cli-interface | **have** |
| TP-FIX-03 | alpine `--input-file` comments `GSSAPI*` in place; other keys stay; mode 600; one backup | test_fix_config | requirement-domain-sshd | **have** |
| TP-FIX-04 | second alpine pass is unchanged and adds no backup | test_fix_config | requirement-domain-sshd | **have** |
| TP-FIX-05 | both flags: input stays, output is the commented copy, one JSON object | test_fix_config | requirement-domain-sshd · requirement-shell-output-requirements | **have** |
| TP-FIX-06 | `--output-file` only: automatic pass comments `~/.ssh/config`, output matches, rolling backup | test_fix_config | requirement-domain-sshd | **have** |
| TP-FIX-07 | termux comments the three algorithm keywords and leaves `GSSAPI*` active | test_fix_config | requirement-domain-sshd | **have** |
| TP-FIX-08 | posix comments neither family | test_fix_config | requirement-domain-sshd | **have** |
| TP-FIX-09 | missing file, empty flag, and unknown operand fail closed | test_fix_config | requirement-domain-sshd · requirement-shell-cli-interface | **have** |
| TP-FIX-10 | `version` comments `~/.ssh/config` on alpine and prints no comment banner; second run does not rewrite | test_fix_config | requirement-domain-sshd | **have** |
| TP-FIX-11 | `--json version` stays one object while the file is commented | test_fix_config | requirement-domain-sshd · requirement-shell-output-requirements | **have** |
| TP-FIX-12 | `--quiet fix-config` comments and prints no human line | test_fix_config | requirement-domain-sshd · requirement-shell-output-requirements | **have** |
| TP-FIX-13 | termux review comments algorithm lines; `dns show` stays `old-openssh: yes` | test_fix_config | requirement-domain-sshd | **have** |
| TP-FIX-14 | suite source has no dotted IPv4 | test_fix_config | requirement-domain-sshd | **have** |
| TP-DNS-29 | `identity-file` + `identities-only` written and shown | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-30 | INTERACTIVE add default as Termux (Y) + Old OpenSSH (Y) | test_dns | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-DNS-31 | INTERACTIVE add Termux n prompts Port; Old OpenSSH n omits algorithms | test_dns | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-DNS-32 | `set termux no` strips keep-alives and Ciphers/MACs; Port kept | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-33 | `set old-openssh no` strips algorithm lines | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-34 | show names identity-file / termux / old-openssh | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-35 | unknown field fail-closed names identity-file / termux / old-openssh | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-36 | keep-alive-only stanza is termux no; `set termux yes` writes Ciphers/MACs | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-37 | last concrete Host delete; stanza gone; `Host *` kept | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-38 | suite source has no dotted IPv4 (minted Host/IP; **PP-C-21**) | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-39 | help lists `unset N field` | test_dns | requirement-domain-sshd · requirement-shell-cli-interface | **have** |
| TP-DNS-40 | non-interactive `unset` user by name; HostName stays | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-41 | refuse `unset` dns or ip | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-42 | `unset` missing field fail-closed | test_dns | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-DNS-43 | JSON `unset` one object; stanza kept | test_dns | requirement-domain-sshd · requirement-shell-output-requirements | **have** |
| TP-DNS-44 | TTY action Unset then field pick; HostName stays | test_dns | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-DNS-45 | `unset termux` strips bundle; Port and HostName stay | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-46 | `unset` missing n / unknown field fail-closed | test_dns | requirement-domain-sshd | **have** |
| TP-DNS-47 | TTY unknown dns action warns and redisplays | test_dns | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-DNS-48 | TTY unknown Host pick warns and redisplays | test_dns | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-DNS-49 | TTY unknown extra-settings pick warns and redisplays | test_dns | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |

### TP-SSH (OpenSSH client Host pick)

| TP-ID | Intent | Suite | Primary requirement(s) | Status |
|-------|--------|-------|------------------------|--------|
| TP-SSH-01 | help lists `ssh` | `tests/test_ssh_download.sh` | requirement-domain-sshd · requirement-shell-cli-interface | **have** |
| TP-SSH-02 | non-interactive `ssh` by name uses Host alias | test_ssh_download | requirement-domain-sshd | **have** |
| TP-SSH-03 | `ssh` by number | test_ssh_download | requirement-domain-sshd | **have** |
| TP-SSH-04 | missing operand fail-closed | test_ssh_download | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-SSH-05 | unknown Host fail-closed | test_ssh_download | requirement-domain-sshd | **have** |
| TP-SSH-06 | JSON `ssh` does not start a session | test_ssh_download | requirement-domain-sshd · requirement-shell-output-requirements | **have** |
| TP-SSH-07 | TTY pick Host 1; user default `-l` | test_ssh_download | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-SSH-08 | TTY user override `-l otheruser` | test_ssh_download | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-SSH-09 | TTY menu numbers ssh **12** / download **13** | test_ssh_download | requirement-domain-sshd | **have** |
| TP-SSH-10 | Commented HostKeyAlgorithms on the Host → `ssh -o HostKeyAlgorithms=+ssh-rsa` | test_ssh_download | requirement-domain-sshd | **have** |

### TP-DL (remote folder download)

| TP-ID | Intent | Suite | Primary requirement(s) | Status |
|-------|--------|-------|------------------------|--------|
| TP-DL-01 | help lists `download` | test_ssh_download | requirement-domain-sshd · requirement-shell-cli-interface | **have** |
| TP-DL-02 | non-interactive download extracts in cwd | test_ssh_download | requirement-domain-sshd | **have** |
| TP-DL-03 | remembers folder for that Host | test_ssh_download | requirement-domain-sshd | **have** |
| TP-DL-04 | TTY numbered previous folder | test_ssh_download | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-DL-05 | TTY type a new folder path | test_ssh_download | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-DL-06 | missing folder fail-closed | test_ssh_download | requirement-domain-sshd | **have** |
| TP-DL-07 | refuse shell metacharacters in folder | test_ssh_download | requirement-domain-sshd | **have** |
| TP-DL-08 | JSON download one object | test_ssh_download | requirement-domain-sshd · requirement-shell-output-requirements | **have** |
| TP-DL-09 | `Host *` is not a ssh/download row | test_ssh_download | requirement-domain-sshd | **have** |
| TP-DL-10 | TTY download default user `-l` | test_ssh_download | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-DL-11 | TTY download user override `-l` | test_ssh_download | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-DL-12 | TTY invalid user fail-closed; Next names download | test_ssh_download | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-DL-13 | TTY `""` omits `-l` | test_ssh_download | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-DL-14 | `~/folder` accepted (operand + TTY); remote `"$HOME"`; not this-login HOME | test_ssh_download | requirement-domain-sshd | **have** |
| TP-DL-15 | `~` alone fail-closed | test_ssh_download | requirement-domain-sshd | **have** |
| TP-DL-16 | `~user/path` fail-closed | test_ssh_download | requirement-domain-sshd | **have** |
| TP-DL-17 | TTY out-of-range folder number warns and redisplays | test_ssh_download | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |

### TP-UL (local folder upload)

| TP-ID | Intent | Suite | Primary requirement(s) | Status |
|-------|--------|-------|------------------------|--------|
| TP-UL-01 | help lists `upload` | test_ssh_download | requirement-domain-sshd · requirement-shell-cli-interface | **have** |
| TP-UL-02 | non-interactive upload streams local tar.gz; remote extracts under `"$HOME"` | test_ssh_download | requirement-domain-sshd | **have** |
| TP-UL-03 | remembers local folder for that Host | test_ssh_download | requirement-domain-sshd | **have** |
| TP-UL-04 | TTY numbered previous local folder | test_ssh_download | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-UL-05 | TTY type a new local path | test_ssh_download | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-UL-06 | missing folder operand fail-closed | test_ssh_download | requirement-domain-sshd | **have** |
| TP-UL-07 | refuse shell metacharacters in folder | test_ssh_download | requirement-domain-sshd | **have** |
| TP-UL-08 | JSON upload one object | test_ssh_download | requirement-domain-sshd · requirement-shell-output-requirements | **have** |
| TP-UL-09 | `Host *` is not an upload row | test_ssh_download | requirement-domain-sshd | **have** |
| TP-UL-10 | TTY upload default user `-l` | test_ssh_download | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-UL-11 | TTY upload user override `-l` | test_ssh_download | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-UL-12 | TTY invalid user fail-closed; Next names upload | test_ssh_download | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-UL-13 | TTY `""` omits `-l` | test_ssh_download | requirement-domain-sshd · requirement-shell-interactive-vs-noninteractive | **have** |
| TP-UL-14 | local `~/folder` accepted; this-login HOME for local tar; remote dest `"$HOME"` not this-login path | test_ssh_download | requirement-domain-sshd | **have** |
| TP-UL-15 | `~` alone fail-closed | test_ssh_download | requirement-domain-sshd | **have** |
| TP-UL-16 | `~user/path` fail-closed | test_ssh_download | requirement-domain-sshd | **have** |
| TP-UL-17 | missing local directory fail-closed | test_ssh_download | requirement-domain-sshd | **have** |
| TP-UL-18 | TTY client menu numbers upload **14** | test_ssh_download | requirement-domain-sshd · requirement-shell-cli-default-interaction | **have** |

### TP-OS (folder tar.gz by OS family)

**TP-UL-01** .. **TP-UL-18** stay the non-MSYS pipe. **TP-OS-GB-01** .. **TP-OS-GB-04** and **TP-OS-CMD-01** are in `tests/test_os_transfer.sh`. Alpine, BusyBox, and other Linux pipe rows stay todo.

| TP-ID | Intent | Suite | Primary requirement(s) | Status |
|-------|--------|-------|------------------------|--------|
| TP-OS-GB-01 | Upload to an MSYS reader uses a finished file, not `tar xzf -`. Local Git Bash uploading to a non-MSYS reader still pipes | test_os_transfer | requirement-shell-windows-git-bash-cli-coding | **have** |
| TP-OS-GB-02 | Download when this login is Git Bash uses a finished file, `scp`, a file extract, then removes the archive | test_os_transfer | requirement-shell-windows-git-bash-cli-coding | **have** |
| TP-OS-GB-03 | `gzip -t` rejection names gzip; a `tar` rejection names tar | test_os_transfer | requirement-shell-windows-git-bash-cli-coding | **have** |
| TP-OS-GB-04 | The MSYS transfer does not use `sleep` or `cat >` as the repair | test_os_transfer | requirement-shell-windows-git-bash-cli-coding | **have** |
| TP-OS-CMD-01 | `Windows_NT` keeps `tar xzf -` and does not call `scp` | test_os_transfer | requirement-shell-windows-cmd-cli-coding | **have** |
| TP-OS-ALP-01 | Alpine keeps the streamed pipe | — | requirement-shell-alpine-cli-coding | **todo** |
| TP-OS-BB-01 | BusyBox keeps the streamed pipe and does not rename applets | — | requirement-shell-busybox-cli-coding | **todo** |
| TP-OS-OTH-01 | Other Linux keeps the streamed pipe | — | requirement-shell-other-linux-cli-coding | **todo** |

### TP-LC (local lifecycle)

| TP-ID | Intent | Suite | Primary requirement(s) | Status |
|-------|--------|-------|------------------------|--------|
| TP-LC-01 | install → USER_BIN | test_local_lifecycle | requirement-shell-self-management | **have** |
| TP-LC-02 | installed binary version | test_local_lifecycle | requirement-shell-self-management | **have** |
| TP-LC-03 | reinstall already-installed | test_local_lifecycle | requirement-shell-idempotency | **have** |
| TP-LC-04 | about installed path | test_local_lifecycle | requirement-shell-self-management | **have** |
| TP-LC-05 | uninstall JSON no force fail-closed | test_local_lifecycle | requirement-shell-interactive-vs-noninteractive | **have** |
| TP-LC-06 | uninstall --force removes | test_local_lifecycle | requirement-shell-self-management | **have** |
| TP-LC-07 | uninstall absent no-op | test_local_lifecycle | requirement-shell-idempotency | **have** |
| TP-LC-08 | about shows installed | test_local_lifecycle | requirement-shell-self-management | **have** |
| TP-LC-09 | installed mode is `0755` | test_local_lifecycle | requirement-shell-self-management | **have** |
| TP-LC-10 | `--force` reinstall heals `0711` → `0755` | test_local_lifecycle | requirement-shell-self-management | **have** |
| TP-LC-11 | install creates `~/.bashrc` with USER_BIN PATH | test_local_lifecycle | requirement-shell-path-and-shell-support | **have** |
| TP-LC-12 | install creates `~/.profile` sourcing bashrc | test_local_lifecycle | requirement-shell-path-and-shell-support | **have** |
| TP-LC-13 | reinstall does not duplicate PATH | test_local_lifecycle | requirement-shell-path-and-shell-support · requirement-shell-idempotency | **have** |
| TP-LC-14 | existing `~/.profile` body kept | test_local_lifecycle | requirement-shell-path-and-shell-support | **have** |
| TP-LC-15 | not Termux: `pkg` not invoked | test_local_lifecycle | requirement-shell-termux-ish | **have** |
| TP-LC-16 | Termux mock: `pkg install -y openssh termux-auth` | test_local_lifecycle | requirement-shell-termux-ish · requirement-domain-sshd | **have** |
| TP-LC-17 | install ends by starting sshd (Termux stub) | test_local_lifecycle | requirement-domain-sshd | **have** |
| TP-LC-18 | Git Bash mock: `pkg` not invoked (normal-user-only CLI) | test_local_lifecycle | requirement-shell-cli-interface · requirement-shell-termux-ish | **have** |
| TP-LC-19 | Windows cmd mock: `pkg` not invoked (normal-user-only CLI) | test_local_lifecycle | requirement-shell-cli-interface · requirement-shell-termux-ish | **have** |
| TP-LC-20 | `BASHRC` env: create rc in a random temp folder when missing | test_local_lifecycle | requirement-shell-path-and-shell-support · requirement-shell-idempotency | **have** |
| TP-LC-21 | `BASHRC` env: modify a dongle `.bashrc` in that temp folder | test_local_lifecycle | requirement-shell-path-and-shell-support | **have** |
| TP-LC-22 | `BASHRC` env: already-correct VERSION + exact `export PATH=` is a no-op | test_local_lifecycle | requirement-shell-path-and-shell-support · requirement-shell-idempotency | **have** |
| TP-LC-27 | sibling exact PATH already present: no second export; sibling comment kept | test_local_lifecycle | requirement-shell-path-and-shell-support | **have** |
| TP-LC-28 | uninstall keeps shared PATH while USER_BIN still has files | test_local_lifecycle | requirement-shell-path-and-shell-support | **have** |
| TP-LC-29 | already installed + PATH missing: install heals exact export | test_local_lifecycle | requirement-shell-path-and-shell-support | **have** |
| TP-LC-30 | uninstall does not delete `.profile` | test_local_lifecycle | requirement-shell-path-and-shell-support | **have** |
| TP-LC-31 | `rc-test --root` create / modify / noop; real HOME bashrc untouched | test_local_lifecycle | requirement-shell-path-and-shell-support | **have** |

### TP-TX (Termux android-wake-lock)

| TP-ID | Intent | Suite | Primary requirement(s) | Status |
|-------|--------|-------|------------------------|--------|
| TP-TX-08 | not Termux: `termux-wake-lock` not invoked | test_local_lifecycle | requirement-shell-termux-ish | **have** |
| TP-TX-09 | Termux mock start (and already-running) invokes `termux-wake-lock` | test_local_lifecycle | requirement-shell-termux-ish · requirement-domain-sshd | **have** |
| TP-TX-10 | Termux mock `wake-lock` verb; idempotent | test_local_lifecycle | requirement-shell-termux-ish · requirement-shell-cli-interface | **have** |
| TP-TX-11 | Git Bash mock: helper not invoked | test_local_lifecycle | requirement-shell-termux-ish · requirement-shell-cli-interface | **have** |
| TP-TX-12 | Windows cmd mock: helper not invoked | test_local_lifecycle | requirement-shell-termux-ish · requirement-shell-cli-interface | **have** |
| TP-TX-13 | Termux start, helper missing: start succeeds; Next names `wake-lock` | test_local_lifecycle | requirement-shell-termux-ish · requirement-domain-sshd | **have** |
| TP-TX-14 | Termux `wake-lock` verb, helper missing: fail closed + Next `pkg install termux-tools` | test_local_lifecycle | requirement-shell-termux-ish | **have** |
| TP-TX-15 | help lists `wake-lock` / `wake-unlock` | test_cli (TP-CLI-04) | requirement-shell-cli-interface · requirement-shell-termux-ish | **have** |
| TP-TX-16 | `stop` does not invoke `termux-wake-unlock` | test_local_lifecycle | requirement-shell-termux-ish · requirement-domain-sshd | **have** |

### TP-CSUM (companion digest)

| TP-ID | Intent | Suite | Primary requirement(s) | Status |
|-------|--------|-------|------------------------|--------|
| TP-CSUM-01 | First install prints companion **link**; PASS or missing-sidecar warn; no mismatch abort | test_local_lifecycle | requirement-shell-automatic-checksum | **have** |

### TP-EXIT (process exit catalog)

| TP-ID | Intent | Suite | Primary requirement(s) | Status |
|-------|--------|-------|------------------------|--------|
| TP-EXIT-01 | Unknown token is status 1, `[ERROR]`, and names `help` (EX-DIE-196) | `tests/test_cli.sh` | requirement-shell-exit-condition | **todo** |
| TP-EXIT-02 | `--json` unknown token is status 1, stderr JSON `out_error`, code `unknown`, no `[ERROR]` | `tests/test_cli.sh` | requirement-shell-exit-condition | **todo** |
| TP-EXIT-03 | Front menu `9` exits 0. A bad menu number warns and does not exit | `tests/test_cli.sh` | requirement-shell-exit-condition | **todo** |
| TP-EXIT-04 | `--purpose` with no text is status 1 (EX-DIE-195) | `tests/test_cli.sh` | requirement-shell-exit-condition | **todo** |

---

## Rules

1. Closing a **bug** finding updates the matching TP to **have**.  
2. Do not mark TP **have** without a suite assertion (or honest skip/n/a).  
3. Do not reintroduce folder-backup / sudoers-emit as Core without a product-mode change.  
4. Domain TPs **are** Core for this product (`status` Connect, menu rows, Termux pkg, start-after-install, daemon vs service). Broader `stop`/`port`/`config`/`host-keys`/`auth-keys` behavioral TPs remain **todo** until added.  
5. There is **no** `requirement-bootstrap-chain` on this product. Trimmed parent verbs are owned by `requirement-shell-cli-interface`.
