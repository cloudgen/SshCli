**file**: docs/requirements/requirement-shell-interactive-vs-noninteractive.md  
**Status**: Retired (Python generation 2.0.0. The live ship unit is the SshCli package. This file records the /bin/sh ship unit through 1.35.1. Where it disagrees with requirement-domain-sshd 1.28.0 or an Active requirement-python-*.md / requirement-runtime-prerequisites.md file, those win.) Was  (Version 1.2.6)  
**Philosophy**: CIAO / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered)

## 1. Purpose

This requirement is the **project Single Source of Truth** for how the sshd-cli **POSIX shell CLI** behaves in **interactive** (human + TTY) versus **non-interactive** (automation, `curl | sh`, CI/CD, pipes, `--json` / often `--quiet`) environments.

It defines when `sshd-cli` may **ask** (real terminal) versus when it **must not wait** (pipe, CI, `--json` / `--quiet`). Mode lives in shell globals (`TTY`, `QUIET`, `JSON`) and `prompt_*` — not a second checker in every helper.

**Scope:** Mode detection signals, prompt policy, auto-install vs confirm, force/skip rules, interaction with quiet/json/debug and output SSOT.  
**Out of scope (cited, not re-owned):** Full command catalog (`requirement-shell-cli-interface.md`); output function catalog (`requirement-shell-output-requirements.md`); self-update integrity (`requirement-shell-self-management.md`); idempotency matrix (`requirement-shell-idempotency.md`).

### 1.1 Human-facing

**In one sentence:** On a real terminal the tool may **ask** before first install or uninstall; under a pipe, CI, `--quiet`, or `--json` it **must never wait for a key** — first install still **places** the program; uninstall without `--force` **must stop**.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | A person at a terminal, or a script / `curl \| sh` with nobody to answer | `sshd-cli` on a TTY vs `curl … \| sh` |
| The other role | Machine flags (`--json`, `--quiet`) and `--force` for deliberate uninstall | `sshd-cli --json version` · `sshd-cli --force self-uninstall` |
| Not this file | Empty-argv case table (peer); `out_*` printers; command catalog | `requirement-shell-cli-zero-arguments.md` |

| Includes | Excludes |
|----------|----------|
| When to ask vs auto-install vs refuse uninstall | Inventing a second “are we interactive?” check inside every helper |
| `prompt_yes_no` / `prompt_ask` as the only confirm/read path | Raw `read` in command bodies |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./sshd-cli` | Program file | `TTY` at startup; `prompt_*`; `inst_maybe_install` |
| `sshd-cli --quiet` / `--json` | Flags | No prompts; first install must still place |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Install from a pipe | Nobody can type yes. The tool **places** the program and prints a short auto-install note. | `curl -fsSL …/sshd-cli \| /bin/sh` |
| First install on a real terminal | No arguments opens the numbered list. To place the program, type `install`. | `sshd-cli` (no args, terminal) · `sshd-cli install` |
| Uninstall without `--force` off a terminal | The tool **must not** delete. JSON says confirm is required. | `sshd-cli --json self-uninstall` |

Jargon: a **TTY** here means “this login has a real terminal on stdin and stdout.” Measure that **once** at startup (`TTY`); helpers **read `TTY`**.

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Definitions (portable)

| Mode | Definition |
|------|------------|
| **Interactive** | A human is driving the tool with a usable terminal (**TTY**). Confirmations, colors, and onboarding prompts are allowed when not overridden by machine flags. |
| **Non-interactive** | No human is available to answer prompts: pipes, CI/CD, `curl \| sh`, config management, Docker build, scripts, or machine flags such as `--json` (and often `--quiet`). The tool **must never hang waiting for input** and must apply **documented safe automatic defaults**. |

### 2.2 Detection (mode SSOT for shell)

For shell CLIs without a separate Config class, the **mode SSOT** is the **global flag / TTY block** at script top + values set by the dispatcher after parsing:

| Signal | Variable / check | Meaning |
|--------|------------------|---------|
| TTY | `TTY=1` when stdin and stdout are terminals. Measure `[ -t 0 ]` and `[ -t 1 ]` **once in the main process, outside functions** (near Config). Helpers **read `TTY`**. **MUST NOT** use a second live `[ -t` inside a function as the sole “may we prompt?” gate. | Interactive UX possible |
| Quiet | `QUIET=1` (`--quiet` / `-q`) | Suppress non-essential human chatter |
| JSON | `JSON=1` (`--json`; implies quiet) | Machine output; no human hang; no human banners |
| Debug | `DEBUG=1` (`--debug`) | Extra stderr diagnostics; suppressed under JSON |
| Force | `FORCE=1` / `FORCE_REINSTALL=1` (`--force`) | Skip confirms / force reinstall / allow policy-gated downgrade |
| Explicit interactive override | `INTERACTIVE=1` (optional env) | Rare override when low-level TTY checks are flaky (prompt_ask only) |

**Rules:**

1. Prompt, color, and hang-sensitive decisions **MUST** respect these globals and/or the shared `prompt_*` helpers—not ad-hoc `read` scattered in domain logic.  
2. After global flags are parsed in `app_main`, subsequent code **MUST** see the updated `QUIET` / `JSON` / `FORCE` / `DEBUG` values.  
3. Do **not** invent a second parallel mode system in individual commands.  
4. Helpers (`prompt_*`, `inst_maybe_install`, `out_*` color) **MUST** consume process `TTY`. Command business logic **MUST** call `prompt_*` instead of re-implementing prompt guards. A `--file` vs stdin probe **MAY** read current `[ -t 0 ]` only when named as a data-source check — **not** as interactive-capability SSOT.

```text
flags + TTY / environment
           │
           ▼
  Global mode SSOT (QUIET / JSON / DEBUG / FORCE / TTY)
           │
     ┌─────┴─────┐
     ▼           ▼
interactive   non-interactive
(human UX)    (no hang, safe defaults)
```

### 2.3 Behavioral differences (portable)

#### 2.3.1 Interactive mode (TTY, not quiet/json)

| Allowed / expected | Notes |
|--------------------|--------|
| Colored / prefixed human output | Via `out_*` when TTY and not quiet/json |
| Helpful messages and about diagnostics | Full human surface |
| Confirmation prompts for destructive actions | Via `prompt_yes_no` unless `--force` |
| Onboarding / install prompt when not installed | When product supports it |
| Value prompts with defaults | Via `prompt_ask` |

#### 2.3.2 Non-interactive mode (automation)

| Required | Forbidden |
|----------|-----------|
| **Never wait** for user input | Bare `read` without mode guards |
| **Safe automatic defaults** documented per command | Assuming someone will type “yes” |
| Suppress or skip prompts under quiet/json | Hanging on confirm in CI |
| Support `--json` purity (output requirement) | Mix human text into JSON stdout |
| Non-zero exit on critical failure | Silent hang that looks like a stuck job |
| Work under `curl \| sh`, Docker, CI | Requiring a full TTY for core ensure ops that claim automation support |

#### 2.3.3 Flag interactions

| Flag / state | Interactive impact |
|--------------|--------------------|
| `--json` | Force quiet-style human suppression; no prompts; structured stdout; errors on stderr |
| `--quiet` | No prompts via `prompt_*`; reduced chatter; errors (and warnings per output requirement) still surface |
| `--force` | Skip uninstall confirm; allow reinstall/downgrade policy paths |
| `--debug` | stderr diagnostics; never block; suppressed under JSON |
| Non-TTY stdin/stdout | Treat as non-interactive for prompts |

### 2.4 Prompt SSOT (portable)

| Helper | Role |
|--------|------|
| `prompt_yes_no` | **Only** yes/no confirmation path for destructive/optional confirms |
| `prompt_ask` | **Only** simple value prompt path with default |
| `out_msg_n` | Prompt fragment without newline (human only) |

**Rules:**

1. Never implement user-visible confirms with raw `printf` + `read` outside `prompt_*`.  
2. Under `JSON=1` or `QUIET=1`, prompts **MUST NOT** block: return default / no / cancel per documented policy.  
3. Without TTY (unless `INTERACTIVE=1` where designed), prompts **MUST NOT** block.  
4. Destructive non-interactive actions that would have required confirm **MUST** either:  
   - require `--force` (fail closed without it), or  
   - document an explicit safe auto-proceed policy (e.g. zero-arg install under pipe).

### 2.5 Implementation Notes (this project)

| Item | Value for sshd-cli |
|------|------------------------|
| **Product / binary** | `sshd-cli` |
| **Implementation** | Repo root `./sshd-cli` |
| **Mode globals** | `TTY`, `QUIET`, `JSON`, `DEBUG`, `FORCE`, `FORCE_REINSTALL` |
| **TTY init** | `[ -t 0 ] && [ -t 1 ] && TTY=1` near config block |
| **Flag parse SSOT** | `app_main` |
| **Prompt SSOT** | `prompt_yes_no`, `prompt_ask` |
| **Output SSOT** | `out_*` (`requirement-shell-output-requirements.md`) |
| **Mode SSOT** | Shell globals + helpers (`TTY` / `QUIET` / `JSON`); not a second checker in every helper |

#### Command-level interactive matrix (normative)

| Command / path | Interactive (TTY, not quiet/json) | Non-interactive / quiet / json |
|----------------|-----------------------------------|--------------------------------|
| Zero-arg, **not** installed | Domain **menu** (`app_cmd_menu`); **no** CLI place | Quiet/json / no TTY: `inst_self_install` (CLI only; copy when `$0` is a script). Payload stays `install`. |
| Zero-arg, **already** installed local or global | Domain **menu** (same as `sshd-cli menu`) | Install-ensure success no-op (“already installed”); **not** help; **not** menu; no re-download without force |
| `install` | Install with human `out_*` messages | No prompt; honor force for reinstall; JSON structured results |
| `self-uninstall` | `prompt_yes_no` unless `--force` | Without force: fail closed with explicit “requires --force” (JSON: `out_json_error` / `confirm_required`); never pretend user cancelled; with `--force`: remove without confirm |
| `self-update` / `version-check` | Human status messages | No prompts; fail loud if `SCRIPT_URL` missing; JSON structured results |
| `about` / `version` / `help` | Human diagnostics / help | Quiet: suppress human; JSON: structured object only |
| Colors | When `TTY=1` and not quiet/json | No color under quiet/json |
| `dns` (no subcommand) | Host names as context (no choice numbers); action menu **1 Edit / 2 Add / 3 Delete / 4 Unset / 9 Exit** (`read` in-shell). Unknown action **MUST** warn and redisplay this menu. Edit/Delete/Unset then numbered Host pick (`0` to leave, not `9`); unknown Host **MUST** warn and redisplay the Host list. Delete confirms with `prompt_yes_no`. Unset then lists currently set extra fields; unknown picker number **MUST** warn and redisplay. `INTERACTIVE=1` allowed when TTY probe is flaky. **MUST NOT** `out_die` solely for a bad TTY numbered choice. | **List only** — never wait. JSON: one `dns_list` object with `@items` |
| `dns show` | Human details (`user` empty → `empty`; empty port → `22`) | Same fields; JSON object; no prompt |
| `dns edit` | Same field walk as after the Edit pick | Fail closed: Next `dns set …` (no hang) |
| `dns delete` | Show details; `prompt_yes_no` unless `--force` | No prompt; delete the stanza; JSON: one `out_success` |
| `dns unset` | Host pick (if no n); then numbered extra-field picker (`0` to leave). dns and ip stay. | Needs n/name **and** a field; no prompt; JSON: one `out_success`. Fail closed if dns/ip requested |
| `dns set` / `dns add` | **MAY** fill missing fields with the same walk when TTY | Operands only; omitted **set** fields unchanged; `""` clears; never prompt |
| `ssh` | Numbered Host pick if no operand; unknown Host **MUST** warn and redisplay. Then **user [default]** (Host User, else this login); then OpenSSH client (`exec` on TTY unless `SSHD_CLI_SSH` is set). `read` in-shell. | Needs `<n\|name>`; no prompt; JSON: one object, **no** session |
| `download` | Host pick if no first operand; then **user [default]** (same as `ssh`); then numbered previous folders for that Host, or type a path (`~/folder` allowed). Out-of-range folder number **MUST** warn and redisplay. Empty folder still fail-closed. | Needs Host **and** folder; no prompt; JSON: one object after the transfer. `~/folder` allowed |
| `upload` | Host pick if no first operand; then **user [default]** (same as `ssh` / `download`); then numbered previous **local** folders for that Host, or type a local path (`~/folder` is this login). Out-of-range folder number **MUST** warn and redisplay. Empty folder still fail-closed. | Needs Host **and** local folder; no prompt; JSON: one object after the transfer. Local `~/folder` allowed; folder **MUST** exist as a directory |
| `menu` / sudoers submenu | Numbered list. Unknown / hidden-row number **MUST** warn and redisplay **that** list. Exit / empty still leave. A valid leaf then redisplays the **front board** (not the submenu). | **MUST NOT** hang. Non-TTY `menu` fails closed with a named-command hint |

#### `prompt_yes_no` contract (this project)

| Condition | Behavior |
|-----------|----------|
| `JSON=1` or `QUIET=1` | Return **1** (no / cancel)—never `read` |
| `TTY` is not `1` | Return **1** (no)—never `read` |
| `TTY=1` and not quiet/json | Prompt via `out_msg_n`; yes → 0, else → 1 |
| Uninstall without force + non-interactive | Confirm fails → uninstall cancelled (safe default) |
| Uninstall with `--force` | Skip confirm entirely |

Ship-unit function (`./sshd-cli`). Call it in the current shell (`if prompt_yes_no; then`). The gate is the process `TTY` global. Empty and any answer other than yes returns 1.

```sh
prompt_yes_no() {
    # --- Safe Variable Defaults ----
    # Defensive defaults - never assume globals are set
    : "${JSON:=0}"
    : "${QUIET:=0}"
    : "${TTY:=0}"

    local message="$1"

    # Never show prompt in quiet or json mode
    if [ "${JSON}" -eq 1 ] || [ "${QUIET}" -eq 1 ]; then
        return 1   # treat as "no" in non-interactive modes
    fi

    # Consume process TTY (measured once at startup; no second [ -t).
    if [ "${TTY}" -ne 1 ]; then
        return 1
    fi

    out_msg_n "${message} (y/N)? "

    local answer=""
    read -r answer || true

    case "$answer" in
        [Yy]*|[Yy][Ee][Ss]*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}
```

#### `prompt_ask` contract (this project)

| Condition | Behavior |
|-----------|----------|
| `JSON=1` or `QUIET=1` | Return **default** without `read` |
| `TTY` is not `1` (and `INTERACTIVE` ≠ 1) | Return **default** without `read` |
| `TTY=1` interactive | Show current/default via `out_*`, then `read` |

Ship-unit function (`./sshd-cli`). **WARNING — do-not-capture-read (`PP-A-22`):** MUST NOT `_x=$(prompt_ask …)` / `$()` / backticks. This body contains `read` and prints the answer on stdout. Call it in the current shell. Portable mold uses `PROMPT_ASK_VALUE`. Menu boards do not call this helper; they `read -r` in the current shell (`requirement-shell-cli-default-interaction` §2.11).

```sh
prompt_ask() {
    # --- Safe Variable Defaults ---
    : "${JSON:=0}"
    : "${QUIET:=0}"
    : "${TTY:=0}"
    : "${INTERACTIVE:=0}"

    # set -u safe: missing args become empty defaults (INC-20260713-001 class)
    local message="${1-}"
    local default="${2-}"
    local current="${3-}"

    # Never prompt in non-interactive modes
    if [ "${JSON}" -eq 1 ] || [ "${QUIET}" -eq 1 ]; then
        printf '%s' "${default}"
        return 0
    fi

    # Consume process TTY (measured once at startup). INTERACTIVE=1 is the
    # documented override when low-level TTY checks are flaky.
    if [ "${TTY}" -ne 1 ] && [ "${INTERACTIVE}" -ne 1 ]; then
        printf '%s' "${default}"
        return 0
    fi

    # Show current value if present
    if [ -n "${current}" ]; then
        out_info "Current: ${current}"
    fi

    # Show default
    if [ -n "${default}" ]; then
        out_info "Default: ${default}"
    fi

    out_msg_n "${message}: "

    local answer=""
    read -r answer || true

    if [ -z "${answer}" ]; then
        printf '%s' "${default}"
    else
        printf '%s' "${answer}"
    fi
}
```

#### `inst_maybe_install` contract (this project)

| Condition | Behavior |
|-----------|----------|
| Already installed (force off) | Success no-op; do not ask again |
| Quiet or JSON | **No prompt.** **MUST** call `inst_perform_install` and return its status. **MUST NOT** `return 0` without placing (unless already-installed no-op). Empty-argv quiet/json in `app_main` also calls `inst_perform_install` directly — **both** paths **MUST** place. Copied products **MUST NOT** keep a helper that skips install under quiet/json. |
| `TTY=1` interactive (not quiet/json) | Prompt install yes/no via `prompt_yes_no` |
| Non-TTY (pipe / automation) | **Auto-install** with a clear human message when not quiet/json |

This dual policy is intentional: **pipe / quiet / json first-install proceeds**; **destructive uninstall does not** without `--force`.

**Honesty (this ship unit, 2026-09-02):** `prompt_yes_no`, `prompt_ask`, and `inst_maybe_install` consume process `TTY`. Quiet/JSON Case A through the helper calls `inst_perform_install` (SM-BUG-01).

### 2.6 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): Never hang automation; destructive ops fail closed without force.  
- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): Explicit matrices for install vs uninstall vs flags.  
- **CIAO Principle 3 – Anti-fragile** (https://github.com/cloudgen/ciao): Works under `curl | sh`, CI, and human TTY.  
- **CIAO Principle 16 – Interactive vs Non-Interactive** (https://github.com/cloudgen/ciao): First-class mode policy.  
- **CIAO Principle 4 (O) / Principle 20 – Over-protect / Protect Against AI & Human Modification** (https://github.com/cloudgen/ciao): Protected `prompt_*` helpers; no raw read regressions.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Prefer cancel over destructive auto-action when intent is ambiguous; prefer auto-install for classic one-liner when not installed.  
- **Intentional:** Mode globals + `prompt_*` ownership is documented and stable.  
- **Anti-fragile:** Non-TTY and quiet/json paths always terminate without stdin.  
- **Over-protect:** Do not “simplify” prompt guards or replace `prompt_yes_no` with ad-hoc `read`.  
- **Pair with output SSOT:** Prompts use `out_msg_n` / `out_*`; JSON never shows prompts.  
- **Pair with CLI interface:** Flag meanings stay aligned with `requirement-shell-cli-interface.md`.

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

**This requirement:** `inst_maybe_install` **MUST NOT** recommend `sudo curl | sh`; **MUST NOT** open a Type 1 password-sudo ladder on that class. **dns** field walk is this login’s `~/.ssh/config` only (Type 0).

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Add `read` or confirmation prompts outside `prompt_ask` / `prompt_yes_no` / documented in-shell `dns` pick-and-field walk / `sshd_ssh_walk_user` / `app_cmd_menu` without updating this requirement.  
2. Allow prompts to run under `--json` or `--quiet`.  
3. Hang on prompts when stdin/stdout are not TTYs (except explicit `INTERACTIVE=1` for `prompt_ask` and the `dns` field walk).  
4. Break the invariant that `--json` forces quiet-style non-interactive human suppression.  
5. Auto-delete / uninstall without confirm **or** `--force` in interactive design—and must not auto-uninstall in non-interactive without `--force`.  
6. Remove the zero-arg non-TTY auto-install path for classic `curl | sh` without an explicit requirement change.  
7. Bypass `out_*` for prompt text (raw `echo`/`printf` user messages).  
8. Scatter ad-hoc TTY/mode logic that contradicts the global flag SSOT and `prompt_*` contracts.  
9. Hardcode project-specific secrets or release URLs into prompt strings.  
10. Let `inst_maybe_install` return success under `--quiet` / `--json` without calling `inst_perform_install` when the program is not installed.  
11. Re-test `[ -t 0 ]` / `[ -t 1 ]` inside helpers as the sole interactive gate; helpers **MUST** consume process `TTY`.  
12. Strip the **Under command line for normal user only** section, or recommend `sudo curl | sh` / Type 1 sudo on that class.  
13. Hang `dns` / `dns edit` / `dns delete` / `dns unset` / `ssh` / `download` / `upload` in non-interactive mode, or `$()` the dns field / user / folder `read` (**do-not-capture-read**). Non-interactive `dns` with no subcommand **MUST** list and return. Non-interactive `dns delete N` and `dns unset N field` **MUST NOT** prompt. Non-interactive `ssh` / `download` / `upload` without required operands **MUST** fail closed.  
14. `out_die` (or exit non-zero) solely because a TTY numbered menu received an unknown or out-of-range choice. **MUST** warn and display **that same list** again (main, sudoers, dns action, Host pick, unset picker, download/upload folder pick).

**Supporting non-interactive environments cleanly is mandatory for CIAO compliance.**

---

## 5. Definition of done (shell interactive vs non-interactive)

Mode-related work for sshd-cli is **not done** if any of the following fail:

1. No code path blocks on `read` under `--json`, `--quiet`, or non-TTY (except documented `INTERACTIVE=1` value prompt).  
2. Destructive uninstall without `--force` does not silently proceed in non-interactive mode.  
3. Zero-arg install-ensure supports automation (`curl | sh` / quiet/json): not-installed installs; already-installed (local or global) success no-op without help (`requirement-shell-cli-zero-arguments.md`). Quiet/json through `inst_maybe_install` **MUST** place or fail closed.  
4. All confirms go through `prompt_yes_no`.  
5. Colors only when TTY and not quiet/json.  
6. JSON/human contracts remain aligned with `requirement-shell-output-requirements.md`.  
7. Changes cite `requirement-shell-interactive-vs-noninteractive`.

---

## 6. Related artifacts

| Artifact | Role |
|----------|------|
| `docs/requirements/requirement-shell-cli-interface.md` | Flags and commands |
| `docs/requirements/requirement-shell-cli-zero-arguments.md` | Empty argv install-ensure matrix |
| `docs/requirements/requirement-shell-output-requirements.md` | quiet/json/debug output contracts |
| `docs/requirements/requirement-shell-self-management.md` | Uninstall confirm / force policy |
| `docs/requirements/requirement-shell-idempotency.md` | Re-run safety under automation |
| `docs/requirements/index.md` | Registry SSOT |
| `./sshd-cli` | Implementation under test |

---

## 7. Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-SSH-07**, **TP-SSH-08** | `tests/test_ssh_download.sh` | have |
| **TP-DL-04**, **TP-DL-05**, **TP-DL-10** .. **TP-DL-17** | `tests/test_ssh_download.sh` | have |
| **TP-DNS-13**, **TP-DNS-20**, **TP-DNS-21**, **TP-DNS-44**, **TP-DNS-47** .. **TP-DNS-49** | `tests/test_dns.sh` | have |
| **TP-SSHD-05**, **TP-SSHD-16** | `tests/test_cli.sh` | have |
| **TP-CFG-17** | `tests/test_config_backup.sh` | have |
| **TP-UL-01** .. **TP-UL-18** | `tests/test_ssh_download.sh` | **have** |

**Map:** `reviews/test-plan.md`

**Last Updated**: 2026-09-28 (1.2.6 zero-arg menu handler is `app_cmd_menu`. 1.2.5 `prompt_yes_no` and `prompt_ask` samples are the `./sshd-cli` functions. 2026-09-16 finished TTY leaf redisplays the front board; **TP-CLI-22**. TTY unknown menu choice redisplays that layer; DTV **TP-SSHD-16** · **TP-DNS-47..49** · **TP-CFG-17** · **TP-DL-17**)  
**Owner**: sshd-cli project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; CIAO Principles 1, 2, 3, 16, 4, 20 (v2.10.2) (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
