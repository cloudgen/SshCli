**file**: docs/requirements/requirement-shell-script-coding.md  
**Status**: Active (Version 1.1.4)  
**Area**: shell  
**Key**: `requirement-shell-script-coding`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This is the **coding-style related requirement** for sshd-cli (POSIX `/bin/sh`). **Without this file, portable learned lessons arrive raw** and agents treat coding skills as product law. It is the specialize-in home for shell coding rules that are not already owned by modular-function-design, output, or interactive-vs-noninteractive peers.

### 1.1 Human-facing

**In one sentence:** This file says how the `./sshd-cli` script must be written: prefixes, `set -u`, no capturing a `read` prompt with `$()`, and keep the Protection Zones.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Someone changing `./sshd-cli` | Add a function, keep `Last updated` |
| The other role | Peer files that already own output / prefixes catalog / TTY vs pipe | `requirement-shell-output-requirements.md` |
| Not this file | Which sshd verbs exist | `requirement-domain-sshd.md` |

| Includes | Excludes |
|----------|----------|
| `set -u`, prefix map pointer, do-not-capture-read, function `Last updated` | Re-owning the full `out_*` catalog |
| Domain prefix `sshd_*` | Python / Node style |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./sshd-cli` | Ship unit | Live style |
| `sh -n ./sshd-cli` | Syntax check | Must pass |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Add a helper | New name uses the right prefix; do not `$()` `prompt_ask` | Edit `./sshd-cli`; `sh -n ./sshd-cli` |
| Change a fatal | Human what-happened / next-step | Keep `out_die` |

---

## 2. Core Rules / Requirements (Mandatory)

1. **MUST** keep `set -u` at the top of `./sshd-cli`. **MUST NOT** add global `set -e`.  
2. **MUST** use the prefix families owned by `requirement-shell-modular-function-design` plus domain **`sshd_*`**.  
3. **MUST** send product user messages through `out_*` (`requirement-shell-output-requirements`).  
4. **MUST NOT** capture a `read` helper with `$()` / command substitution (**do-not-capture-read**). `prompt_ask` returns via stdout for class-B data; **new** TTY choice code (including `menu`) **MUST** `read` in the current shell, not `_x=$(prompt_ask …)`. The live menu functions are quoted in `requirement-shell-cli-default-interaction` §2.11. The live `prompt_ask` and `prompt_yes_no` bodies are quoted in `requirement-shell-interactive-vs-noninteractive`.  
5. **MUST** keep a `Last updated:` (or `Last reviewed:`) line on every function header that is edited.  
6. **MUST NOT** strip CIAO Protection Zones / `DO NOT MODIFY` dispatcher comments for brevity.  
7. **MUST** initialize variables used under `set -u` (`: "${VAR:=…}"` or a prior assign).  
8. **MUST NOT** use this file as a second copy of install or checksum tables.  
9. **SHOULD** keep `sh -n ./sshd-cli` passing in `tests/test_cli.sh`.  
10. In-tool sudo wrappers: **`util_sudo`** for `backup-config` only. SSOT: `requirement-shell-sudoer` (this file **points**; wrap slice `requirement-shell-sudo-command` also points).  
11. **MUST NOT** `out_die` because `mkdir` of one cache/storage leaf failed while later roots remain untried. Chain SSOT: `requirement-shell-cli-storage`.  
12. In-place `sed` **MUST** use `sed -i.bak` and then remove the `.bak`. Bare `sed -i` fails on macOS BSD `sed`. Family note: `requirement-shell-macos-cli-coding`.  
13. Family coding **MUST** stay on the five homes: `requirement-shell-fedora-redhat-cli-coding`, `requirement-shell-debian-cli-coding`, `requirement-shell-macos-cli-coding`, `requirement-shell-termux-cli-coding`, `requirement-shell-windows-git-bash-cli-coding`. This file **MUST NOT** copy those fences. `sshd_fix_os_class` stays `alpine` | `termux` | `posix` (`requirement-domain-sshd`).

### 2.1 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Ship unit | `./sshd-cli` POSIX `/bin/sh` |
| Prefixes in use | `out_` `inst_` `path_` `ver_` `util_` `prompt_` `app_` `sshd_` |
| `set -u` | yes (file top) |
| Menu read | `app_cmd_menu` and each child board call `read -r` in the current shell. Verbatim bodies: `requirement-shell-cli-default-interaction` §2.11 |
| Sudo wrap | `util_sudo` (`backup-config` only; `requirement-shell-sudoer`) |

### 2.2 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): Style home is named so lessons do not arrive raw.  
- **CIAO Principle 4 / 20 – Over-protect** (https://github.com/cloudgen/ciao): Protection Zones stay.  
- **CIAO Principle 21 – Dual policies** (https://github.com/cloudgen/ciao): Portable core; filled notes.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: `set -u` catches missing assigns.  
- **Intentional**: Prefixes encode job.  
- **Anti-fragile**: No global `set -e`.  
- **Over-protect**: Do not capture `read` in `$()`.

## Under command line for normal user only

When the ship unit detects a **command line for normal user only** (Termux, Git Bash, Windows cmd, or the same class):

| MUST | MUST NOT |
|------|----------|
| Keep **normal user privilege** (Type 0) only | Implement or enable **admin privilege** (Type 1) or **dedicated system user privilege** (Type 2) |
| Document Type 1 **unused** and Type 2 **unused** | In-tool `sudo`; wrap `apt` / `dnf` / `yum`; create a dedicated system user |
| Termux: named `pkg` as this login remains Type 0 | Recommend `sudo curl \| sh` as the install path |
| Git Bash / Windows cmd: same privilege ceiling | Invoke Termux `pkg` because Git Bash or Windows cmd was detected |

Helpers (this product): `sshd_is_termux`, `sshd_is_git_bash`, `sshd_is_windows_cmd`, `sshd_is_normal_user_only_cli`. Dual mention: `requirement-shell-cli-interface` · `requirement-shell-termux-ish`.

**This requirement:** no sudo-wrapping function; detect helpers stay `sshd_*`; **MUST NOT** add `util_sudo` because a Type 1 ladder exists on other products.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Delete this file while the workspace is software-development.  
2. Treat coding skills as product law because this file is missing.  
3. `$()` a `prompt_*` helper for new TTY choice code.  
4. Duplicate the full output or install tables here.  
5. Strip the **Under command line for normal user only** section, or add in-tool `sudo` on that class.  
6. Abort the CLI because `mkdir` of one cache leaf failed while later temp roots are untried (storage chain: `requirement-shell-cli-storage`).  
7. Paste the Fedora / Debian / macOS / Termux / Git Bash family fences into this file, or add `sshd_is_fedora` / `sshd_is_debian` here.

## 5. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry |
| `docs/requirements/requirement-shell-modular-function-design.md` | Prefix catalog |
| `docs/requirements/requirement-shell-output-requirements.md` | `out_*` |
| `docs/requirements/requirement-class-software-dev.md` | Residual points here |
| `docs/requirements/requirement-shell-cli-default-interaction.md` | Menu `read` bodies (§2.11) |
| `docs/requirements/requirement-shell-interactive-vs-noninteractive.md` | Live `prompt_ask` / `prompt_yes_no` |
| `docs/requirements/requirement-shell-fedora-redhat-cli-coding.md` | Fedora / Red Hat family fence |
| `docs/requirements/requirement-shell-debian-cli-coding.md` | Debian / Ubuntu family fence |
| `docs/requirements/requirement-shell-macos-cli-coding.md` | Darwin family fence |
| `docs/requirements/requirement-shell-termux-cli-coding.md` | Termux coding fence (`pkg` stays on termux-ish) |
| `docs/requirements/requirement-shell-windows-git-bash-cli-coding.md` | Git Bash coding fence |
| `./sshd-cli` | Implementation |

**Last Updated**: 2026-10-14 (1.1.4 family coding homes own Fedora/Red Hat, Debian, macOS, Termux, and Windows Git Bash. In-place `sed` is `sed -i.bak`. 2026-09-28 (1.1.3 menu `read` is `app_cmd_menu` and the child boards. 1.1.2 quoted those bodies in the peer requirements))  
**Owner**: Cloudgen Wong  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
