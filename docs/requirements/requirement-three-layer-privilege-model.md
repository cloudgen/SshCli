**file**: docs/requirements/requirement-three-layer-privilege-model.md  
**Status**: Retired (Python generation 2.0.0. The live ship unit is the SshCli package. This file records the /bin/sh ship unit through 1.35.1. Where it disagrees with requirement-domain-sshd 1.28.0 or an Active requirement-python-*.md / requirement-runtime-prerequisites.md file, those win.) Was  (Version 1.0.0)  
**Area**: privilege  
**Key**: `requirement-three-layer-privilege-model`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement owns the **Type 0 / Type 1 / Type 2 map** for sshd-cli. Type 2 is unused. Type 1 is the approved `sudo sshd-cli backup-config` grant (not a dedicated system user). **Sudoer verbs, JSON body, and `util_sudo` SSOT:** `requirement-shell-sudoer`. Do **not** duplicate those handlers here.

### 1.1 Human-facing

**In one sentence:** you write a JSON grant, queue it for sudoer-adm, or as root install the printed fragment so `sudo sshd-cli backup-config` needs no password.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Generate and submit | `sshd-cli generate-sudoer-request` then `sshd-cli submit-sudoer-request` |
| The other role | sudoer-adm or a root login | approve inbound, or `sudo sh …-sudoers-admin.sh install` |
| Not this file | JSON field table; copy ops | `requirement-shell-sudoer` · `requirement-shell-config-backup` |

| Includes | Excludes |
|----------|----------|
| print-sudoers; generate; submit; install-script; remove draft | Writing `/etc/sudoers.d` as Type 0; mkdir inbound |

| Surface | What you open | What for |
|---------|---------------|----------|
| `sshd-cli print-sudoers` | draft | admin review |
| inbound | queued JSON | approval |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Ask for the grant | JSON then queue | `sshd-cli generate-sudoer-request` · `sshd-cli submit-sudoer-request` |
| Install as root | Admin script | `sshd-cli print-sudoers-install-script` then `sudo sh FILE install` |

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Verbs (dual mention — **SSOT is `requirement-shell-sudoer`**)

| Verb | Behavior |
|------|----------|
| `print-sudoers [path]` | Emit fragment; no `/etc` write. Trust tier production or `--allow-test-local` |
| `print-sudoers-install-script [path]` | Write admin script; does not run as root |
| `generate-sudoer-request [path]` | Local JSON grant; not inbound |
| `submit-sudoer-request [file]` | Type 0 compose sudoer-cli into inbound; does not mkdir inbound |
| `remove-project-sudoers [path]` | Delete user draft only |

Samples:

```text
sshd-cli print-sudoers
sshd-cli print-sudoers --allow-test-local "$HOME/.config/sshd-cli/sudoers.fragment-$(id -un)"
sshd-cli generate-sudoer-request
sshd-cli submit-sudoer-request
sshd-cli print-sudoers-install-script
sshd-cli remove-project-sudoers
```

### 2.2 Trust tier

production = readable+executable `{{GLOBAL_BIN}}/sshd-cli`. test_local = only `{{USER_BIN}}`. unmanaged = neither. Non-production emit **MUST** fail closed unless `--allow-test-local` or `ALLOW_TEST_LOCAL_SUDOERS=1`.

### 2.3 Paths

| Kind | Path |
|------|------|
| Installed fragment | `/etc/sudoers.d/sshd-cli-{{username}}` |
| Draft | `{{HOME}}/.config/sshd-cli/sudoers.fragment-{{username}}` |
| Local JSON | `{{HOME}}/.config/sshd-cli/sudoer-request-{{username}}.json` |
| Inbound | `/var/sudoer-cli/sudoer-request` (must already exist) |

Type 0 **MUST NOT** write `/etc`. **MUST NOT** mkdir inbound.

### 2.4 Implementation Notes (this project)

**SSOT:** `requirement-shell-sudoer`. Handlers listed there. Tests **TP-CFG-06** · **TP-CFG-07**.

## Under command line for normal user only

On Termux / Git Bash / Windows cmd these verbs **MUST** fail closed and the TTY menu **MUST** omit the sudoers row. **This requirement:** no sudoers workflow on that class.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: Type 0 never writes `/etc`.  
- **Intentional**: submit is compose, not visudo.  
- **Anti-fragile**: `--allow-test-local` for CI.  
- **Over-protect**: per-user fragment suffix.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Write `/etc/sudoers.d` from Type 0.  
2. Mkdir inbound.  
3. Treat local `~/.local/bin` as production elev.

## 5. Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CFG-06** | `tests/test_config_backup.sh` | have |
| **TP-CFG-07** | `tests/test_config_backup.sh` | have |

**Matrix:** `docs/reviews/requirement-test-matrix.md`  
**Map:** `docs/reviews/test-plan.md`.

## 6. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry |
| `docs/requirements/requirement-shell-sudoer.md` | **SSOT** — sudoer verbs / JSON / wrap |
| `docs/requirements/requirement-shell-cli-interface.md` | Dual mention |
| `./sshd-cli` | Ship unit |

**Last Updated**: 2026-09-11  
**Owner**: sshd-cli project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; CIAO (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
