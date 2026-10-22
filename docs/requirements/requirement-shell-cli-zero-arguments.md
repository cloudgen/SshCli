**file**: docs/requirements/requirement-shell-cli-zero-arguments.md  
**Status**: Retired (Python generation 2.0.0. The live ship unit is the SshCli package. This file records the /bin/sh ship unit through 1.35.1. Where it disagrees with requirement-domain-sshd 1.28.0 or an Active requirement-python-*.md / requirement-runtime-prerequisites.md file, those win.) Was  (Version 1.5.1)  
**Philosophy**: CIAO / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered)

## 1. Purpose

When you run `sshd-cli` with **no command** — switches such as `--debug` are still no command — a **terminal** opens the numbered sshd list; a **pipe** (`curl … | sh`) or a quiet/json line with no command **places the CLI** (or says it is already there). It must not print help and must not install OpenSSH / start sshd (that is `install`).

Catalog: interactive **zero-cli-verb** → main menu; non-interactive **zero-cli-verb** → Type O **CLI self-install** (not Type N help; not payload). Dual mention: `requirement-shell-cli-self-install.md` · `requirement-shell-cli-default-interaction.md`.

### 1.0 Product type (template dual-model)

| Field | Value for sshd-cli |
|-------|------------------------|
| **Empty-argv type** | **Split on zero-cli-verb** (no verb; switches allowed): interactive → main **menu**; non-interactive → **Type O CLI self-install** (not Type N help; not payload `install`) |
| **Rationale** | Product advertises `curl … \| sh` one-liner **CLI place** (pipe = no TTY). Payload (packages / start sshd) is `sshd-cli install`. On a real terminal, no command (switches allowed) opens the numbered sshd list. |

Type N (non-online-install → empty argv = help) does **not** apply to this product.

It defines what happens on a **zero-cli-verb** line: **no command**, **switches allowed**, including the classic one-liner:

```sh
curl -fsSL https://raw.githubusercontent.com/cloudgen/sshd-cli/main/sshd-cli | /bin/sh
```

**Non-interactive** zero-cli-verb (pipe, CI, `--quiet` / `--json` with no verb, or no TTY) means **install-ensure** for three detect cases. **Interactive** zero-cli-verb (real terminal on stdin and stdout, not quiet/json, switches such as `--debug` allowed) means the main **menu** (`app_cmd_menu`) — dual mention `requirement-shell-cli-default-interaction` · `requirement-domain-sshd`.

| Case | Meaning |
|------|---------|
| **Not installed** | No managed binary at the resolved install path(s) |
| **Installed (local)** | Managed binary at the user path (`USER_BIN` / `${HOME}/.local/bin/sshd-cli`) |
| **Installed (global)** | Managed binary at the global path (`GLOBAL_BIN` / `/usr/local/bin/sshd-cli`) |

**Scope:** Empty-argv routing, detect cases (global / local / absent), messages, force boundary, exit status, interaction with TTY / quiet / json.  
**Out of scope (own requirements):** Full command catalog (`requirement-shell-cli-interface.md`); download/checksum detail (`requirement-shell-automatic-checksum.md`); full self-update/uninstall lifecycle (`requirement-shell-self-management.md`); output function catalog (`requirement-shell-output-requirements.md`); general idempotency matrix beyond empty-argv rows (`requirement-shell-idempotency.md`).

### 1.1 Human-facing

**In one sentence:** If you run `sshd-cli` with **no command** on a **terminal** (a switch such as `--debug` is still no command), you get the numbered sshd list; if you run it from a **pipe** (`curl … | sh`), or with `--quiet` / `--json` and no command, it **places itself** (or says it is already installed) — it must not print help.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | A person at a terminal, or a `curl \| sh` pipe with nobody to answer | `sshd-cli` on a TTY · `curl -fsSL …/sshd-cli \| /bin/sh` |
| The other role | Explicit verbs: help, force reinstall, uninstall, `menu` | `sshd-cli help` · `sshd-cli install --force` · `sshd-cli menu` |
| Not this file | Full command list, checksum, update/uninstall, output printers | `requirement-shell-cli-interface.md` and peers |

| Includes | Excludes |
|----------|----------|
| Zero-cli-verb: no routed-verb after switch parse. Includes a bare name, a pipe one-liner, and switches with no verb (`sshd-cli --debug`, `sshd-cli --quiet`, `sshd-cli --json`) | A line that still has a verb (`sshd-cli --json status`, `sshd-cli help`, `sshd-cli menu`) |
| Interactive zero-cli-verb → numbered main menu; non-interactive zero-cli-verb → Type O CLI self-install | Type N help-default; treating `--json` / `--quiet` with no verb as help; hanging a menu under a pipe |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./sshd-cli` | Program file people install | Live empty-argv behavior |
| `sshd-cli` with no args | Command | Terminal → menu; pipe → install-ensure |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| First install from the internet | No program is on disk yet. The pipe has no human to answer a question, so the tool **places itself** (user bin for a normal login; system bin if you already ran as root). Failure must be a real error, not a fake success. | `curl -fsSL https://raw.githubusercontent.com/cloudgen/sshd-cli/main/sshd-cli \| /bin/sh` |
| Run it on a terminal with no command | You get the numbered sshd list (same as `sshd-cli menu`). A switch is not a command. It must **not** install-ensure and must **not** dump help. | `sshd-cli` or `sshd-cli --debug` (real terminal) |
| Quiet or JSON with **no command** | No yes/no question and no menu. The tool still **places** the program (or no-ops if already installed). A helper that returns success without placing is a defect. | `sshd-cli --quiet` or `sshd-cli --json` with no command. Same if `QUIET=1` or `JSON=1` is already set and the line has no command |

Jargon: **zero-cli-verb** means no command after switches. **Type O** (letter) means that shape **places the CLI** on a **non-interactive** run. That is **not** Type **0** (digit: you run as yourself). On a real terminal, with quiet and json off, that same shape is the **main menu**.

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Definitions (portable + project)

| Term | Definition for sshd-cli |
|------|----------------------------|
| **Zero-cli-verb** | No routed-verb after global switches are parsed. Switches are allowed and are not a verb. A bare name is this shape. `sshd-cli --debug`, `sshd-cli --quiet`, and `sshd-cli --json` with no command are this shape. `sshd-cli --json status` is not. |
| **Type O** | Online-install ensure behavior: **non-interactive** zero-cli-verb = install-ensure (this product). Not the shape. Not JSON help. |
| **Type N** | Non-online-install behavior: no command = help — **out of scope** for sshd-cli. |
| **Empty argv / zero-arg** | Older name for a zero-cli-verb line. It is **not** `$# -eq 0` before flag parse. Switches do not take the line out of this shape. |
| **Interactive zero-cli-verb** | Zero-cli-verb and `TTY=1` and `JSON=0` and `QUIET=0`: route to `app_cmd_menu` (main menu; `requirement-shell-cli-default-interaction`). |
| **Non-interactive zero-cli-verb** | Zero-cli-verb and (no TTY, or `JSON=1`, or `QUIET=1`): `inst_self_install`. Includes `--quiet`, `--json`, and off-TTY `--debug` with no verb. |
| **Install-ensure** | Converge to “managed `sshd-cli` binary present”; either perform install or success no-op. **Non-interactive zero-cli-verb only.** |
| **Not installed** | `inst_is_installed` returns false (`inst_get_version` → `not installed`). |
| **Installed (local)** | Executable at `${USER_BIN}/sshd-cli` (default `USER_BIN=${HOME}/.local/bin`) observed by install-detect SSOT. |
| **Installed (global)** | Executable at `${GLOBAL_BIN}/sshd-cli` (default `GLOBAL_BIN=/usr/local/bin`) observed by install-detect SSOT. |
| **Force / reinstall** | `FORCE_REINSTALL=1` from `--force` (and related force wiring in `app_main`). Required only for deliberate replace, not for ensure. |

### 2.2 Split meaning of a zero-cli-verb line

1. When the line is a **zero-cli-verb** and the run is **interactive** (`TTY=1`, `JSON=0`, `QUIET=0`), `app_main` **MUST** call `app_cmd_menu` — **MUST NOT** install-ensure and **MUST NOT** route to `app_help`. Switches that do not set quiet or json (`--debug`, `--force`) do not change this route. The numbered tree is `requirement-shell-cli-default-interaction`.  
2. When the line is a **zero-cli-verb** and the run is **non-interactive** (no TTY, or `JSON=1`, or `QUIET=1`), `app_main` **MUST** run **CLI self-install** (`inst_self_install`) — **MUST NOT** open the menu, **MUST NOT** route to `app_help`, and **MUST NOT** run payload `inst_perform_install`. This includes `sshd-cli --quiet` and `sshd-cli --json` with no verb. Depth: `requirement-shell-cli-self-install.md`.  
3. Explicit `sshd-cli help` remains the only full-usage path for help text. Explicit `sshd-cli menu` remains the named menu verb (same handler). Those lines are **not** zero-cli-verb.  
4. Bootstrap **MUST** always call `app_main "$@"` so pipe one-liners reach this contract (no `${0##*/}` product-name gate).  
5. Non-interactive zero-cli-verb **MUST NOT** require the user to pass `install` or `install --force` merely because a previous ensure already succeeded.  
6. Portable mold JSON-help for `--json` with no command **MUST NOT** override rule 2. This product answers that line with Type O install-ensure.

### 2.2.1 Specializee contract (bootstrap origin → specialized B)

When this product is used as **bootstrap origin A** for a specialized product **B** (A→B only; never reverse-copy):

| Rule | MUST | MUST NOT |
|------|------|----------|
| Empty argv on B | Keep **non-interactive Type O install-ensure**; interactive empty argv **MAY** be a TTY menu when claimed | Hijack **non-interactive** empty argv for domain full-setup / host mutation; hang a menu under `curl \| sh` |
| Domain setup verb | Use an explicit command (e.g. `run`, `setup`, domain verb catalog) | Treat bare `curl \| sh` as host domain install |
| Case A helper | If B copies `inst_maybe_install` as first-install SSOT, quiet/json **MUST** call `inst_perform_install` and return its status | Copy a helper that `return 0` under quiet/json without placing the binary |
| Tests | Isolate `HOME`, `USER_BIN`, and **`GLOBAL_BIN`** so host `/usr/local/bin/${APP_NAME}` does not shadow lifecycle CI | Assume empty `HOME` alone hides a real global install |

**Rationale:** Specializees that rebind empty argv to interactive host setup break the online-install contract and confuse install-ensure with domain ops. Host-mutating domain work belongs under explicit verbs with privilege gates (see CLI interface specializee contract).

### 2.3 Normative case matrix

**Interactive empty argv** (before this matrix): `app_cmd_menu`; **does not** apply Cases A/B/C.

**Non-interactive** empty argv, `FORCE_REINSTALL=0`:

| Case | Detect condition (project) | Empty argv, `FORCE_REINSTALL=0` | Empty argv / install with force |
|------|----------------------------|--------------------------------|---------------------------------|
| **A. Not installed** | `inst_is_installed` false | Install into privilege-correct path (§2.4) | Same first-time install |
| **B. Installed — local** | User binary present via detect SSOT | Success no-op: already installed; no re-download; **no help**; **no menu** | `inst_perform_install` re-download/replace (user path when non-root) |
| **C. Installed — global** | Global binary present via detect SSOT | Success no-op: already installed; no re-download; **no help**; **no menu** | Re-download/replace (global path when root / global binary policy) |

**Already-installed rules (Cases B and C, force off):**

1. Exit status **MUST** be `0`.  
2. Human mode **MUST** use `out_success` with an **already installed** message (via `inst_perform_install` no-op path).  
3. Human mode **MAY** add `out_info` tips that `--force` / `self-update` are for **deliberate** reinstall or upgrade — **MUST NOT** imply force is required for a normal one-liner re-run.  
4. JSON mode **MUST** use structured success (`out_json` success type) with already-installed message — **MUST NOT** emit help JSON.  
5. Detect **MUST** treat either global or local managed binary as installed when that is how `inst_is_installed` / `inst_get_version` resolve paths (project SSOT today prefers global when executable there, else user path).

### 2.4 Case A — not installed (modes)

When **no managed binary** is present, **non-interactive** empty argv **MUST** place the program (or fail closed). **Interactive** empty argv **MUST** open the menu and **MUST NOT** place as a side effect.

| Mode | What a person sees | What MUST happen |
|------|--------------------|------------------|
| **Interactive** (real terminal on stdin+stdout, not quiet/json) | Numbered domain menu | `app_cmd_menu`; empty choice / Exit → 0; **no** install-ensure |
| **Non-interactive** (no terminal / `curl \| sh`) | An auto-install message | Place the program (`inst_maybe_install` non-TTY branch → `inst_perform_install`) |
| **Quiet or JSON** | No question; no menu | `inst_perform_install` (no prompt). Failure **MUST** be non-zero. **MUST NOT** return success without placing. |
| **Failure** (network, checksum, I/O) on install-ensure | An error | Non-zero exit; no fake success; no help-only output |

**Dispatcher vs helper (same outcome):**

| Path | Quiet / JSON, not installed | Human TTY | Pipe, not installed |
|------|-----------------------------|--------------------------|---------------------|
| `app_main` empty argv | **MUST** call `inst_perform_install` directly | **MUST** call `app_cmd_menu` (not install) | **MUST** auto-install (helper non-TTY branch or direct place) |
| `inst_maybe_install` itself | **MUST** call `inst_perform_install` and return its status. **MUST NOT** `return 0` without placing | Unreachable from empty argv (menu owns TTY) | Auto-install message + place |

Empty-argv quiet/json in `app_main` is **not** a license for the helper to no-op. Products copied from this bootstrap that route Case A **only** through the helper **MUST** still place the binary under quiet/json.

**Placement privilege:**

| Invoker | Target |
|---------|--------|
| root (`id -u` 0), e.g. `curl … \| sudo sh` | `${GLOBAL_BIN}/sshd-cli` → `/usr/local/bin/sshd-cli` |
| non-root | `${USER_BIN}/sshd-cli` → `${HOME}/.local/bin/sshd-cli` |

### 2.5 Equivalence to explicit `install`

| Invocation | Contract |
|------------|----------|
| Empty argv (non-interactive) | Same ensure semantics as `install` for Cases A/B/C |
| Empty argv (interactive) | Same as `menu` |
| `install` | Explicit ensure; same detect / no-op / force |
| `install --force` | Deliberate reinstall |
| `help` | Usage only — **not** empty-argv default |

### 2.6 Forbidden empty-argv outcomes

1. Dump full help when Case B or C applies.  
2. Silent success when Case A should install (or when Case B/C should acknowledge already installed).  
3. Require `--force` solely because detect says installed.  
4. Blind re-download every empty-argv run without force.  
5. Basename-gate main so `curl \| sh` never hits the empty-argv branch.  
6. Detect only one of global/local incorrectly so a present local install is treated as Case A (or the reverse) contrary to `inst_*` SSOT.  
7. Silent success from `inst_maybe_install` under quiet/json when Case A should place the binary.

### 2.7 Implementation Notes (this project)

| Item | Value for sshd-cli |
|------|------------------------|
| **Empty-argv type** | Interactive zero-cli-verb → `app_cmd_menu`; non-interactive zero-cli-verb → **Type O** install-ensure (not Type N help-default; not JSON help) |
| **Product / binary** | `sshd-cli` (`APP_NAME`) |
| **Ship unit** | Repo root `./sshd-cli` |
| **Dispatcher** | Zero-cli-verb **after** switch parse, plus the same split when `$# -eq 0` (no-token fast path). A switch-only line is this route. |
| **Interactive zero-cli-verb** | `TTY=1` and not quiet/json and no verb → `app_cmd_menu` |
| **CLI self-install** | `inst_self_install` — **non-interactive** zero-cli-verb (copy when `$0` is a script) |
| **Payload `install`** | `inst_perform_install` — explicit verb only |
| **Detect SSOT** | `inst_is_installed` ← `inst_get_version` |
| **Global path** | `GLOBAL_BIN` default `/usr/local/bin` |
| **Local path** | `USER_BIN` default `${HOME}/.local/bin` |
| **Force wiring** | `--force` → `FORCE=1` and `FORCE_REINSTALL=1` in `app_main` |
| **Output SSOT** | `out_success` / `out_info` / `out_json` / errors via `out_*` |
| **Channel** | `SCRIPT_URL` (compose from `REPO_USER` / `REPO_NAME` / `APP_NAME`) for download path inside install |
| **Tests** | `tests/test_cli.sh` (**TP-CLI-07** non-TTY empty argv; **TP-CLI-14** TTY menu; **TP-CLI-23** switch-only menu vs self-install); `tests/test_local_lifecycle.sh` (**TP-LC-10** mode heal `0711` → `0755`; quiet/json empty argv still places). |

#### Dispatcher algorithm (normative sketch)

```sh
# Zero-cli-verb: after global switches are parsed, no routed-verb remains.
# Switches (--debug, --quiet, --json, --force, …) are not a verb.
# A line with no tokens is the same shape.
# Interactive (TTY=1, JSON=0, QUIET=0) → main menu.
# Non-interactive (no TTY, or JSON=1, or QUIET=1) → CLI self-install.
# --json / --quiet with no verb are non-interactive (Type O, not help).
# Ship unit: the same split runs when $# -eq 0 (no-token fast path)
# and again after flag parse when COMMAND is empty (switch-only line).
if [ -z "${COMMAND-}" ]; then
    if [ "${TTY}" -eq 1 ] && [ "${JSON}" -eq 0 ] && [ "${QUIET}" -eq 0 ]; then
        app_cmd_menu
        exit $?
    fi
    inst_self_install
    exit $?
fi
```

This product: `--json` with no command is **Type O install-ensure** (not JSON help). Portable mold special-case JSON help **MUST NOT** override this specialized zero-cli-verb law.

#### Message contract (already installed, human)

- Success: `${APP_NAME} is already installed.` (or equivalent via `out_success`)  
- Optional info: force / `self-update` only for deliberate reinstall or upgrade  
- **MUST NOT** print the full `app_help` usage body on this path

### 2.8 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): One-liner re-runs must not look like broken install or force unnecessary reinstall.  
- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): Empty argv has one meaning for not-installed, local, and global.  
- **CIAO Principle 3 – Anti-fragile** (https://github.com/cloudgen/ciao): Dual install paths + `curl \| sh` + TTY.  
- **CIAO Principle 6 – Single Point of Entry** (https://github.com/cloudgen/ciao): `app_main` owns empty-argv before help default.  
- **CIAO Principle 16 – Interactive vs Non-Interactive** (https://github.com/cloudgen/ciao): Case A auto under pipe; optional TTY confirm.  
- **CIAO Principle 4 (O) / Principle 20 – Over-protect / Protect Against AI & Human Modification** (https://github.com/cloudgen/ciao): Protection Rule against help-fallback regression.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Real failures non-zero; healthy re-runs success with clear text.  
- **Intentional:** Help is never the empty-argv default; interactive no-args is the menu; pipe no-args is install-ensure.  
- **Anti-fragile:** Global and local detect; idempotent second one-liner.  
- **Over-protect:** Do not “simplify” empty-argv back to `COMMAND:=help` after first install.  
- **SSOT:** `inst_is_installed` / `inst_perform_install` / `inst_maybe_install` / `out_*`.  
- **Idempotent ensure:** Case B/C force off → already installed, exit 0.

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

**This requirement:** Type O empty-argv install-ensure stays Type 0 (this-login place + Termux `pkg` companion); **MUST NOT** become a sudo/apt install path.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Route **non-interactive** zero-cli-verb to `app_help` or to the domain **menu** when Case A/B/C should install-ensure.  
1b. Route **interactive** zero-cli-verb to install-ensure or to `app_help` instead of `app_cmd_menu`.  
1c. Treat a switch (`--debug`, `--quiet`, `--json`, `--force`) as a command, or send `sshd-cli --json` / `sshd-cli --quiet` with no verb to help.  
2. Require `--force` for a healthy already-installed **non-interactive** empty-argv re-run (local or global).  
3. Handle only Case A and leave B/C as accidental help fallthrough.  
4. Break dual-path detect so local or global installs are misclassified.  
5. Blindly reinstall on every empty-argv run without `FORCE_REINSTALL`.  
6. Exit 0 with no install and no already-installed acknowledgment when detect says installed.  
7. Reintroduce a basename-only gate that skips `app_main` under `curl \| sh`.  
8. Bypass `out_*` for empty-argv user messages.  
9. Contradict this file in peer requirements by documenting “already installed → help” as normative empty-argv behavior.  
10. Let `inst_maybe_install` return success under quiet/json when Case A should place the binary (silent skip). Empty-argv bypass in `app_main` does **not** excuse a helper that no-ops.  
11. Copy this helper into a specialized product as Case A SSOT while keeping a quiet/json `return 0` without `inst_perform_install`.  
12. Strip the **Under command line for normal user only** section, or turn empty-argv ensure into a Type 1 install on that class.

**Violating this rule is a critical zero-arg / online-install regression.**

---

## 5. Definition of done

This requirement is satisfied when all of the following hold:

1. Non-interactive zero-cli-verb + not installed → Case A install path (pipe / quiet / json / switch-only non-interactive auto). Quiet/json through the helper **MUST** place or fail closed — not `return 0` without install.  
1b. Interactive zero-cli-verb → `app_cmd_menu`; **MUST NOT** place the binary as a side effect.  
2. Non-interactive empty argv + local install present + force off → already-installed success; not help; not menu; no re-download.  
3. Non-interactive empty argv + global install present + force off → already-installed success; not help; not menu; no re-download.  
4. Empty argv + install failure → non-zero exit.  
5. `--force` only for deliberate reinstall; not required for ensure.  
6. `help` works when invoked explicitly.  
7. Tests cover Case A failure (not installed, bad channel) and already-installed not-help for local (Case B) and global (Case C).  
8. **TP-CLI-07:** not installed + QUIET/JSON empty argv places or fail closed (not a silent `return 0`).  
9. Changes cite `requirement-shell-cli-zero-arguments`.

### Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CLI-07** non-interactive empty argv install-ensure | `tests/test_cli.sh` | have |
| **TP-CLI-14** interactive empty argv menu | `tests/test_cli.sh` | have |
| **TP-CLI-23** switch-only: TTY `--debug` / `--force` menu; `--quiet` / `--json` / non-TTY `--debug` self-install | `tests/test_cli.sh` | have |
| **TP-LC-01** / **TP-LC-03** already-installed no-op | `tests/test_local_lifecycle.sh` | have |

**Map:** `reviews/test-plan.md`

---

## 6. Related artifacts

| Artifact | Role |
|----------|------|
| `docs/requirements/requirement-shell-cli-interface.md` | Full command surface; empty-argv row must match this SSOT |
| `docs/requirements/requirement-domain-sshd.md` | Menu handler and rows; dual mention of interactive empty argv |
| `docs/requirements/requirement-shell-idempotency.md` | Ensure re-run / force boundary |
| `docs/requirements/requirement-shell-interactive-vs-noninteractive.md` | TTY vs pipe for Case A |
| `docs/requirements/requirement-shell-self-management.md` | self-update / uninstall (not empty-argv default) |
| `docs/requirements/requirement-shell-output-requirements.md` | out_* / JSON purity |
| `docs/requirements/requirement-shell-automatic-checksum.md` | Integrity on install download path |
| Repo root `./sshd-cli` | Implementation (`app_main`, `inst_*`) |
| `tests/test_cli.sh`, `tests/test_local_lifecycle.sh` | Regression coverage |

---

## 7. Revision history

| Date | Change | Author / agent |
|------|--------|----------------|
| 2026-07-14 | Initial Active v1.0.0: empty argv = install-ensure for not-installed / local / global; forbid help fallthrough | Grok (owner request) |
| 2026-07-14 | v1.1.0: Classify product as Type O (online-install) under dual-type empty-argv template model | Grok |
| 2026-08-11 | v1.2.0: Specializee contract — empty argv stays Type O; domain setup uses explicit verbs; test GLOBAL_BIN isolation | Grok |
| 2026-09-05 | v1.3.0: Interactive empty argv → domain menu; non-interactive empty argv stays Type O install-ensure | Grok (owner request) |
| 2026-09-05 | v1.3.1: Section **Under command line for normal user only** (Type O ensure stays Type 0 on Termux/Git Bash) | Grok (owner request) |
| 2026-09-17 | v1.4.0: Non-interactive empty argv = CLI self-install (`inst_self_install`), not payload `install` | Grok (owner request) |
| 2026-09-28 | v1.5.0: Zero-cli-verb = no verb after switches. Interactive → main menu. Non-interactive, including `--quiet` / `--json` with no verb, stays Type O CLI self-install (not help) | Grok (owner request) |
| 2026-09-28 | v1.5.1: interactive zero-cli-verb calls `app_cmd_menu` | Grok (owner request) |
| 2026-09-06 | v1.3.2: People-language Purpose; DTV points at live `tests/test_local_lifecycle.sh` (drop ghost `test_install_lifecycle.sh` / `TP-INST-MAYBE-01`) | Grok |

---

**Last Updated**: 2026-09-28 (1.5.1 interactive zero-cli-verb calls `app_cmd_menu`)  
**Owner**: sshd-cli project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; CIAO Principles 1, 2, 3, 6, 16, 4, 20 (v2.10.2) (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).

