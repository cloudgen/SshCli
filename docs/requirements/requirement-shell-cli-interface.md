**file**: docs/requirements/requirement-shell-cli-interface.md  
**Status**: Retired (Python generation 2.0.0. The live ship unit is the SshCli package. This file records the /bin/sh ship unit through 1.35.1. Where it disagrees with requirement-domain-sshd 1.28.0 or an Active requirement-python-*.md / requirement-runtime-prerequisites.md file, those win.) Was  (Version 1.14.16)  
**Philosophy**: CIAO / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered)

## 1. Purpose

This requirement is the **project Single Source of Truth** for the **POSIX shell CLI interface** of the sshd-cli tool: command surface, privilege typing, global flags, dispatcher behavior, output modes, and interactive vs non-interactive rules.

It defines a **normal user privilege** (workshop **Type 0**) **self-managed shell CLI** (install / update / uninstall of the tool itself). It does **not** invent **admin privilege** (Type 1) host-bootstrap or **dedicated system user privilege** (Type 2) app-ops commands unless a future requirement adds them.

**Scope:** User-facing command names, flags, dispatch, privilege labels, and mode contracts.  
**Out of scope (own requirements when specialized):** Online-install checksum mechanics detail, self-management safety beyond the command surface, shell coding style, full output-function catalog (cited, not re-owned).

### 1.1 Human-facing

**In one sentence:** This file lists the **words you type** (`version`, `help`, `install`, `status`, `start`, …), the flags (`--quiet`, `--json`, `--force`), and that **you run them as this login** — no in-tool `sudo`, no dedicated `sshd-adm` account.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | The person who types the command | `sshd-cli help` · `sshd-cli version` |
| The other role | Zero-cli-verb (interactive main menu / non-interactive CLI self-install) and lifecycle safety | `requirement-shell-cli-zero-arguments.md` · `requirement-shell-cli-default-interaction.md` · `requirement-shell-cli-self-install.md` · `requirement-shell-self-management.md` |
| Not this file | Checksum, storage paths, `out_*` internals | Peer requirements |

| Includes | Excludes |
|----------|----------|
| Command names, flags, “unknown command” fail | Host package install, dedicated-account app ops |
| Empty-argv **row** pointing at the zero-arguments file | Re-owning the full Case A/B/C matrix |

| Surface | What you open | What for |
|---------|---------------|----------|
| `sshd-cli help` | Command | Listed verbs and flags |
| `./sshd-cli` | Program file | Dispatcher |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| See the menu | Help lists install, version, about, self-update, self-uninstall, and flags. An unknown word is an error, not a silent no-op. | `sshd-cli help` |
| Ask for JSON | Same verbs; structured objects; no human banners. | `sshd-cli --json version` |

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Command surface (portable shape)

Every CIAO-Lite shell CLI **MUST** expose a documented command set. Commands **MUST** map to exactly one privilege type. Unclassified commands are incomplete design.

| Category | Privilege | Meaning | Portable examples |
|----------|-----------|---------|-------------------|
| **Type 0 – Normal user privilege – Self-management / CLI lifecycle** | Invoking user (no elevation required for user-owned install) | Manage the CLI binary and diagnostics | `version`, `about`, `help`, `version-check`, `self-update`, `self-uninstall` |
| **Type 0 – Normal user privilege – Install CLI binary** | Invoking user (root → global path; non-root → user path) | First-time or explicit **CLI** placement | `self-install`; **non-interactive** empty argv — `requirement-shell-cli-self-install.md` |
| **Type 1 – Admin privilege – Host preparation** | Elevated (internal escalation when designed) | Passwordless `sudo sshd-cli backup-config` into `/var/sshd-cli` after sudoer-adm | *Used for `backup-config` deposit on POSIX Linux. On a command line for normal user only (Termux, Git Bash, Windows cmd) MUST stay unused — do not implement/enable.* |
| **Type 2 – Dedicated system user privilege – App ops under system user** | Dedicated least-privilege system user | App install/configure/runtime under app identity | *Unused on this product. On a command line for normal user only (Termux, Git Bash, Windows cmd) MUST stay unused — do not implement/enable.* |

**Execution rules (core):**

1. Type 0 commands **MUST** run as the invoker without requiring a dedicated system user.
2. Type 1 on this product is **only** the studied `sudo -n {{GLOBAL_BIN}}/sshd-cli backup-config` grant (`requirement-shell-sudoer` · `requirement-shell-config-backup`). Type 2 is **unused**. **MUST NOT** add other Type 1 verbs without updating those requirements.  
3. When the ship unit detects a **command line for normal user only** (Termux, Git Bash, Windows cmd): Type 1 and Type 2 **MUST** stay unused. **MUST NOT** implement or enable in-tool `sudo`, wrap `apt`/`dnf`/`yum`, create a dedicated system user, or recommend `sudo curl | sh` as the install path. Helpers: `sshd_is_termux`, `sshd_is_git_bash`, `sshd_is_windows_cmd`, `sshd_is_normal_user_only_cli`. Dual mention: `requirement-shell-termux-ish` (Termux detect / `pkg`).
4. Privilege type for each command **MUST** be documented in help and in this requirement’s Implementation Notes.

### 2.2 Global flags (portable)

| Flag | Env / state | Behavior |
|------|-------------|----------|
| `--quiet`, `-q` | `QUIET=1` | Suppress non-error human output; errors and fatal paths still visible |
| `--json` | `JSON=1` (implies quiet) | Machine-readable structured output; no human banner text |
| `--debug` | `DEBUG=1` | Extra diagnostics when designed (must not break JSON purity on stdout) |
| `--force` | Force/reinstall policy vars | Skip safe confirms or force reinstall only where documented; never silent security bypass |

Additional flags **MAY** be added only when documented here (or a superseding requirement) and wired in the dispatcher.

### 2.3 Dispatcher and entry rules (portable)

1. **Single entry:** A single main dispatcher (e.g. `app_main`) **MUST** parse global flags and route commands.
2. **Unknown command:** **MUST** fail loudly with a clear error and pointer to `help` (via output SSOT).
3. **Zero-cli-verb split:** No command after switches **MUST NOT** mean help. Switches are not a verb. **Interactive** (`TTY=1`, not quiet/json) → main **menu**. **Non-interactive** (no TTY, or `--quiet`, or `--json` with no verb) → **CLI self-install** (`inst_self_install`; not payload; not JSON help). Full contract: `requirement-shell-cli-zero-arguments.md` · `requirement-shell-cli-default-interaction.md` · `requirement-shell-cli-self-install.md`.
4. **Idempotent install skip:** Install **MUST** no-op when already installed unless force/reinstall policy is set.
5. **No raw user I/O:** User-facing messages **MUST** go through the centralized `out_*` system (see output template/term).

### 2.4 Output and mode contracts (portable)

| Mode | Contract |
|------|----------|
| Human (default TTY) | Prefixed messages via `out_*`; colors only when TTY and not quiet/json |
| Quiet | Suppress info/success/plain noise; still show errors / fatal |
| JSON | Force quiet; emit structured JSON via `out_json` / `out_json_error`; no mixed human lines on success path |
| Non-interactive | Never hang on prompts; use safe defaults or `--force`/env policy |

Destructive Type 0 actions (e.g. uninstall) **MUST** confirm when interactive unless force policy is set; non-interactive **MUST NOT** block on stdin.

### 2.5 Help surface (portable)

`help` **MUST** list:

- Usage line  
- Every supported **operational** command with one-line purpose  
- Privilege category (at least Type 0 vs elevated vs system-user when those exist)  
- Global flags  
- **Test-purpose** verbs (when any exist, including `rc-test`) under a heading **apart** from operational verbs  

In JSON mode, help **MUST NOT** dump long human text; return a short structured success/note object instead. Human `help` and human `about` follow the saved language (`requirement-shell-cli-language`). JSON about fields stay the machine contract in English. Argv `version` stays English.

**Recommended help section order** (specializee-friendly; Type 0 bootstrap uses Type 0 first):

1. Title / short description  
2. Usage  
3. **Type 0 self-management** commands  
4. **Domain commands** (when specialized B has a domain surface; **absent** on bootstrap A)  
5. Global options  
6. Environment / channel vars (never `CHECKSUM` on help)

Ship-unit injection anchors (comments in `./sshd-cli`): `DOMAIN_HELP_ROWS`, `DOMAIN_ABOUT_FIELDS`, `DOMAIN_DISPATCH_FLAGS`, `DOMAIN_DISPATCH_COMMANDS`, `DOMAIN_DISPATCH_ROUTES`.

### 2.5.1 Specializee contract (bootstrap origin → specialized B)

When specializing product **B** from this bootstrap (**A → B only**):

| Concern | MUST | MUST NOT |
|---------|------|----------|
| **Channel** | B Config defaults `REPO_USER` / `REPO_NAME` / `SCRIPT_URL` for **B’s** product channel | Point B’s default channel at A’s raw URL (or A at B’s) without explicit user order |
| **Identity** | Retarget `APP_NAME`, descriptions, product `VERSION` on B | Leave B’s `APP_NAME` as the bootstrap parent name |
| **Output** | All domain user/machine messages via `out_*` (temporary shims → `out_*` OK) | Parallel `echo`/`printf` banners or a second JSON family as product UI |
| **Host-mutating domain** | Privilege gate (**root** / designed escalation) **before** any host mutation on **every** path (interactive **and** non-interactive) | Non-interactive “success” after partial host writes as non-root |
| **Dispatch** | Single `app_main`; add domain verbs in the same parse pass as Type 0 | Drop Type 0 routes while claiming same architecture as A |
| **Help / about** | Keep Type 0 rows; add domain rows/fields at the injection anchors | Replace help entirely with domain-only text |
| **Requirements retarget** | Rewrite product identity only; keep CIAO / peer URLs (`github.com/cloudgen/ciao`, …) | Bulk `sed` org renames that break philosophy links |
| **Domain law** | After domain extend: one Active `requirement-domain-*` with four pillars | Domain law only on A; reverse-copy B domain onto A |

### 2.6 Implementation Notes (this project)

| Item | Value for sshd-cli |
|------|------------------------|
| **Product / binary name** | `sshd-cli` (`APP_NAME`, default `sshd-cli`) |
| **Primary executable** | Repo root `./sshd-cli` (POSIX `/bin/sh`, single-file for `curl \| sh`) |
| **Dispatcher** | `app_main` (always invoked at end of script: `app_main "$@"` — no `${0##*/}` / APP_NAME basename gate; required for `curl \| sh`) |
| **Output SSOT** | `out_text` + wrappers (`out_info`, `out_success`, `out_warn`, `out_error`, `out_die`, `out_plain`, `out_json`, …) |
| **Version SSOT** | `VERSION` default `1.35.1` (script header / config block: `VERSION="1.35.1"`) |
| **Install paths** | Global: `GLOBAL_BIN` default `/usr/local/bin`, or `${PREFIX}/bin` when Termux `PREFIX/bin` exists; User: `USER_BIN` default `${HOME}/.local/bin` |
| **Interactive rc write path** | `BASHRC` default `${HOME}/.bashrc`. `install` PATH ensure creates/modifies this file. Tests/CI **MAY** set `BASHRC` to a file in a temp folder. Dual mention: `requirement-shell-path-and-shell-support`. |
| **Remote channel env (help surface)** | `REPO_USER` / `REPO_NAME` (defaults `cloudgen` / `sshd-cli`); `SCRIPT_URL` composed default `https://raw.githubusercontent.com/${REPO_USER}/${REPO_NAME}/main/${APP_NAME}` (literal product default: `https://raw.githubusercontent.com/cloudgen/sshd-cli/main/sshd-cli`; override via env). **`help` / `about` MUST list these operator channel vars as designed — MUST NOT list `CHECKSUM`** (install-path runtime pin only; see `requirement-shell-automatic-checksum.md`). **`help` Environment also lists `BASHRC`.** |
| **Type 1 / Type 2 commands** | Type 1: `backup-config` deposit via `util_sudo` (`sudo -n {{GLOBAL_BIN}}/sshd-cli backup-config`). Type 2: **None**. Domain sshd start/stop on Linux may **need a root login** (no in-tool sudo for those). Termux, Git Bash, and Windows cmd: Type 1/2 stay unused; backup-config / sync-config / sudoers fail closed. |
| **Dedicated system user** | **Not required**. **MUST NOT** enable on Termux, Git Bash, or Windows cmd. |
| **Normal-user-only CLI detect** | `sshd_is_normal_user_only_cli` = Termux **or** Git Bash **or** Windows cmd |

#### Supported commands (normative for this project)

| Command | Type | Handler (current) | Required behavior |
|---------|------|-------------------|-------------------|
| *(zero-cli-verb — no verb; switches allowed)* | Type 0 | `app_main` → `app_cmd_menu` (interactive) or `inst_self_install` (non-interactive) | Interactive: main menu (`sshd-cli`, `sshd-cli --debug`). Non-interactive: **CLI self-install** (`curl \| sh`, `sshd-cli --quiet`, `sshd-cli --json` with no verb). Never help. Never payload. See `requirement-shell-cli-zero-arguments.md` · `requirement-shell-cli-default-interaction.md` · `requirement-shell-cli-self-install.md` |
| `self-install` | Type 0 | `inst_self_install` | Place **this CLI only** (copy when `$0` is a script; download when piped). Dest **0700** local / **0755** global. **MUST NOT** `pkg` or start sshd. Dual mention: `requirement-shell-cli-self-install`. Sample: `sshd-cli self-install` |
| `install` | Type 0 | `inst_perform_install` | Payload: **always** `inst_ensure_companion` (rc + Termux pkg); then **start sshd** (`sshd_start_after_install`). Also places the CLI if needed. Dual mention: `requirement-shell-self-management` · `requirement-shell-path-and-shell-support` · `requirement-domain-sshd` |
| `version` | Type 0 | argv: `app_version`; TTY **62** / typed `version` on a board: `app_about` | Argv: print local version; JSON `"type":"version"` when `--json`. TTY numbered **62** and typed `version` run **about** (diagnostics), not a header reprint (**INC-20260914-001**). |
| `about` | Type 0 | `app_about` | Diagnostics: install presence, global/local paths, user, shell, TTY; **Cache folder used**, **preferred**, **1st fallback**, **2nd fallback** when that host has one, and **Persistence storage** (`requirement-shell-cli-storage`); human lines follow the saved language; JSON when `--json` stays English; **no `CHECKSUM` field** |
| `version-check` | Type 0 | `ver_check` | Compare local vs remote `VERSION` from `SCRIPT_URL`; fail clearly if URL unset/unreachable |
| `self-update` | Type 0 | `inst_self_update` | Fetch remote version; reinstall when policy allows; reuse install primitives. **CLI-only:** no auto-start sshd; no `sshd -t` of `/etc/ssh/sshd_config`. Dual mention: `requirement-shell-self-management` · `requirement-domain-sshd` |
| `self-uninstall` | Type 0 | `inst_self_uninstall` | Remove managed binary; PATH cleanup only if `~/.local/bin` empty (user installs) |
| `help` | Type 0 | `app_help` | Full usage in human mode; short JSON note in JSON mode; Environment lists channel vars plus `BASHRC` — **not** `CHECKSUM` |
| `status` | Type 0 domain | `sshd_cmd_status` | Show sshd running/port/paths and a live `ssh -p … user@lan` connect line. systemd host: unit name + active. Dual mention: `requirement-domain-sshd` |
| `start` | Type 0 domain | `sshd_cmd_start` | Termux / no-unit Linux: OpenSSH `sshd -f` (no `-D`). POSIX Linux with a loaded distro unit: `systemctl start <unit>` as **root login**. Termux: auto-acquire Android wake lock. **No** routed `systemctl` verb; **no** in-tool `sudo`. Dual mention: `requirement-domain-sshd` · `requirement-shell-termux-ish` |
| `stop` | Type 0 domain | `sshd_cmd_stop` | Same launch-path split (`systemctl stop <unit>` when a unit exists). Dual mention: `requirement-domain-sshd` |
| `restart` | Type 0 domain | `sshd_cmd_restart` | Unit path: one `systemctl restart <unit>`. Else stop then start. Dual mention: `requirement-domain-sshd` |
| `port` | Type 0 domain | `sshd_cmd_port` | Show or set listen Port. Dual mention: `requirement-domain-sshd` |
| `config` | Type 0 domain | `sshd_cmd_config` | Show resolved sshd paths and key settings. Dual mention: `requirement-domain-sshd` |
| `host-keys` | Type 0 domain | `sshd_cmd_host_keys` | List or generate host keys. Dual mention: `requirement-domain-sshd` |
| `auth-keys` | Type 0 domain | `sshd_cmd_auth_keys` | List or add this login `authorized_keys`. Dual mention: `requirement-domain-sshd` |
| `dns` | Type 0 domain | `sshd_cmd_dns` | This login `~/.ssh/config` Host list (TTY edit/add/delete/unset menu; as Termux / identity-file / Old OpenSSH; show; set/add/delete/unset operands). `unset` drops extra settings (user, port, …), not dns or ip. Add and update comment keywords this OS rejects. Dual mention: `requirement-domain-sshd` · `requirement-shell-interactive-vs-noninteractive` |
| `fix-config` | Type 0 domain | `sshd_cmd_fix_config` | Comment OpenSSH client keywords this OS does not support. Optional `--input-file` and `--output-file` follow the verb. Every run also applies that pass to `~/.ssh/config` before dispatch, with no extra message. Typed only (no numbered row). Dual mention: `requirement-domain-sshd`. Sample: `sshd-cli fix-config` · `sshd-cli fix-config --input-file "${HOME}/.ssh/config" --output-file "${HOME}/ssh-config.commented"` |
| `ssh` | Type 0 domain | `sshd_cmd_ssh` | OpenSSH client to a concrete Host alias from this login `~/.ssh/config` (TTY numbered pick then user with default; operand `<n\|name>`). Dual mention: `requirement-domain-sshd` · `requirement-shell-interactive-vs-noninteractive`. Sample: `sshd-cli ssh 1` |
| `download` | Type 0 domain | `sshd_cmd_download` | tar.gz a remote folder over ssh and extract into cwd (TTY Host pick, then user with default, then numbered previous folders or a typed path; `~/folder` allowed). When the gzip reader is MSYS2 or Git Bash, do not pipe that gzip on stdin (`requirement-shell-windows-git-bash-cli-coding`). From **1.35.1** the ship unit uses the finished file for that reader. Dual mention: `requirement-domain-sshd` · `requirement-shell-interactive-vs-noninteractive`. Sample: `sshd-cli download 1 /opt/app` · `sshd-cli download 1 ~/box/app` |
| `upload` | Type 0 domain | `sshd_cmd_upload` | tar.gz a **local** folder over ssh and extract under the remote login home (TTY Host pick, then user with default, then numbered previous **local** folders or a typed path; `~/folder` is this login). When the gzip reader is MSYS2 or Git Bash, do not pipe that gzip on stdin (`requirement-shell-windows-git-bash-cli-coding`). From **1.35.1** the ship unit uses the finished file for that reader. Dual mention: `requirement-domain-sshd` · `requirement-shell-interactive-vs-noninteractive`. Sample: `sshd-cli upload 1 ./box` · `sshd-cli upload 1 ~/box/app` |
| `menu` / `main` | Type 0 | `app_cmd_menu` | Numbered tree on a terminal (`main` is an unlisted alias of `menu`). Same handler as an interactive zero-cli-verb. Front **1** client-side / **2** server-side / **5** sudoers (POSIX Linux) / **6** self-management / **7** language / **9** Exit. **7** opens the language block **70–89** (not more than 20 languages): **71** English / **72** Simplified Chinese / **73** Traditional Chinese / **74** Spanish / **75** Arabic / **76** French / **77** Portuguese / **78** Russian / **79** German / **80** Japanese / **81** Korean / **82** Dutch / **83** Greek. **70** and **84–89** are reserved and are not printed. Front **8** is not a row. Dual mention: `requirement-shell-cli-default-interaction` · `requirement-shell-cli-language` · `requirement-domain-sshd` · `requirement-shell-interactive-vs-noninteractive` |
| `wake-lock` | Type 0 | `sshd_cmd_wake_lock` | Acquire Android wake lock again (`termux-wake-lock`). Termux: fail closed if helper missing. Off Termux: success no-op. Dual mention: `requirement-shell-termux-ish` |
| `wake-unlock` | Type 0 | `sshd_cmd_wake_unlock` | Release Android wake lock (`termux-wake-unlock`). Operator-owned. **MUST NOT** auto-run from `stop`. Dual mention: `requirement-shell-termux-ish` |
| `backup-config` | Type 1 deposit (POSIX Linux) | `sshd_cmd_backup_config` | Copy this login `~/.ssh/config` to `/var/sshd-cli/config`. Dual mention: `requirement-shell-config-backup` · `requirement-shell-sudoer` · `requirement-domain-sshd`. Sample: `sshd-cli backup-config` |
| `sync-config` | Type 0 | `sshd_cmd_sync_config` | Copy `/var/sshd-cli/config` to `~/.ssh/config` mode 600. Dual mention: `requirement-shell-config-backup`. Sample: `sshd-cli sync-config` |
| `sync-from-remote` | Type 0 | `sshd_cmd_sync_from_remote` | `scp` a remote `/var/sshd-cli/config` into this login `~/.ssh/config` (mode 600). Remembers last SPEC as TTY default. Dual mention: `requirement-shell-config-backup`. Sample: `sshd-cli sync-from-remote user@host` |
| `print-sudoers` | Type 0 | `sshd_cmd_print_sudoers` | Emit fragment. Dual mention: `requirement-shell-sudoer`. Sample: `sshd-cli print-sudoers` |
| `print-sudoers-install-script` | Type 0 | `sshd_cmd_print_sudoers_install_script` | Admin script. Dual mention: `requirement-shell-sudoer`. Sample: `sshd-cli print-sudoers-install-script` |
| `generate-sudoer-request` | Type 0 | `sshd_cmd_generate_sudoer_request` | Local JSON grant. Dual mention: `requirement-shell-sudoer`. Sample: `sshd-cli generate-sudoer-request` |
| `submit-sudoer-request` | Type 0 | `sshd_cmd_submit_sudoer_request` | Queue inbound. Dual mention: `requirement-shell-sudoer`. Sample: `sshd-cli submit-sudoer-request` |
| `remove-project-sudoers` | Type 0 | `sshd_cmd_remove_project_sudoers` | Delete draft. Dual mention: `requirement-shell-sudoer`. Sample: `sshd-cli remove-project-sudoers` |
| `rc-test` | Type 0 **test-purpose** | `path_rc_test` | Fixture create / modify / no-op against `--root` tmp/cache. **MUST NOT** write this login’s real `{{HOME}}/.bashrc`. Help lists this **apart** from operational verbs. Dual mention: `requirement-shell-path-and-shell-support`. Sample: `sshd-cli rc-test --root "$tmpdir" --file bashrc --case create` |

#### Dual mention (CI-M1 — this project)

Every routed verb is named **here** and on a topic-owner. Help/`app_help` is **not** the second mention.

| Verb | Topic-owner | Sample on owner |
|------|-------------|-----------------|
| empty argv | `requirement-shell-cli-zero-arguments` · `requirement-shell-cli-self-install` | `sshd-cli` (TTY menu / pipe CLI self-install) |
| `self-install` | `requirement-shell-cli-self-install` | `sshd-cli self-install` |
| `install` | `requirement-shell-self-management` · `requirement-shell-path-and-shell-support` · `requirement-domain-sshd` · `requirement-shell-termux-ish` | `sshd-cli install` |
| `version` | `requirement-shell-output-requirements` | `sshd-cli version` |
| `about` | `requirement-shell-self-management` · `requirement-shell-cli-storage` | `sshd-cli about` |
| `help` | `requirement-shell-cli-zero-arguments` · `requirement-shell-automatic-checksum` | `sshd-cli help` |
| `version-check` / `self-update` | `requirement-shell-self-management` | `sshd-cli version-check` |
| `self-uninstall` | `requirement-shell-self-management` · `requirement-shell-path-and-shell-support` | `sshd-cli --force self-uninstall` |
| `status` / `start` / `stop` / `restart` / `port` / `config` / `host-keys` / `auth-keys` / `dns` / `fix-config` / `ssh` / `download` / `upload` / `menu` | `requirement-domain-sshd` | `sshd-cli status` · `sshd-cli dns list` · `sshd-cli fix-config` · `sshd-cli ssh 1` · `sshd-cli download 1 /opt/app` · `sshd-cli upload 1 ./box` |
| `backup-config` / `sync-config` / `sync-from-remote` | `requirement-shell-config-backup` · `requirement-shell-sudoer` · `requirement-domain-sshd` | `sshd-cli backup-config` · `sshd-cli sync-from-remote user@host` |
| `print-sudoers` / `print-sudoers-install-script` / `generate-sudoer-request` / `submit-sudoer-request` / `remove-project-sudoers` | `requirement-shell-sudoer` | `sshd-cli generate-sudoer-request` |
| `main` | `requirement-domain-sshd` | alias of `menu` (help names the alias; type `menu`) |
| `wake-lock` / `wake-unlock` | `requirement-shell-termux-ish` | `sshd-cli wake-lock` · `sshd-cli wake-unlock` |
| `rc-test` | `requirement-shell-path-and-shell-support` | `sshd-cli rc-test --root "$tmpdir" --file bashrc --case create` |

#### Global flags (normative wiring for this project)

| Flag | Required wiring |
|------|-----------------|
| `--quiet`, `-q` | Set `QUIET=1` in `app_main` |
| `--json` | Set `JSON=1` and `QUIET=1` in `app_main` |
| `--debug` | Set `DEBUG=1` in `app_main` |
| `--force` | Parsed by `app_main` → `FORCE=1` and `FORCE_REINSTALL=1`; used by install reinstall, self-update (incl. deliberate downgrade), and uninstall confirm skip |

#### Dispatcher sample (this project — zero-cli-verb + test-purpose + domain)

```sh
# Zero-cli-verb: no verb after switches. Interactive → main menu.
# Non-interactive (--quiet / --json / no TTY) → CLI self-install.
# Always app_main "$@" (no basename gate).
# Ship unit: no-token fast path, and the same split after flag parse.
if [ -z "${COMMAND-}" ]; then
    if [ "${TTY}" -eq 1 ] && [ "${JSON}" -eq 0 ] && [ "${QUIET}" -eq 0 ]; then
        app_cmd_menu
        exit $?
    fi
    inst_self_install
    exit $?
fi
# rc-test operands accumulate then: set -- ${RC_TEST_OPERANDS}; path_rc_test "$@"
# Domain verbs (status|start|stop|restart|port|config|host-keys|auth-keys|dns|ssh|download|upload|menu|main|wake-lock|wake-unlock)
# share the same parse pass as Type 0. Operands after port/dns/ssh/download/upload/… go in DOMAIN_OPERANDS.
```

#### Dispatcher acceptance criteria (this project)

1. Unknown token after flag parse → `out_die` with pointer to `sshd-cli help` (catalog row EX-DIE-196 in `requirement-shell-exit-condition`).  
2. Zero-cli-verb (no verb; switches allowed) → interactive main menu **or** non-interactive CLI self-install (not help, not JSON help); failures non-zero.  
3. Command routing table in `app_main` **must** include every **operational** row in the command table above **and** `rc-test`.  
4. Help text **must** stay aligned with that table (no orphan commands, no listed-but-unrouted commands). Help **MUST** list `rc-test` under a heading **apart** from operational verbs.  
5. User-facing strings **must not** use raw `echo`/`printf` outside the `out_*` system (protected low-level helpers excepted only if already CIAO-marked and not for general messages).

#### Explicitly out of scope until a new requirement

- Type 1: `prerequisites`, `create-user`, Docker host install, wrapping `sudo` inside this CLI, wrapping Linux `apt`/`dnf` (Termux `pkg` on `install` is the Termux-ish companion — `requirement-shell-termux-ish` — not a Type 1 verb). On Termux, Git Bash, or Windows cmd these **MUST NOT** be enabled.  
- Type 2: app ops under a dedicated system user. On Termux, Git Bash, or Windows cmd **MUST NOT** be enabled.  
- Domain catalog ownership lives on `requirement-domain-sshd` (this file dual-mentions the verbs)  
- Writing systemd unit files; routed verbs `systemctl` / `enable-service` / `sv-enable` / `add-crontab`; `systemctl enable` / `disable` / `mask`; `termux-services`. Domain `start`/`stop`/`restart` **may** invoke `systemctl` internally on POSIX Linux — `requirement-domain-sshd` §2.2.1.  

### 2.7 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): Unknown commands fail loud; force and prompts gate destructive ops; quiet/json never hide fatal errors incorrectly.  
- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): Every command has one privilege type, one handler, and documented flags.  
- **CIAO Principle 3 – Anti-fragile** (https://github.com/cloudgen/ciao): Works under TTY, `curl | sh`, quiet, and JSON; root vs user install paths.  
- **CIAO Principle 5 – Single Source of Output** and **Principle 14 – Security & Traceability** (https://github.com/cloudgen/ciao): Central `out_*`; JSON/human separation.  
- **CIAO Principle 6 – Single Point of Entry** (https://github.com/cloudgen/ciao): `app_main` is the dispatcher SSOT.  
- **CIAO Principle 10 – Least-Privilege User** (https://github.com/cloudgen/ciao): Type 0 default for CLI self-care; no invented system-user requirement for binary lifecycle.  
- **CIAO Principle 16 – Interactive vs Non-Interactive** (https://github.com/cloudgen/ciao): No hang in non-interactive; prompts only when appropriate.  
- **CIAO Principle 4 (O) / Principle 20 – Over-protect / Protect Against AI & Human Modification** (https://github.com/cloudgen/ciao): Protection Rule below blocks privilege and UX regressions.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Fail loud on bad input; never silent wrong privilege context.  
- **Intentional:** Command table + help + dispatcher stay synchronized.  
- **Anti-fragile:** Per-user and global install; network/remote optional until `SCRIPT_URL` set.  
- **Over-protect:** Do not collapse Type 0/1/2, remove JSON quiet contract, or reintroduce raw output for user messages.  
- **SSOT:** `APP_NAME` / `VERSION` / flags at config defaults; output via `out_*`; dispatch via `app_main`.  
- **Idempotency:** Already-installed install path is a no-op unless force reinstall.  
- **Respect old working logic:** Surgical changes only; preserve Protection Zones and battle-tested install/self-management helpers unless explicitly redesigning.

---

## Under command line for normal user only

When the ship unit detects a **command line for normal user only** (Termux, Git Bash, Windows cmd, or the same class):

| MUST | MUST NOT |
|------|----------|
| Keep **normal user privilege** (Type 0) only | Implement or enable **admin privilege** (Type 1) or **dedicated system user privilege** (Type 2) |
| Document Type 1 **unused** and Type 2 **unused** | In-tool `sudo`; wrap `apt` / `dnf` / `yum`; create a dedicated system user |
| Termux: named `pkg` as this login remains Type 0 | Recommend `sudo curl \| sh` as the install path |
| Git Bash / Windows cmd: same privilege ceiling | Invoke Termux `pkg` because Git Bash or Windows cmd was detected |

Helpers (this product): `sshd_is_termux`, `sshd_is_git_bash`, `sshd_is_windows_cmd`, `sshd_is_normal_user_only_cli`. Dual mention: `requirement-shell-termux-ish`.

**This requirement:** the command table Type 1 / Type 2 rows stay unused; detect lives in the dispatcher helpers; **MUST NOT** add Type 1 or Type 2 verbs on this class; **MUST NOT** invoke `systemctl` or add `termux-services` / cron-as-service verbs on that class. POSIX Linux `systemctl` for a distro ssh unit is **not** this class (`requirement-domain-sshd` §2.2.1).

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Remove or rename the normative Type 0 commands without updating this requirement and help together.  
2. Add Type 1 or Type 2 commands that mix host bootstrap with app toolchain in a single privileged install (three-layer privilege: Type 0 tool self-management must stay separate from Type 1 host bootstrap and Type 2 system-user app ops).  
3. Force manual `sudo` as the only UX for every elevated sub-step when internal escalation is the designed pattern (when Type 1 is introduced).  
4. Bypass `out_*` with raw user-facing `echo`/`printf` for normal messages.  
5. Break the contract that `--json` implies quiet and machine-oriented output.  
6. Drop **non-interactive** zero-arg install-ensure for the classic `curl | sh` path (including already-installed success no-op) without an explicit requirement change (`requirement-shell-cli-zero-arguments.md`). **MUST NOT** send a pipe empty argv to the TTY menu.  
7. Document flags in help that the dispatcher does not parse (or leave `--force` documented-only).  
8. Invent a dedicated system user as mandatory for Type 0 CLI self-management without a specialized architecture requirement.  
9. Implement or enable Type 1 (**admin privilege**) or Type 2 (**dedicated system user privilege**) when Termux, Git Bash, or Windows cmd is detected (command line for normal user only).  
10. Recommend `sudo curl | sh` or wrap `sudo` on that class.  
11. Strip the **Under command line for normal user only** section.  
12. Add routed verbs `systemctl` / `enable-service` / `termux-services` / `sv-enable` / `add-crontab`, or invoke `systemctl` on Termux / Git Bash / Windows cmd. POSIX Linux unit start/stop/restart stays on existing verbs (`requirement-domain-sshd` §2.2.1).  
13. Drop `wake-lock` / `wake-unlock` from the command table without updating `requirement-shell-termux-ish`, or auto-unlock on `stop`.  
14. Drop `rc-test` from the dual-mention table without updating `requirement-shell-path-and-shell-support`, mix it into operational help grouping, or treat it as install.  
15. Fail **`self-update`** after a successful CLI place because host `sshd -t` / `/etc/ssh/sshd_config` / `/run/sshd` failed.  
16. Treat TTY **62** / typed `version` on a numbered board as argv `app_version` (header reprint). TTY **MUST** run `about`. Argv `version` / JSON `"type":"version"` stay thin (**INC-20260914-001**).

**Violating this rule is a critical CLI interface regression.**

---

## 5. Definition of done (CLI interface)

This requirement is satisfied for the sshd-cli shell CLI when all of the following hold:

1. Every command in §2.6 is routed and documented, including test-purpose `rc-test`.  
2. Global flags in §2.6 are parsed and honored.  
3. Output modes match §2.4 (including JSON purity).  
4. Install privilege paths remain invoker-based (root/global vs user/local).  
5. No Type 1/2 surface claims exist without matching specialized requirements.  
6. Protection Rule items are not violated in code or docs.  
7. Traceability: implementation changes cite this file path / key `requirement-shell-cli-interface`.

---

## 6. Related artifacts

| Artifact | Role |
|----------|------|
| `docs/requirements/requirement-shell-self-management.md` | Lifecycle command semantics |
| `docs/requirements/requirement-shell-path-and-shell-support.md` | PATH / profile; `BASHRC`; `rc-test` |
| `docs/requirements/requirement-shell-output-requirements.md` | Output SSOT and channels |
| `docs/requirements/requirement-shell-interactive-vs-noninteractive.md` | TTY / automation mode behavior |
| `docs/requirements/requirement-shell-cli-zero-arguments.md` | Empty argv: TTY menu / non-TTY install-ensure |
| `docs/requirements/requirement-shell-idempotency.md` | Re-run safety for ensure ops |
| `docs/requirements/requirement-shell-modular-function-design.md` | Prefix ownership (`app_`, `inst_`, `out_*`) |
| `docs/requirements/requirement-shell-termux-ish.md` | Termux detect / `pkg`; Git Bash is same privilege class |
| `docs/requirements/requirement-shell-exit-condition.md` | Process exit catalog (unknown token EX-DIE-196) |
| `docs/requirements/index.md` | Registry SSOT |
| `./sshd-cli` | Implementation under test |

---

**Last Updated**: 2026-10-16 (1.14.16 product `VERSION="1.35.1"` and the MSYS reader uses the finished file. 1.14.15 MSYS2 / Git Bash gzip reader points at `requirement-shell-windows-git-bash-cli-coding`. Ship unit of that revision still piped. 1.14.14 product `VERSION="1.35.0"`. 1.14.13 front **5** sudoers **51–55**, front **6** self-management **61–67**, front **7** language **71–83**. Product `VERSION="1.34.0"`. 1.14.12 unknown-token exit points at `requirement-shell-exit-condition`. 1.14.11 product `VERSION="1.33.0"`. 1.14.10 language rows **51–63** (`ar`, `pt`, `ru`, `nl`, `el`). Product `VERSION="1.32.0"`. 1.14.9 front **5** language, block **50–69**. Product `VERSION="1.31.0"`. 1.14.8 `fix-config` and the automatic client-config pass. Product `VERSION="1.30.0"`. 1.14.7 language **67–68**; human help and about follow the saved language. 1.14.6 language **63–66**. 1.14.5 front **6** language. 1.14.4 `menu`/`main` handler is `app_cmd_menu`. Zero-cli-verb gate is live after flag parse. Prior: 2026-09-27 `about` cache lines)  
**Owner**: sshd-cli project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; CIAO Principles 1, 2, 3, 5, 6, 10, 16, 4, 20 (v2.10.2) (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
