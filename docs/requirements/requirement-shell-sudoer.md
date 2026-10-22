**file**: docs/requirements/requirement-shell-sudoer.md  
**Status**: Retired (Python generation 2.0.0. The live ship unit is the SshCli package. This file records the /bin/sh ship unit through 1.35.1. Where it disagrees with requirement-domain-sshd 1.28.0 or an Active requirement-python-*.md / requirement-runtime-prerequisites.md file, those win.) Was  (Version 1.0.0)  
**Area**: shell  
**Key**: `requirement-shell-sudoer`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the Single Source of Truth for **all sudoer-related features** on sshd-cli: JSON grant body, sudoers(5) text dual, Type 0 print/generate/submit/remove workflow, and the one in-tool wrap `util_sudo`. Type 1 on this product is the approved passwordless `sudo sshd-cli backup-config` grant only. Type 2 is unused.

Copy/deposit of `~/.ssh/config` is **not** this file — that is `requirement-shell-config-backup`, which **depends on** this requirement.

### 1.1 Human-facing

**In one sentence:** you generate a JSON grant so sudoer-adm can let this login run `/usr/local/bin/sshd-cli backup-config` as root with no password — not `cp`, not a folder archive.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Write and queue the grant | `sshd-cli generate-sudoer-request` then `sshd-cli submit-sudoer-request` |
| The other role | sudoer-adm or a root login | approve inbound, or install the printed fragment |
| Not this file | How the file is copied | `requirement-shell-config-backup` |

| Includes | Excludes |
|----------|----------|
| print-sudoers; generate; submit; install-script; remove draft; `util_sudo`; JSON `args: ["backup-config"]` | Writing `/etc` as a normal login; mkdir inbound; `sync-config` in the grant; OS-tool paths |

| Surface | What you open | What for |
|---------|---------------|----------|
| `sshd-cli generate-sudoer-request` | command | local JSON |
| inbound | queued JSON | approval |
| `util_sudo` | wrap | only sudo call site |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Ask for the grant | JSON then queue | `sshd-cli generate-sudoer-request` · `sshd-cli submit-sudoer-request` |
| Install as root | Admin script | `sshd-cli print-sudoers-install-script` then `sudo sh FILE install` |

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Verbs (dual mention with `requirement-shell-cli-interface`)

| Verb | Behavior |
|------|----------|
| `print-sudoers [path]` | Emit fragment; no `/etc` write. Production or `--allow-test-local` |
| `print-sudoers-install-script [path]` | Write admin script; does not run as root |
| `generate-sudoer-request [path]` | Local JSON grant; not inbound |
| `submit-sudoer-request [file]` | Type 0 compose into inbound; does not mkdir inbound |
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

### 2.2 Grant

1. Grant **MUST** name only `{{GLOBAL_BIN}}/sshd-cli`.  
2. `commands[].args` **MUST** be exactly `["backup-config"]` (verb-only; no `*`).  
3. `runas` **MUST** be `root`; tags **MUST** include `NOPASSWD`.  
4. **MUST NOT** allowlist `cp`, `mkdir`, `chmod`, `chown`, `tar`, `rm`, shells.  
5. Single grant: **MAY** omit `kind`. **MUST NOT** label this deposit `login-hook-elev`.  
6. **MUST NOT** grant `sync-config` (Type 0; no sudo).

Filename grammar:

```text
sudoer-{{YYYYMMDD}}-sshd-cli-{{username}}-{{action}}-{{n}}.json
```

Worked sample basename (add): `sudoer-20260912-sshd-cli-<id -un>-add-1.json`

Complete sample JSON (add):

```json
{
  "schema_version": 1,
  "purpose": "Allow <id -un> to run sshd-cli backup-config as root.",
  "username": "<id -un>",
  "service": "sshd-cli",
  "action": "add",
  "commands": [
    {
      "runas": "root",
      "tags": ["NOPASSWD"],
      "path": "/usr/local/bin/sshd-cli",
      "args": ["backup-config"]
    }
  ]
}
```

Equivalent text dual:

```text
<id -un> ALL=(root) NOPASSWD: /usr/local/bin/sshd-cli backup-config
```

### 2.3 Paths and trust tier

| Kind | Path |
|------|------|
| Installed fragment | `/etc/sudoers.d/sshd-cli-{{username}}` |
| Draft | `{{HOME}}/.config/sshd-cli/sudoers.fragment-{{username}}` |
| Local JSON | `{{HOME}}/.config/sshd-cli/sudoer-request-{{username}}.json` |
| Inbound | `/var/sudoer-cli/sudoer-request` (must already exist) |

production = readable+executable `{{GLOBAL_BIN}}/sshd-cli`. test_local = only `{{USER_BIN}}`. Non-production emit **MUST** fail closed unless `--allow-test-local` or `ALLOW_TEST_LOCAL_SUDOERS=1`. Type 0 **MUST NOT** write `/etc`. **MUST NOT** mkdir inbound.

### 2.4 Wrap + sudo allow table (studied)

1. **MUST** keep one wrap `util_sudo`. **MUST NOT** scatter raw `sudo`.  
2. Already-root **MUST** run argv without sudo.  
3. Non-root production dest **MUST** use `sudo -n` matching the table.  
4. **MUST NOT** probe `sudo true` / `sudo mkdir` / `sudo cp`.

| Binary | Verb | Operand | Fragment dest | NOPASSWD? | This wrap? | Study evidence |
|--------|------|---------|---------------|-----------|------------|----------------|
| `{{GLOBAL_BIN}}/sshd-cli` | `backup-config` | none (verb-only) | `/etc/sudoers.d/sshd-cli-{{username}}` | yes | yes | this product `print-sudoers` emit |

### 2.5 Consumer

`requirement-shell-config-backup` **MUST** call `util_sudo` and this grant. **MUST NOT** invent a second wrap.

### 2.6 Implementation Notes (this project)

Handlers: `sshd_cmd_print_sudoers` · `sshd_cmd_generate_sudoer_request` · `sshd_cmd_submit_sudoer_request` · `sshd_cmd_print_sudoers_install_script` · `sshd_cmd_remove_project_sudoers` · `sshd_sudoers_json_text_compact` · `sshd_sudoers_fragment_text` · `util_sudo`. Call site of wrap: `sshd_cmd_backup_config`. Tests **TP-CFG-06** · **TP-CFG-07** · **TP-CFG-04/05/09**.

### 2.7 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 9 – Type 0/1/2** (https://github.com/cloudgen/ciao): Type 0 emit; Type 1 is the approved product command.  
- **CIAO Principle 10 – Least privilege** (https://github.com/cloudgen/ciao): one verb; no OS tools.

## Under command line for normal user only

On Termux / Git Bash / Windows cmd these verbs **MUST** fail closed and the TTY menu **MUST** omit the sudoers row. `util_sudo` **MUST NOT** run. **This requirement:** no sudoer workflow on that class.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: Type 0 never writes `/etc`; refuse OS-tool grants.  
- **Intentional**: one wrap; one verb.  
- **Anti-fragile**: `--allow-test-local` for CI.  
- **Over-protect**: per-user fragment suffix; verb-only argv.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Add `cp`/`mkdir`/`chmod` to the grant.  
2. Write `backup-config *`.  
3. Grant `sync-config`.  
4. Write `/etc/sudoers.d` from Type 0.  
5. Mkdir inbound.  
6. Guess dest as `/etc/{{username}}/sshd-cli` when print-sudoers says `/etc/sudoers.d/sshd-cli-{{username}}`.  
7. Probe `sudo true`.  
8. Split a second sudoer SSOT on the config-backup file.

## 5. Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CFG-06** | `tests/test_config_backup.sh` | have |
| **TP-CFG-07** | `tests/test_config_backup.sh` | have |
| **TP-CFG-04** · **TP-CFG-05** · **TP-CFG-09** | `tests/test_config_backup.sh` | have |

**Matrix:** `docs/reviews/requirement-test-matrix.md`  
**Map:** `docs/reviews/test-plan.md`.

## 6. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry |
| `docs/requirements/requirement-shell-config-backup.md` | Deposit consumer (depends on this file) |
| `docs/requirements/requirement-shell-cli-interface.md` | Dual mention |
| `docs/requirements/requirement-shell-sudo-command.md` | Points here (wrap slice) |
| `docs/requirements/requirement-sudoer-json-file.md` | Points here (JSON slice) |
| `docs/requirements/requirement-three-layer-privilege-model.md` | Type 0/1/2; sudoer verbs point here |
| `./sshd-cli` | Ship unit |

**Last Updated**: 2026-09-12  
**Owner**: sshd-cli project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; CIAO (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
