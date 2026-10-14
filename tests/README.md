# Tests — sshd-cli

## Run

```sh
./tests/run.sh
# or
sh tests/run.sh
```

Exit **0** when all assertions pass; **1** on failure; **2** if ship unit missing.

## Layout

| File | Focus | TP families |
|------|--------|-------------|
| `run.sh` | Entrypoint | — |
| `helpers.sh` | Asserts + isolated HOME | — |
| `test_cli.sh` | CLI surface, empty argv, `self-install`, domain help, systemd unit path, POSIX Linux non-root menu hide, TTY unknown menu retry, finished leaf returns to front board, per-login per-process cache (Linux / Git Bash / Mac) | **TP-CLI-*** · **TP-SI-01..06** · **TP-SSHD-01** · **TP-SSHD-03..14** · **TP-SSHD-16** |
| `test_local_lifecycle.sh` | install / self-uninstall / about / login rc / `BASHRC` fixture / sibling / scoped uninstall / heal / `rc-test` / Termux pkg mock / companion link / daemon hint / Android wake lock | **TP-LC-*** · **TP-CSUM-01** · **TP-SSHD-02** · **TP-TX-08..16** |
| `test_dns.sh` | this-login `~/.ssh/config` Host list (dns-ip; edit/add/delete/unset; as Termux / identity / Old OpenSSH comments; simpler Ciphers/MACs; **minted** Host/IP; TTY unknown retry; alpine comments `GSSAPI*`) | **TP-DNS-01..52** |
| `test_fix_config.sh` | `fix-config` flags, OS comment table, automatic pass on `version` | **TP-FIX-01..14** |
| `test_ssh_download.sh` | OpenSSH client Host pick (`ssh`) + user default + commented `HostKeyAlgorithms` `-o` + remote folder tar.gz (`download`) + local folder tar.gz (`upload`) with TTY user default and `~/folder`; fake `SSHD_CLI_SSH`. Those rows are not an MSYS reader. **TP-OS-*** stay todo | **TP-SSH-01..10** · **TP-DL-01..17** · **TP-UL-01..18** |
| `test_config_backup.sh` | `backup-config` / `sync-config` / `sync-from-remote` / sudoers grant; Termux Git Bash Windows cmd hide; TTY sudoers unknown retry | **TP-CFG-01..17** |

## Isolation

- Temp `HOME` + `USER_BIN` + redirected `GLOBAL_BIN` for install tests  
- **`BASHRC`** redirected to a random temp folder for **TP-LC-20..22** (create / modify dongle / no-op)  
- **dns Host/IP minted per run** (`t_rand_host` / `t_rand_ip`) — never this-login aliases or live LAN IPv4 (**PP-A-26** / **PP-C-21**)  
- **No** public network  
- **No** write to `/etc` or `/var/backup`

## Ship unit under test

`src/sshd-cli` (channel copy `./sshd-cli`)

## Maps

Product TP map: `reviews/test-plan.md`  
RTM: `reviews/requirement-test-matrix.md`
