**file**: docs/requirements/requirement-shell-modular-function-design.md  
**Status**: Retired (Python generation 2.0.0. The live ship unit is the SshCli package. This file records the /bin/sh ship unit through 1.35.1. Where it disagrees with requirement-domain-sshd 1.28.0 or an Active requirement-python-*.md / requirement-runtime-prerequisites.md file, those win.) Was  (Version 1.1.4)  
**Philosophy**: CIAO / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered)

## 1. Purpose

This requirement is the **project Single Source of Truth** for **modular function organization** of the sshd-cli POSIX shell CLI.

It defines modular function organization for a **monolithic yet modular** single-file shell tool that remains `curl | sh` compatible.

**Scope:** Function prefixes, documentation headers, Protection Zones, single-file modularity, SSOT ownership by prefix, surgical change rules.  
**Out of scope (cited, not re-owned):** Command surface (`requirement-shell-cli-interface.md`); self-management behavior (`requirement-shell-self-management.md`); idempotency matrix (`requirement-shell-idempotency.md`); full POSIX coding style beyond modular structure.

**Core idea:** Modularity is achieved through **clear function boundaries, consistent prefixes, and full CIAO documentation** — **not** by splitting the main CLI into multiple shipped files.

### 1.1 Human-facing

**In one sentence:** People still install **one file** (`./sshd-cli`); inside that file, functions stay in labeled families (`out_` print, `inst_` install, `app_` menu, `prompt_` questions) so a change to help does not rewrite download.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Maintainer editing one family | Change `app_help`, leave `inst_perform_install` |
| The other role | The `curl \| sh` user who needs a **single** downloadable file | One ship unit at repo root |
| Not this file | What each command **does** (CLI / lifecycle / output peers) | Prefix table here; behavior tables elsewhere |

| Includes | Excludes |
|----------|----------|
| Prefixes, headers, “do not simplify” zones, surgical edits | Splitting the shipped CLI into many files |
| `inst_maybe_install` as an `inst_` helper | Re-owning Case A quiet/json law (zero-arguments + interactive peers) |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./sshd-cli` | The one program file | Function families |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Change a message | Edit an `out_*` helper, not a raw `echo` in install. | Open `./sshd-cli`, find `out_` |
| Change first-install ask | Edit `inst_maybe_install` / `prompt_yes_no`, not `app_help`. | Same file; different prefix |

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Overall architecture (portable)

CIAO-Lite shell CLIs distributed as one-liners **MUST** use:

| Rule | Meaning |
|------|---------|
| **Single executable** | One primary script file for the installable CLI (required for `curl \| sh`) |
| **Logical modules** | Functions grouped by **strict prefixes**, not by separate runtime files |
| **Documented units** | Every public helper carries a defensive header and safe defaults |
| **Requirements extract policy** | Durable rules live in `requirement-*.md`; code comments encode intent and Protection Zones |

Optional multi-file layout under `src/` for future authoring **MAY** exist only if a build or pack step still produces **one** installable artifact and this requirement is updated. Until then, `./sshd-cli` remains the single shipped script.

### 2.2 Official function prefix table (mandatory)

**All functions MUST use a defined prefix.** Bare names (`main`, `install`, `help`, `about`, `helper`) are forbidden.

| Prefix | Category | Purpose | Example functions |
|--------|----------|---------|-------------------|
| `out_` | Output system | All user-facing and machine-readable output | `out_text`, `out_info`, `out_success`, `out_json`, `out_die` |
| `inst_` | Installation & self-management | Install, self-update, self-uninstall, install detect | `inst_perform_install`, `inst_self_update`, `inst_is_installed` |
| `util_` | General utilities | Reusable helpers (backup, path resolve, storage) | `util_backup`, `util_resolve_storage`, `util_get_install_bin_path` |
| `app_` | General app CLI surface (product-neutral) | Entry, dispatch, about/help/version presentation, numbered menu | `app_main`, `app_about`, `app_help`, `app_version`, `app_cmd_menu` |
| `ver_` | Version comparison | Semantic version handling | `ver_gt`, `ver_check` |
| `path_` | Shell PATH & environment | PATH manipulation and shell config (bashrc/profile) | `path_add_shell`, `path_add_bashrc`, `path_ensure_profile` |
| `prompt_` | Interactive prompts | TTY-safe confirmations and questions | `prompt_yes_no`, `prompt_ask` |
| `sshd_` | Domain / product business logic | OpenSSH sshd verbs and Termux detect | `sshd_cmd_start`, `sshd_pkg_ensure`, `sshd_is_termux` |

**`app_*` vs domain prefix:**

- **`app_*`** — cross-cutting CLI surface every shell CLI needs (main, help, about, version routing, numbered menu `app_cmd_menu*`).  
- **`sshd_*`** — domain business logic only (OpenSSH sshd + Termux detect).  
- Do **not** put domain ops under `app_*`.  
- Do **not** put generic about/help/main under the domain prefix unless a specialized requirement explicitly requires product-prefixed aliases.

**Specializee note:** When grafting legacy domain DNA onto this bootstrap, prefer a domain prefix for new handlers. Temporary **output shims** (`info` → `out_info`, …) are allowed only as bridges to `out_*` SSOT (`requirement-shell-output-requirements.md`) — do not invent a durable second output family.

**Strict naming rules:**

1. Every new function **must** use one of the defined prefixes (or extend this table in the same change).  
2. Internal helpers **must** still carry the correct category prefix.  
3. Names **must** be descriptive but concise.  
4. Adding a new category **must** update this requirement (and any related live shell requirements) in the same work item.  
5. Prefer small, single-purpose functions over mega-functions that mix output, install, and domain logic.

### 2.3 Function documentation standards (mandatory)

Every non-trivial function **MUST** include a defensive header of this shape (trivial one-line wrappers may inherit documentation from their parent SSOT function, but still require the correct prefix).

#### 2.3.1 Product-source documentation authority

Optional `ALIGNMENT` / `See` / “fully synchronized with” lines in **product source** (`./sshd-cli`) **MUST** cite only **live** `docs/requirements/requirement-*.md` paths that exist on disk and appear in `docs/requirements/index.md`.

| Allowed in product source comments | Forbidden in product source comments |
|------------------------------------|--------------------------------------|
| Live `requirement-shell-*.md` (and other live `requirement-*.md` registered in `index.md`) | Non-requirement paths under `docs/` as product-law authority |
| Short incident IDs for lessons (optional; no required path) | Invented or stale `requirement-*.md` names |
| | Harness / template / skill filenames as ALIGNMENT targets |

Product-source law is only the live registry under `docs/requirements/`. Local workspace material outside this folder is not product-source authority (see INC-20260712-002).

```sh
# =============================================================================
# function_name() - Short one-line purpose
# =============================================================================
#
# GENERAL PURPOSE:
# Clear explanation of what this function does and why it exists.
#
# CIAO PRINCIPLES APPLIED:
# - Caution (Principle 1): ...
# - Intentional (Principle 2): ...
# - Anti-fragile (Principle 3): ...
# - Over-protect (Principle 4 O + Principle 20): ...
#
# !!! DO NOT MODIFY OR SIMPLIFY THIS FUNCTION !!!
# Designed to be reusable in other CIAO-Lite projects.
#
# Lessons Learned (CIAO Reflection):
# [Date]: [Short note when fixing regressions or improving defensive comments]
#
# Last reviewed: YYYY-MM-DD
# =============================================================================

function_name() {
    # --- Safe Variable Defaults ---
    : "${VAR:=default}"

    # Main logic...
}
```

**Mandatory elements for critical / reusable helpers:**

| Element | Rule |
|---------|------|
| GENERAL PURPOSE | States objective and why the function exists |
| CIAO principles | Filled meaningfully for non-trivial logic |
| DO NOT MODIFY / Protection intent | Present on reusable and security-sensitive helpers |
| Safe variable defaults | `: "${VAR:=default}"` at top of body for globals the function relies on |
| Lessons Learned | Add when fixing regressions; do not delete history |

### 2.4 Ownership and SSOT by prefix (portable)

| Concern | Owning prefix / entry | Rule |
|---------|----------------------|------|
| User-facing output | `out_*` | No raw user messages outside `out_*` |
| Install + CLI lifecycle | `inst_*` | One install orchestrator; self-update reuses it |
| Version compare / remote check | `ver_*` | Pure compare helpers stay portable |
| PATH / shell profile | `path_*` | Duplicate-safe append; create `~/.bashrc` if missing; create `~/.profile` if absent (never overwrite). **Bodies:** `requirement-shell-path-and-shell-support` |
| CLI entry / dispatch | `app_*` | Single dispatcher; no second parallel main |
| Interactive confirm | `prompt_*` | Single source for yes/no; non-interactive safe behavior |
| Backup / storage resolve | `util_*` | Reusable; no domain-specific hardcodes as universal law |
| Domain product ops | `sshd_*` | OpenSSH sshd verbs and Termux-ish detect |

### 2.5 Surgical change and reuse rules (portable)

1. **Respect existing working functions** — high bar before rewriting protected helpers.  
2. **Surgical edits** — change the smallest function that fulfills the request; do not rewrite the whole script.  
3. **No merge for “cleanliness”** — do not collapse prefix boundaries or remove Protection Zones.  
4. **Reusable helpers** marked DO NOT MODIFY remain sacred unless the user explicitly redesigns them.  
5. **Duplicates** — if two functions with the same name exist, that is a defect; keep one authoritative definition.

### 2.6 Implementation Notes (this project)

| Item | Value for sshd-cli |
|------|------------------------|
| **Product / binary** | `sshd-cli` (`APP_NAME`) |
| **Single shipped script** | Repo root `./sshd-cli` (`#!/bin/sh`); authoring copy `src/sshd-cli` (same bytes) |
| **`src/` directory** | Holds the same single-file ship unit (`src/sshd-cli`); **not** a multi-file runtime layout |
| **Domain prefix `sshd_*`** | Domain ops: `sshd_cmd_*` (OpenSSH verbs), `sshd_resolve`, `sshd_pkg_ensure`. Numbered menu handlers are `app_cmd_menu*`. |
| **Bootstrap** | Direct execution when `${0##*/}` is `sshd-cli` or `sshd-cli.sh` → `app_main "$@"` |

#### Live prefix inventory (authoritative categories)

| Prefix | Live examples in `./sshd-cli` |
|--------|----------------------------------|
| `out_` | `out_text`, `out_success`, `out_info`, `out_warn`, `out_error`, `out_die`, `out_plain`, `out_msg_n`, `out_empty_line`, `out_double_line`, `out_json`, `out_json_error` |
| `inst_` | `inst_perform_install`, `inst_self_install`, `inst_self_install_copy_from_script`, `inst_resolve_self_script`, `inst_argv0_is_shell_interpreter`, `inst_cli_dest_mode`, `inst_ensure_companion`, `inst_perform_install_prepare_target`, `inst_perform_install_download_with_checksum`, `inst_perform_install_download_without_checksum`, `inst_perform_install_atomic_install`, `inst_maybe_install`, `inst_self_update`, `inst_self_uninstall` (+ determine_bin / confirm_and_remove / cleanup_path), `inst_is_installed`, `inst_get_version` |
| `ver_` | `ver_gt`, `ver_check` |
| `path_` | `path_add_bashrc`, `path_ensure_profile`, `path_add_zshrc`, `path_add_fish`, `path_add_shell`, `path_rc_test` |
| `util_` | `util_json_escape`, `util_sha256_file`, `util_fetch_remote_version`, `util_get_install_bin_path`, `util_backup`, `util_cache_host_kind`, `util_preferred_cache_dir`, `util_fallback_cache_dir`, `util_fallback2_cache_dir`, `util_cache_try_dir`, `util_resolve_storage` (**wired** from `app_main` / `app_about`; silent tier miss; SSOT: `requirement-shell-cli-storage.md`), `util_resolve_persistent_storage` (preferred-remote leaf), `util_sudo` (**backup-config** re-exec; SSOT: `requirement-shell-sudo-command.md`), `util_get_current_shell` |
| `prompt_` | `prompt_ask`, `prompt_yes_no` |
| `app_` | `app_about`, `app_version` (dispatcher routes `version` here), `app_help`, `app_main`, `app_cmd_menu`, `app_cmd_menu_client`, `app_cmd_menu_server`, `app_cmd_menu_self`, `app_cmd_menu_language`, `app_lang_load`, `app_lang_save`, `app_menu_text`. The translated strings, worked samples, and translation tables stay in `requirement-shell-cli-language`. This row only names the helpers. |
| `sshd_` | `sshd_is_termux`, `sshd_is_git_bash`, `sshd_is_windows_cmd`, `sshd_is_normal_user_only_cli`, `sshd_os_name`, `sshd_menu_show_daemon_rows`, `sshd_is_systemd_host`, `sshd_systemd_unit`, `sshd_systemd_is_active`, `sshd_systemd_main_pid`, `sshd_resolve`, `sshd_pkg_ensure`, `sshd_start_after_install`, `sshd_try_start_linux`, `sshd_ifconfig_ipv4`, `sshd_lan_ipv4`, `sshd_connect_cmd`, `sshd_cmd_status` / `start` / `stop` / `restart` / `port` / `config` / `host_keys` / `auth_keys` |

#### Structural notes (implementation status)

| Issue | Status |
|-------|--------|
| Duplicate `inst_perform_install_prepare_target` | **Fixed** — single definition (2026-07-12) |
| Nested `get_current_shell` | **Fixed** — top-level `util_get_current_shell` |
| Thin wrappers (`out_success`, …) | **Allowed** — delegate to `out_text` SSOT |
| Partial headers on some helpers | Improve when those helpers are touched (ongoing surgical standard) |

#### New function checklist (this project)

When adding a function to `./sshd-cli`:

1. Choose the correct prefix from §2.2 / this inventory.  
2. Add the defensive header (full for non-trivial logic).  
3. Add safe variable defaults.  
4. Route user messages only through `out_*`.  
5. Do not introduce a second install or update path.  
6. Update this requirement’s inventory table if a **new** prefix category is introduced.  
7. Cite `requirement-shell-modular-function-design` in the change summary.

### 2.7 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): Small, prefixed units with safe defaults reduce accidental cross-cutting edits.  
- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): Prefixes encode ownership; GENERAL PURPOSE encodes why.  
- **CIAO Principle 3 – Anti-fragile** (https://github.com/cloudgen/ciao): Focused functions can be reviewed and reused; single file survives minimal environments.  
- **CIAO Principle 6 – Single Point of Entry** (https://github.com/cloudgen/ciao): `app_main` is the dispatcher SSOT.  
- **CIAO Principle 7 – General Purpose Requirement** (https://github.com/cloudgen/ciao): Public helpers document GENERAL PURPOSE.  
- **CIAO Principle 8 – Reusable Function Protection** (https://github.com/cloudgen/ciao): DO NOT MODIFY on reusable helpers.  
- **CIAO Principle 4 (O) / Principle 20 – Over-protect / Protect Against AI & Human Modification** (https://github.com/cloudgen/ciao): Protection Zones and prefix table defend against AI “cleanup” regressions.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Prefer additive helpers over rewriting protected orchestrators.  
- **Intentional:** Prefix = category; headers = intent; no mystery bare functions.  
- **Anti-fragile:** Monolithic ship unit + modular internals; works under `curl | sh`.  
- **Over-protect:** Never strip Protection Zones or merge categories for aesthetics.  
- **Simplicity but Safety:** Simplify only non-protected, non-security paths; keep intentional verbosity in headers.  
- **Surgical changes:** Edit the owning function; do not reformat the whole file casually.  
- **SSOT:** Output, install, version compare, and dispatch each have one owning family.

---

## Under command line for normal user only

When the ship unit detects a **command line for normal user only** (Termux, Git Bash, Windows cmd, or the same class):

| MUST | MUST NOT |
|------|----------|
| Keep **normal user privilege** (Type 0) only | Implement or enable **admin privilege** (Type 1) or **dedicated system user privilege** (Type 2) |
| Document Type 1 **unused** and Type 2 **unused** | In-tool `sudo`; wrap `apt` / `dnf` / `yum`; create a dedicated system user |
| Termux: named `pkg` as this login remains Type 0 | Recommend `sudo curl \| sh` as the install path |
| Git Bash / Windows cmd: same privilege ceiling | Invoke Termux `pkg` because Git Bash or Windows cmd was detected |

Helpers (this product): `sshd_is_termux`, `sshd_is_git_bash`, `sshd_is_windows_cmd`, `sshd_is_normal_user_only_cli`. Dual mention: `requirement-shell-cli-interface` · `requirement-shell-termux-ish`.

**This requirement:** class-detect helpers live under `sshd_*`; **MUST NOT** add a `util_sudo` family on that class.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Merge functions or remove the prefix-based grouping system.  
2. Delete or weaken Protection Zones and `!!! DO NOT MODIFY OR SIMPLIFY THIS FUNCTION !!!` comments.  
3. Remove or hollow out GENERAL PURPOSE / CIAO PRINCIPLES APPLIED sections on protected helpers.  
4. Refactor the shipped CLI into multiple runtime files in a way that breaks `curl | sh` single-artifact install without an explicit redesign requirement.  
5. Violate the official function prefix table (including inventing bare `main`/`install`/`help`).  
6. Put domain product logic under `app_*`, or generic CLI surface under a domain-only prefix without an explicit requirement change.  
7. Remove or weaken safe variable defaults at the top of functions.  
8. Introduce a second parallel dispatcher or a second install/update orchestrator “for clarity.”  
9. Leave duplicate function definitions with the same name as intentional design.  
10. Cite `template-*.md` or `skill-*.md` in product source as behavioral authority, or invent missing `requirement-*.md` paths in headers (§2.3.1).  
11. Strip the **Under command line for normal user only** section, or add a sudo-wrap prefix family on that class.

**Modularity is prefixes + documentation + boundaries — not multi-file sprawl for the installable artifact.**

---

## 5. Definition of done (shell modular function design)

A modular-structure change for sshd-cli is **not done** if any of the following fail:

1. Every new function uses an approved prefix from this requirement.  
2. Critical helpers retain defensive headers and Protection intent.  
3. The ship unit remains a single `curl | sh`-compatible script unless redesign is approved.  
4. Output remains under `out_*`; install lifecycle under `inst_*`; dispatch under `app_*`.  
5. No bare unprefixed public functions introduced.  
6. Inventory / this requirement updated when a new prefix category is added.  
7. Duplicate same-name function definitions are not introduced (and known duplicates are scheduled for removal when touched).  
8. Changes cite `requirement-shell-modular-function-design`.  
9. Product source headers do not cite non-requirement docs as authority; any ALIGNMENT paths resolve under `docs/requirements/`.

---

## 6. Related artifacts

| Artifact | Role |
|----------|------|
| `docs/requirements/requirement-shell-cli-interface.md` | Command surface owned by `app_*` dispatch |
| `docs/requirements/requirement-shell-self-management.md` | Lifecycle owned by `inst_*` / `ver_*` |
| `docs/requirements/requirement-shell-idempotency.md` | Re-run safety inside ensure helpers |
| `docs/requirements/requirement-shell-output-requirements.md` | `out_*` ownership |
| `docs/requirements/index.md` | Registry SSOT |
| `./sshd-cli` | Implementation under modular design rules |

---

**Last Updated**: 2026-09-28 (1.1.4 language samples and translation tables stay on the language requirement. 1.1.3 menu language helpers are `app_lang_load`, `app_lang_save`, `app_menu_text`, `app_cmd_menu_language`. 1.1.2 numbered menu handlers are `app_cmd_menu*`)  
**Owner**: sshd-cli project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; CIAO Principles 1, 2, 3, 6, 7, 8, 4, 20 (v2.10.2) (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
