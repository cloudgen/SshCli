**file**: docs/requirements/requirement-sudoer-json-file.md  
**Status**: Retired (Python generation 2.0.0. The live ship unit is the SshCli package. This file records the /bin/sh ship unit through 1.35.1. Where it disagrees with requirement-domain-sshd 1.28.0 or an Active requirement-python-*.md / requirement-runtime-prerequisites.md file, those win.) Was  (Version 1.0.0)  
**Area**: privilege  
**Key**: `requirement-sudoer-json-file`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement **points** at `requirement-shell-sudoer` for the JSON sudoer file body (one grant, verb `backup-config`) and the text dual. Workflow (print/generate/submit) also lives there. Do **not** duplicate emit samples here.

### 1.1 Human-facing

**In one sentence:** the JSON file you generate says this login may run `/usr/local/bin/sshd-cli backup-config` as root with no password — not `cp`, not `chmod`.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Write a grant you can read | `sshd-cli generate-sudoer-request` |
| The other role | sudoer-adm approves the queued JSON | inbound `/var/sudoer-cli/sudoer-request` |
| Not this file | How backup-config copies the file | `requirement-shell-config-backup` |

| Includes | Excludes |
|----------|----------|
| Compact JSON; `args: ["backup-config"]`; NOPASSWD | OS-tool paths; `restore-config`; extra argv |

| Surface | What you open | What for |
|---------|---------------|----------|
| generated JSON | grant body | review then submit |
| sudoers(5) dual | fragment text | admin install |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Make a grant | One command: backup-config | `sshd-cli generate-sudoer-request` |

## 2. Core Rules / Requirements (Mandatory)

1. Grant **MUST** name only `sshd-cli` at `{{GLOBAL_BIN}}/sshd-cli`.  
2. `commands[].args` **MUST** be exactly `["backup-config"]` (verb-only; no `*`).  
3. `commands[].runas` **MUST** be `root`; tags **MUST** include `NOPASSWD`.  
4. **MUST NOT** allowlist `cp`, `mkdir`, `chmod`, `chown`, `tar`, `rm`, shells.  
5. Single grant: **MAY** omit `kind`. **MUST NOT** label this deposit `login-hook-elev`.  
6. Filename grammar for queued requests:

```text
sudoer-{{YYYYMMDD}}-sshd-cli-{{username}}-{{action}}-{{n}}.json
```

**Worked sample basename (add):** `sudoer-20260911-sshd-cli-<id -un>-add-1.json`

**Complete sample JSON grant (add):**

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

**Equivalent text dual:**

```text
<id -un> ALL=(root) NOPASSWD: /usr/local/bin/sshd-cli backup-config
```

### 2.1 Implementation Notes (this project)

**SSOT:** `requirement-shell-sudoer` §2.2–2.6. Emit: `sshd_sudoers_json_text_compact` / `sshd_sudoers_fragment_text`. Tests **TP-CFG-06** · **TP-CFG-07**.

## Under command line for normal user only

On Termux / Git Bash / Windows cmd, generate/submit/print-sudoers **MUST** fail closed (same as backup-config). **This requirement:** no JSON grant on that class.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: refuse OS-tool grants.  
- **Intentional**: one verb.  
- **Anti-fragile**: compact JSON for sudoer-cli convert.  
- **Over-protect**: verify `"backup-config"` before submit.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Add `cp`/`mkdir`/`chmod` to the grant.  
2. Write `backup-config *`.  
3. Grant `sync-config` (Type 0; no sudo).

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
| `docs/requirements/requirement-shell-sudoer.md` | **SSOT** — JSON + workflow + wrap |
| `docs/requirements/requirement-shell-config-backup.md` | Ops (depends on sudoer) |
| `./sshd-cli` | Ship unit |

**Last Updated**: 2026-09-11  
**Owner**: sshd-cli project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; CIAO (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
