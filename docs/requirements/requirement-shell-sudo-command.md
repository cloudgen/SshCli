**file**: docs/requirements/requirement-shell-sudo-command.md  
**Status**: Retired (Python generation 2.0.0. The live ship unit is the SshCli package. This file records the /bin/sh ship unit through 1.35.1. Where it disagrees with requirement-domain-sshd 1.28.0 or an Active requirement-python-*.md / requirement-runtime-prerequisites.md file, those win.) Was  (Version 1.0.0)  
**Area**: shell  
**Key**: `requirement-shell-sudo-command`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement **points** at `requirement-shell-sudoer` for in-tool sudo: one wrapping function `util_sudo`, check before sudo, and the studied allow table for `backup-config`. Do **not** duplicate the wrap body here.

### 1.1 Human-facing

**In one sentence:** when you are not root, `backup-config` asks passwordless sudo to run the same program again as root — only that one command.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Run backup-config | `sshd-cli backup-config` |
| The other role | sudoer-adm already approved the grant | `/etc/sudoers.d/sshd-cli-<id -un>` |
| Not this file | JSON body; copy semantics | `requirement-shell-sudoer` · `requirement-shell-config-backup` |

| Includes | Excludes |
|----------|----------|
| `util_sudo`; already-root skip; `sudo -n` exact argv | Scattered raw `sudo`; `sudo true` probes |

| Surface | What you open | What for |
|---------|---------------|----------|
| `util_sudo` | wrap | only sudo call site |
| allow table | this file | dest + argv |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Push config as yourself | The CLI re-execs the global binary | `sshd-cli backup-config` |

## 2. Core Rules / Requirements (Mandatory)

1. **MUST** keep one wrap `util_sudo`. **MUST NOT** scatter raw `sudo` for product elev.  
2. Already-root **MUST** run argv without sudo (C5).  
3. Non-root production dest **MUST** use `sudo -n` matching the allow table (NOPASSWD). **MUST NOT** default `sudo -n` for other verbs.  
4. **MUST NOT** probe with `sudo true` / `sudo mkdir` / `sudo cp`.  
5. Probe for skip: `id -u` = 0, or dest is a writable `SSHD_CLI_ROOT` outside `/var/sshd-cli`. **MUST NOT** use `[ -O dest]` to skip a `/var/sshd-cli` deposit.

### 2.1 Sudo allow table (studied)

| Binary | Verb | Operand | Fragment dest | NOPASSWD? | This wrap? | Study evidence |
|--------|------|---------|---------------|-----------|------------|----------------|
| `{{GLOBAL_BIN}}/sshd-cli` | `backup-config` | none (verb-only) | `/etc/sudoers.d/sshd-cli-{{username}}` | yes | yes | this product `print-sudoers` emit |

### 2.2 Implementation Notes (this project)

**SSOT:** `requirement-shell-sudoer` §2.4. `util_sudo` in `./sshd-cli`. Call site: `sshd_cmd_backup_config`. Dual mention: `requirement-shell-config-backup`.

## Under command line for normal user only

On Termux / Git Bash / Windows cmd, `util_sudo` **MUST NOT** run: those verbs fail closed first. **This requirement:** wrap exists for POSIX Linux only.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: C0–C6.  
- **Intentional**: one wrap.  
- **Anti-fragile**: already-root path.  
- **Over-protect**: verb-only argv.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Guess dest as `/etc/{{username}}/sshd-cli` when print-sudoers says `/etc/sudoers.d/sshd-cli-{{username}}`.  
2. Wrap `sync-config`.  
3. Probe `sudo true`.

## 5. Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CFG-01** | `tests/test_config_backup.sh` | have |
| **TP-CFG-06** | `tests/test_config_backup.sh` | have |

**Matrix:** `docs/reviews/requirement-test-matrix.md`  
**Map:** `docs/reviews/test-plan.md`.

## 6. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry |
| `docs/requirements/requirement-shell-sudoer.md` | **SSOT** — wrap + allow table + JSON |
| `docs/requirements/requirement-shell-config-backup.md` | Ops (depends on sudoer) |
| `docs/requirements/requirement-shell-script-coding.md` | Points at sudoer SSOT |
| `./sshd-cli` | Ship unit |

**Last Updated**: 2026-09-11  
**Owner**: sshd-cli project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; CIAO (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
