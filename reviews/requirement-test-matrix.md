# Requirement ↔ test matrix — sshd-cli

**Updated:** 2026-10-14  
**Product VERSION:** 1.35.0  
**Suite:** `tests/run.sh`

| Requirement key | Area | TP families | Coverage notes |
|-----------------|------|-------------|----------------|
| requirement-class-software-dev | class | TP-CLI-01, TP-CLI-11 | Syntax + posix-sh stack |
| requirement-shell-cli-interface | shell | TP-CLI-* · TP-LC-18/19 · TP-TX-10/11/12/15 | Commands, flags, dispatch; domain verbs + `wake-lock` in help; Git Bash / Windows cmd; TTY **62** about (**TP-CLI-21**) |
| requirement-shell-cli-default-interaction | shell | TP-CLI-14 · **TP-CLI-21** · **TP-CLI-22** · **TP-CLI-23** · **TP-CLI-24** · TP-SSHD-03..05 · TP-SSHD-16 | Numbered tree; front **5** sudoers (**51–55**), **6** self-management (**61–67**), **7** language, block **70–89** (assigned **71–83**); TTY **62** / typed `version` run about; finished leaf → front board; TTY `--debug` with no verb opens the menu |
| requirement-shell-cli-language | shell | **TP-CLI-24** · TP-CLI-14 · TP-SSHD-04 | English default; block **70–89** (at most 20); **72** through **83** persisted (Simplified Chinese through Greek); **71** restores English; **70**, **84**, and **89** do not write the file; front **8** does not open the language board; `SSHD_CLI_LANG` overrides the file; human help and about follow the code |
| requirement-shell-cli-zero-arguments | shell | TP-CLI-07, TP-CLI-14, TP-CLI-23, TP-SI-03 | Non-TTY CLI self-install; TTY menu; switch-only `--debug` menu and `--quiet` / `--json` self-install |
| requirement-shell-cli-self-install | shell | TP-SI-01..06, TP-CLI-07, TP-CLI-23 | Copy from script `$0`; dest 0700; NI empty argv and `--quiet` / `--json` with no verb place the CLI |
| requirement-shell-self-management | shell | TP-LC-* (incl. **09/10** mode) · TP-CLI-10 | install / self-uninstall; **0755**; companion **call site**; channel verbs routed. Rc bodies: `requirement-shell-path-and-shell-support` |
| requirement-shell-path-and-shell-support | shell | TP-LC-11–14 · TP-LC-20–22 · TP-LC-27–31 · TP-CLI-18 | PATH / profile; sibling; scoped uninstall; heal; `rc-test` routed |
| requirement-shell-output-requirements | shell | TP-CLI-03,05,08,09 | JSON / quiet / errors |
| requirement-shell-exit-condition | shell | TP-EXIT-01..04 | **todo** — catalog written; suite rows not asserted yet |
| requirement-shell-modular-function-design | shell | (indirect) | `sshd_*` domain prefix; `app_main` / `out_*`; `inst_ensure_companion` — no dedicated prefix scan |
| requirement-shell-idempotency | shell | TP-LC-03,07,13,14,20,21,22 | Re-install / uninstall absent / PATH / profile; `BASHRC` create / dongle modify / VERSION+PATH no-op |
| requirement-shell-interactive-vs-noninteractive | shell | TP-LC-05, TP-CLI-07, TP-CLI-14, TP-DNS-05, TP-DNS-08, TP-DNS-11, TP-DNS-13, TP-DNS-42, TP-DNS-44, TP-DNS-47..49, TP-SSH-07, TP-SSH-08, TP-DL-04, TP-DL-05, TP-DL-10, TP-DL-11, TP-DL-12, TP-DL-13, TP-DL-14, TP-DL-15, TP-DL-16, TP-DL-17, TP-SSHD-05, TP-SSHD-16, TP-CFG-17, **TP-UL-01..18** | self-uninstall confirm; empty-argv TTY vs pipe; dns walk vs list/set/unset; pick 9 is a Host; TTY unknown menu redisplay; ssh/download/upload TTY user default; download remote `~/folder`; upload local `~/folder` |
| requirement-shell-cli-storage | shell | TP-CLI-**06**, **12**, **19**, **20** | Per-login per-process cache (`cache-${APP_NAME}-${login}-$$` on shm/tmp) + persistence `${HOME}/.local/${APP_NAME}`; silent tier miss; Git Bash omits 2nd fallback; Termux cache may be `noexec` |
| requirement-shell-automatic-checksum | shell | TP-CSUM-01, TP-CLI-04, TP-CLI-06 | Companion **link** on install; CHECKSUM omitted from help/about. Not TP-LC-01. |
| requirement-domain-sshd | domain | TP-CLI-04, TP-CLI-06, TP-CLI-14, TP-CLI-15, TP-LC-16, TP-LC-17, **TP-SSHD-01**, **TP-SSHD-02**, **TP-SSHD-03..08**, **TP-SSHD-09..16**, **TP-DNS-01..52**, **TP-FIX-01..14**, **TP-SSH-01..09**, **TP-DL-01..17**, **TP-UL-01..18**, **TP-TX-09**, **TP-TX-13**, **TP-TX-16**, **TP-CFG-01..17** | help rows; menu 1–5 plus ssh 6 / download 7 / upload 8; POSIX Linux non-root hides 2/3/4; TTY unknown menu redisplay; host-local Linux errors; systemd unit path; Termux daemonize; dns Edit/Add/Delete/Unset; `fix-config` comments unsupported client keywords by OS; `ssh` Host pick + user default; `download` user default + folder tar.gz + `~/folder`; `upload` local tar.gz into remote home; minted Host/IP fixtures; config deposit |
| requirement-shell-sudoer | shell | TP-CFG-06, TP-CFG-07, TP-CFG-04/05/09 | JSON grant, print-sudoers, nuser hide; wrap `util_sudo` |
| requirement-shell-config-backup | shell | TP-CFG-01..16 | `/var/sshd-cli` deposit; depends on shell-sudoer for 06/07 |
| requirement-sshd-config-backup | backup | TP-CFG-01..16 | Points at shell-config-backup |
| requirement-sudoer-json-file | privilege | TP-CFG-06, TP-CFG-07 | Points at shell-sudoer |
| requirement-three-layer-privilege-model | privilege | TP-CFG-06, TP-CFG-07 | Points sudoer verbs at shell-sudoer |
| requirement-shell-sudo-command | shell | TP-CFG-01, TP-CFG-06 | Points wrap at shell-sudoer |
| requirement-shell-termux-ish | shell | TP-LC-15, TP-LC-16, TP-LC-18, TP-LC-19, **TP-TX-08..16** | not Termux: `pkg` / `termux-wake-lock` not invoked; Termux mock: `pkg install -y openssh termux-auth`; auto-acquire + `wake-lock` verb; Git Bash / Windows cmd skip |
| requirement-shell-script-coding | shell | TP-CLI-01, TP-CLI-11, TP-CLI-20 | `sh -n`; `set -u` with HOME unset; mkdir fail-soft (no mid-chain die); family fences are the nine CLI coding homes |
| requirement-shell-fedora-redhat-cli-coding | shell | TP-SSHD-03, TP-SSHD-09..14, TP-SSHD-10, **TP-SSHD-17** | `posix` class; no `dnf`/`yum` (absent by design); unit probe `ssh.service` or `sshd.service`; non-root hides 22–24; missing-sshd hint names `dnf` and `apt`. No Fedora-only suite host |
| requirement-shell-debian-cli-coding | shell | TP-SSHD-03, TP-SSHD-09..14, TP-SSHD-10, **TP-SSHD-17** | `posix` class; no `apt` wrap; missing-sshd hint is not Debian-only. No Debian-only suite host |
| requirement-shell-macos-cli-coding | shell | TP-CLI-12, TP-CLI-20, **TP-SSHD-17** | Darwin cache `/tmp/cache` → `Library/Caches` → `~/cache`; digest stays `util_sha256_file`; Mac missing-sshd hint does not name `brew` |
| requirement-shell-termux-cli-coding | shell | TP-SSHD-04, TP-SSHD-13, TP-CFG-04 | `sshd_is_termux`; sudoers hide; start does not call `systemctl`. `pkg` and wake lock stay on termux-ish |
| requirement-shell-windows-git-bash-cli-coding | shell | TP-CFG-05, TP-CLI-12, TP-LC-18, **TP-SSHD-17**, **TP-OS-GB-01..04** (todo) | `sshd_is_git_bash`; token `gitbash`; cache tmp → AppData; `install` does not call `pkg`; missing-sshd hint does not name `apt`. Owns the MSYS gzip-stdin ban. Ship unit still pipes. Windows cmd is TP-LC-19 and TP-OS-CMD-01, not this row |
| requirement-shell-windows-cmd-cli-coding | shell | TP-CFG-09, TP-LC-19, **TP-OS-CMD-01** (todo) | Detect after Git Bash, Cygwin, and WSL. Keeps the streamed pipe. `Windows_NT` is not the MSYS ban |
| requirement-shell-alpine-cli-coding | shell | TP-FIX-*, **TP-OS-ALP-01** (todo) | `sshd_fix_os_class` alpine. Keeps the streamed pipe. No `apk` wrap. GSSAPI stays on the domain file |
| requirement-shell-busybox-cli-coding | shell | **TP-OS-BB-01** (todo) | `busybox APPLET`. Keeps the streamed pipe. Does not rename filename-selected applets |
| requirement-shell-other-linux-cli-coding | shell | **TP-OS-OTH-01** (todo) | POSIX Linux outside Debian, Fedora/RHEL, Alpine, and Termux. Keeps the streamed pipe. No invented package tool |

**Absent by design (no TP Core):** folder-archive backup/restore, sudoers-file emit, systemd unit files.

**Honest todo (not Core this cut):** dedicated `stop`/`port`/`config`/`host-keys`/`auth-keys` behavioral TPs; public-network curl; prefix-scan for modular-function-design.
