**file**: docs/requirements/requirement-sshd-config-backup.md  
**Status**: Retired (Python generation 2.0.0. The live ship unit is the SshCli package. This file records the /bin/sh ship unit through 1.35.1. Where it disagrees with requirement-domain-sshd 1.28.0 or an Active requirement-python-*.md / requirement-runtime-prerequisites.md file, those win.) Was  (Version 1.1.3)  
**Area**: backup  
**Key**: `requirement-sshd-config-backup`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement **points** at `requirement-shell-config-backup` for depositing this login’s `~/.ssh/config` into `/var/sshd-cli` (`backup-config`), `sync-config`, and `sync-from-remote`. Elev wrap and JSON grant: `requirement-shell-sudoer`. Do **not** duplicate copy semantics here. It is not folder-archive tar.gz.

### 1.1 Human-facing

**In one sentence:** `backup-config` copies this login’s SSH client config into `/var/sshd-cli/config` as root after a passwordless grant; `sync-config` copies that file back as you, mode 600; `sync-from-remote` `scp`s the same file from another host and remembers the last `user@host` as the next default.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Push or pull the SSH client config | `sshd-cli backup-config` · `sshd-cli sync-config` · `sshd-cli sync-from-remote user@host` |
| The other role | sudoer-adm approves passwordless `sudo sshd-cli backup-config` | JSON grant inbound |
| Not this file | Host list edit; sudoers JSON schema | `requirement-domain-sshd` · `requirement-shell-sudoer` |

| Includes | Excludes |
|----------|----------|
| Source `~/.ssh/config`; dest `/var/sshd-cli/config`; SUDO_USER home when elevated; dest mode 600 on sync; `sync-from-remote` SPEC + preferred-remote | Whole `~/.ssh` including private keys; folder-archive `backup`/`restore`; Termux / Git Bash / Windows cmd **deposit** (`backup-config` / local `sync-config`) |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./sshd-cli` | ship unit | live verbs |
| `/var/sshd-cli/config` | durable store | backup dest / sync source |
| `sshd-cli backup-config` | command | elevated push |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Share this login’s SSH names | Copy `~/.ssh/config` into the host store as root | `sshd-cli backup-config` |
| Use the shared names | Copy the store into this login’s `~/.ssh/config` as 600 | `sshd-cli sync-config` |
| Pull from another host | `scp` that host’s `/var/sshd-cli/config`; last SPEC is the next default | `sshd-cli sync-from-remote user@host` |

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Source and dest

1. Source **MUST** be the invoking login’s `{{HOME}}/.ssh/config`. When the process is root via sudo, invoking home **MUST** be `SUDO_USER`’s passwd home (not `/root`) unless tests set an explicit root home.  
2. Default dest directory **MUST** be `/var/sshd-cli`. Override `SSHD_CLI_ROOT` (tests / non-production). Store file **MUST** be `{{SSHD_CLI_ROOT}}/config`.  
3. **MUST NOT** copy private keys, `id_*`, or the whole `~/.ssh` directory.  
4. Missing source **MUST** fail closed. Next: create this login’s SSH config (for example `sshd-cli dns add`), then `sshd-cli backup-config`.

### 2.2 backup-config (elevated deposit)

1. On Termux, Git Bash, or Windows cmd **MUST** fail closed. Next: use a POSIX Linux host.  
2. Writing the production dest (`/var/sshd-cli` or a path under it) as a non-root login **MUST** re-exec `sudo -n {{GLOBAL_BIN}}/sshd-cli backup-config` (exact grant; no extra flags on the sudo command line) through `util_sudo`.  
3. If that sudo is refused, **MUST** fail closed and tell the operator to generate/submit a JSON grant for sudoer-adm. Next: `sshd-cli generate-sudoer-request && sshd-cli submit-sudoer-request`.  
4. As root, the ship unit **MUST** `mkdir` the dest if needed, copy the file, `chown root:root`, `chmod 0644` the file and `0755` the dest.  
5. **MUST NOT** grant OS tools (`cp`, `mkdir`, `chmod`, `chown`) in sudoers; those run inside the elevated product command.  
6. A writable `SSHD_CLI_ROOT` outside `/var/sshd-cli` **MAY** accept Type 0 deposit for tests (no chown). Production dest **MUST NOT** skip elev just because it happens to be writable.  
7. Re-running backup-config **MUST** overwrite the same basename (idempotent snapshot, no dated tar).

### 2.3 sync-config (no sudo)

1. `sync-config` **MUST NOT** call `sudo`.  
2. Source is `{{SSHD_CLI_ROOT}}/config`. Dest is this login’s `{{HOME}}/.ssh/config`.  
3. **MUST** fail closed if the store is missing or unreadable without sudo. Next: someone with an approved `sudo sshd-cli backup-config` must push first.  
4. **MUST** create dest `~/.ssh` if needed (dir mode `700` when possible).  
5. Dest `config` **MUST** be mode `600` after copy. Owner is this login.

### 2.4 sync-from-remote (no sudo)

1. **MUST** route **`sync-from-remote`**. Dual mention: this file **and** `requirement-shell-cli-interface`.  
2. **MUST** be Type 0. **MUST NOT** call `sudo`. **MUST** be available on Termux / Git Bash / Windows cmd (unlike `backup-config` / local `sync-config`).  
3. Operand **SPEC** **MUST** be exactly one of: `{{user}}@{{ipv4}}`, `{{ipv4}}`, `{{domain-name}}`, `{{user}}@{{domain-name}}`.  
4. When SPEC has no `user@`, SSH **MUST** use the invoking login / ssh config (do not invent a Unix login).  
5. **MUST** reject empty SPEC, extra `@`, paths, and shell metacharacters. Off-TTY missing SPEC **MUST** fail closed with Next: `sshd-cli sync-from-remote USER@HOST`. On TTY with no operand, **MUST** `read` in the current shell (**MUST NOT** `_spec=$(prompt_ask …)`).  
6. Preferred SPEC **MUST** be stored in persistence storage (`${HOME}/.local/${APP_NAME}/preferred-remote`, mode **0600**). After a successful pull, **MUST** save the SPEC that worked. On TTY with no operand, **MUST** load that leaf first (if present and still a valid SPEC). When a preferred value is stored, the prompt **MUST** show it at the **end** as `[user@host]: `. Empty input (Enter) **MUST** use that default. No stored value → no default suffix; empty input still fail-closed. **MUST NOT** treat an invalid stored line as a default.  
7. Transport **MUST** be `scp` in **BatchMode** (no password hang). Override `SSHD_CLI_SCP` for tests. Missing `scp` **MUST** fail closed.  
8. Remote source **MUST** be `{{SSHD_CLI_REMOTE_ROOT}}/config` (default `/var/sshd-cli`). Dest is this login’s `~/.ssh/config` mode **600**. Dest dir mode **700** when created.  
9. Core tests **MUST NOT** open a real SSH session.

### 2.5 Invocation samples

```text
sshd-cli backup-config
sshd-cli sync-config
sshd-cli sync-from-remote user@host.example.test
sshd-cli generate-sudoer-request
sshd-cli submit-sudoer-request
```

### 2.6 Implementation Notes (this project)

**SSOT:** `requirement-shell-config-backup` (ops) · `requirement-shell-sudoer` (elev). Product store names stay:

| Item | Value |
|------|--------|
| Store | `/var/sshd-cli/config` (`SSHD_CLI_ROOT` default `/var/sshd-cli`) |
| Source | `$(sshd_invoking_home)/.ssh/config` |
| Elev argv | `sudo -n /usr/local/bin/sshd-cli backup-config` |
| Handlers | `sshd_cmd_backup_config` · `sshd_cmd_sync_config` · `sshd_cmd_sync_from_remote` · `util_sudo` |
| Persistence | `${HOME}/.local/sshd-cli/preferred-remote` |
| Tests | `tests/test_config_backup.sh` **TP-CFG-01..16** |

### 2.7 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 10 – Least privilege** (https://github.com/cloudgen/ciao): elev is the product command only.  
- **CIAO Principle 12 – Right backup** (https://github.com/cloudgen/ciao): durable host store is not the dns pre-edit `.bak`.  
- **CIAO Principle 22 – File modes** (https://github.com/cloudgen/ciao): store 0644; dest 600.

## Under command line for normal user only

When the ship unit detects Termux, Git Bash, Windows cmd, or the same class: **MUST NOT** deposit into `/var/sshd-cli` or wrap `sudo`. Direct `backup-config` / local `sync-config` **MUST** fail closed. The client board’s **menu-hidden message** for that cause **MUST** print `[INFO] backup-config and sync-config not available for termux` / `gitbash` / `windows-cmd` **before** the client numbered list and **MUST** omit **15** backup-config and **16** sync-config. **`sync-from-remote` remains available** (Type 0 `scp`) and **MUST** be numbered **18** on the client board (client **12** `ssh`, **13** `download`). Front **5** sudoers is a separate hide cause on the front board. Its menu-hidden message is owned by `requirement-shell-cli-default-interaction` (`sudoers not available for termux` / `gitbash` / `windows-cmd`). Numbers: `requirement-shell-cli-default-interaction`.

**This requirement:** host deposit is POSIX Linux; remote pull is this-login `scp` on every class.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: SUDO_USER home; no private keys.  
- **Intentional**: `backup-config` vs `sync-config` vs dns `util_backup`.  
- **Anti-fragile**: `SSHD_CLI_ROOT` for tests; overwrite same leaf.  
- **Over-protect**: fail closed on this-login-only hosts.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Tar the whole `~/.ssh` or copy private keys.  
2. Name the pull verb `restore` / `restore-config` (folder-archive retired; pull is `sync-config`).  
3. Grant `cp`/`mkdir`/`chmod` in sudoers.  
4. Enable **deposit** (`backup-config`) on Termux / Git Bash / Windows cmd.  
5. Use `/root/.ssh/config` when `SUDO_USER` is set.  
6. Hide or fail-closed `sync-from-remote` because Termux/Git Bash was detected.  
7. `_spec=$(prompt_ask …)` for the remote SPEC (do-not-capture-read).  
8. Store preferred-remote on `/dev/shm` (must survive reboot: `${HOME}/.local/${APP_NAME}/preferred-remote`).

## 5. Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CFG-01** | `tests/test_config_backup.sh` | have |
| **TP-CFG-02** | `tests/test_config_backup.sh` | have |
| **TP-CFG-03** | `tests/test_config_backup.sh` | have |
| **TP-CFG-04** | `tests/test_config_backup.sh` | have |
| **TP-CFG-05** | `tests/test_config_backup.sh` | have |
| **TP-CFG-08** | `tests/test_config_backup.sh` | have |
| **TP-CFG-09** | `tests/test_config_backup.sh` | have |
| **TP-CFG-10** | `tests/test_config_backup.sh` | have |
| **TP-CFG-11** | `tests/test_config_backup.sh` | have |
| **TP-CFG-12** | `tests/test_config_backup.sh` | have |
| **TP-CFG-13** | `tests/test_config_backup.sh` | have |
| **TP-CFG-14** | `tests/test_config_backup.sh` | have |
| **TP-CFG-15** | `tests/test_config_backup.sh` | have |
| **TP-CFG-16** | `tests/test_config_backup.sh` | have |

**Matrix:** `docs/reviews/requirement-test-matrix.md`  
**Map:** `docs/reviews/test-plan.md`.

## 6. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry |
| `docs/requirements/requirement-shell-config-backup.md` | **SSOT** — deposit / sync / remote pull |
| `docs/requirements/requirement-shell-sudoer.md` | **Required peer** — wrap + JSON + print/generate/submit |
| `docs/requirements/requirement-domain-sshd.md` | Dual mention catalog |
| `./sshd-cli` | Ship unit |

**Last Updated**: 2026-10-14 (1.1.3 front **5** sudoers is the separate hide cause. 1.1.2 front **7** hide sentence is have on the menu requirement. 2026-09-28 menu-hidden message; sync-from-remote)  
**Owner**: sshd-cli project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; CIAO (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
