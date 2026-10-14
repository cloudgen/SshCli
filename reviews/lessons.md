# Lessons — sshd-cli

Durable failure modes. **Always re-check on product review.**

| ID | Mode | Prevention | Status |
|----|------|------------|--------|
| L-TYPE-N-01 | TTY empty argv accidentally becomes install-ensure (menu split lost) | `requirement-shell-cli-zero-arguments` TTY menu / non-TTY Type O; TP-CLI-07 **and** TP-CLI-14 | open watch |
| L-ONLINE-01 | Channel env advertised as a verb, or `CHECKSUM` on help/about | `SCRIPT_URL` is a channel env (not a command); TP-CLI-04/10; TP-CSUM-01 | open watch |
| L-UNIN-01 | Non-interactive uninstall succeeds without force | TP-LC-05 confirm fail-closed | open watch |
| L-INST-MODE-01 | Install leaves `0711`/`0700` (chmod +x after mktemp) so non-owners cannot run shell ship unit | absolute `chmod 0755` + heal on reinstall; TP-LC-09/10; local-self-management §2.3.1 | open watch |
| L-TRIM-01 | Backup / restore / sudoers verbs reintroduced as if still product law | bootstrap-chain (absent domain); TP-CLI-04/13 | open watch |
| L-PUSH-VAULT-01 | Bare `git push` uses wrong active SSH vault when default face ≠ repository-user | Pre-git report + bound SSH transport; incident 20260810-001 | open watch |
| L-SETU-01 | `set -u` crash with unset HOME | TP-CLI-11 | open watch |
| L-STOR-01 | Shared world-writable storage / one cache leaf for every login | util_resolve_storage; leaf `cache-${APP_NAME}-${login}-$$` under `/dev/shm/cache` or `/tmp/cache`; TP-CLI-12 | open watch |
| L-STOR-02 | A missed cache tier prints `[ERROR]` or skips the next root | Silent tier miss. Git Bash preferred is `/tmp/cache/cache-${APP_NAME}-${login}-$$`, then `${HOME}/AppData/Local/Temp/cache-${APP_NAME}-$$` (no 2nd fallback line). **INC-20260911-001**; TP-CLI-12 · TP-CLI-19 · TP-CLI-20 | open watch |
| L-INTENT-01 | Harness Type 0 / “don’t wrap package managers” overrode a clear Termux sshd purpose; `pkg` listed as a domain non-goal until the operator named packages | Purpose wins: specialize **`LM-SHELL-TERMUX-ISH`** / `requirement-shell-termux-ish`; bootstrap Step 5c; domain Protection Rule 8b; Linux `apt` stays out; TP-LC-15/16 | open watch |
| L-ERR-HOST-01 | POSIX Linux start/stop fail-closed copy hardcoded “use Termux” as a next step on a host that is not Termux | Next step is host-local (Linux: re-run as root); do not name another platform after detect; **INC-20260908-001**; `CL-OPERATOR-READABLE-ERROR` E3 | open watch |
| L-SSHD-UNIT-01 | Ubuntu already-running `start` printed session-daemon / “not a systemd” copy for a pid that was `ssh.service` (`sshd -D`, `ssh.socket`) | Scope (“this CLI does not manage systemd”) ≠ process fact; already-running copy must not deny the distro unit; **INC-20260908-002**; `PO-STAY-HONEST` · `PO-MUST-NOT-CONFUSE` | open watch |
| L-DNS-01 | TTY Host pick reused main-menu Exit `9` on an unbounded list | Leave with `0` / empty; TP-DNS-13 | open watch |
| L-DNS-02 | `dns add` appended after trailing `Host *` so OpenSSH first-match ignored new User/Port | Insert before first wildcard Host / Match; atomic replace; TP-DNS-14 | open watch |
| L-DNS-03 | `Key=value` / extra Host aliases lost on set | Parse optional `=`; keep aliases after first pattern; TP-DNS-15/16 | open watch |
| L-DNS-04 | TTY main menu omitted `dns` so an update-and-open looked like the Host list was never added | Number `dns` as row 5; TP-CLI-14 · TP-DNS-20 | open watch |
| L-DNS-05 | TTY Host list treated a number as update-only; no add/delete | Action menu Edit/Add/Delete then Host pick; TP-DNS-20..24 | open watch |
| L-RC-01 | Path-ensure claimed without routed `rc-test`; uninstall `sed` matched any installer comment | Dual-mention `rc-test`; help testers apart; strip only this `APP_NAME` comments; **INC-20260909-001**; TP-LC-27..31 · TP-CLI-18 | open watch |
| L-SSHD-SELFUPD-01 | `self-update` (or CLI `install`) `out_die`s after a successful binary place because `sshd -t` of `/etc/ssh/sshd_config` fails (`/run/sshd` missing) | CLI lifecycle success ≠ host sshd config test; `SKIP_DOMAIN_START` on `self-update`; Linux install warn-not-die; **INC-20260909-002**; TP-SSHD-15 | watch |
| L-DNS-06 | Suite copies this-login Host alias or LAN IPv4 into `tests/**` (exposes developer computer) | Mint `t_rand_host` / `t_rand_ip`; file-leaks C6; **PP-A-26** / **PP-C-21**; **INC-20260909-003**; TP-DNS-37 · TP-DNS-38 | open watch |
| L-DL-01 | TTY `download` skips the `ssh` user prompt, so BatchMode ssh uses this login / Host User with no override | Same user walk as `ssh`; `-l` when non-empty; **INC-20260912-001**; TP-DL-10..13 | open watch |
| L-DL-02 | `download` refuses `~/folder` as if `~` were a metacharacter; single-quoting `~/…` blocks remote tilde | Allow `~/folder`; remote `"$HOME"/'folder'`; refuse `~` alone and `~user/…`; **INC-20260912-002**; TP-DL-14..16 | open watch |
| L-TTY-THIN-01 | TTY numbered row reprints the board header (thin sibling of a richer diagnostic on the same board) | TTY **62** / typed `version` run `about`; argv `version` stays thin; do not number `help` / `menu` / `where-is-me` / `config` beside `status`; **INC-20260914-001**; **TP-CLI-21** | open watch |
| L-UL-01 | MSYS / Git Bash gzip stdin short-read on folder upload or download (`invalid compressed data--format violated`, remote Unexpected EOF, local short write / status 141) | `requirement-shell-windows-git-bash-cli-coding` **1.1.0**: finish the archive, copy the file, extract the file, remove the archive. Do not treat fake-ssh **TP-UL-*** as proof. A short sleep is not a repair. **INC-20261014-001**. **TP-OS-GB-01..04** are todo. The ship unit still pipes | open watch |

**Related-product only (do not re-apply as this origin’s law):** L-DEPOSIT-01, L-SUDOERS-01..05, L-OVERWRITE-01 stay on folder-backup. Type O empty-argv / online-channel lessons stay on products that own those surfaces. This product is hop 0.

**This origin’s kept surfaces:** output SSOT, no basename gate on entry, storage isolation, Type N empty argv.
