# Requirements

Authoritative product and engineering requirements for this project live here.

**Current state (2026-10-14 — sshd-cli 1.35.0):** sshd-cli is a Termux-first helper that installs and runs OpenSSH sshd. Termux: background daemon (`sshd -f`) plus Android wake lock. POSIX Linux with a loaded distro unit: `start` / `stop` / `restart` use `systemctl` (root login; no in-tool `sudo`; no routed `systemctl` verb). This login’s `~/.ssh/config` Host list (`dns`) includes **`unset`**. **`ssh`** (client **12**) opens an OpenSSH client session; on Termux, `old-openssh yes` writes `HostKeyAlgorithms` / `PubkeyAcceptedAlgorithms` as comments, and `ssh` adds `-o HostKeyAlgorithms=+ssh-rsa` when those lines are comments. **`download`** (client **13**) tar.gz a remote folder into cwd; **`upload`** (client **14**) tar.gz a **local** folder onto that Host (extract under the remote login home). Both are routed (**TP-UL-01** .. **TP-UL-18** have). Non-interactive **zero-cli-verb** (no verb after switches; `--quiet` / `--json` with no verb included) and `self-install` place the CLI only (`requirement-shell-cli-self-install`); an interactive zero-cli-verb opens the numbered main menu (`requirement-shell-cli-default-interaction`); payload stays `install`. Cache folder is per login and per process (`cache-${APP_NAME}-${login}-$$` under `/dev/shm/cache` on Linux, including Termux). Git Bash and Mac prefer `/tmp/cache`. A skipped tier is silent. Persistence stays `${HOME}/.local/${APP_NAME}`. TTY sudoers is front **5** (verbs **51–55**); Termux / Git Bash / Windows cmd hide that row. Each hide cause is a **menu-hidden message** printed before that layer’s numbered items (client backup/sync, non-root server start/stop/restart, and the front-board sudoers hide do this). Every menu layer reads its choice in the current shell (**do not capture `read`**). The menu requirement quotes those live board functions from `./sshd-cli` (`app_cmd_menu` and the child boards). Front **7** Language reserves **70–89** for not more than 20 languages and assigns **71** English (`en`), **72** Simplified Chinese (`zh-Hans`), **73** Traditional Chinese (`zh-Hant`), **74** Spanish (`es`), **75** Arabic (`ar`), **76** French (`fr`), **77** Portuguese (`pt`), **78** Russian (`ru`), **79** German (`de`), **80** Japanese (`ja`), **81** Korean (`ko`), **82** Dutch (`nl`), and **83** Greek (`el`) for that menu. **70** and **84–89** are reserved and are not printed. Front **8** is not a row, and human help and about follow the same code (`requirement-shell-cli-language`); the file is `${HOME}/.local/${APP_NAME}/language`. Worked samples of each front board and of the opening of `help` and `about`, and the translation tables, are in that file. TTY numbered menus warn and redisplay on an unknown choice. `backup-config` / `sync-config` / `sync-from-remote` and sudoers grant live on **`requirement-shell-config-backup`** / **`requirement-shell-sudoer`**. `install` PATH ensure honors `BASHRC` (default `~/.bashrc`). Scratch/cache mkdir is fail-soft. Shell-rc law lives on **`requirement-shell-path-and-shell-support`**. **dns** as-Termux Host writes simpler Ciphers/MACs so slow Termux sshd does not abort with Connection corrupted. Alpine OpenSSH rejects an active `GSSAPIAuthentication` (`Unsupported option "gssapiauthentication"`). `fix-config` comments that family on Alpine, comments `HostKeyAlgorithms` / `PubkeyAcceptedAlgorithms` / `PubkeyAcceptedKeyTypes` on Termux, and leaves both families active on another OS. Every run applies that pass to `~/.ssh/config`. **dns** add and update use the same comment rule (`requirement-domain-sshd` 1.27.1). Law lives in **one** class file (`requirement-class-software-dev`), **twenty-four** shell files (including **cli-language**, **cli-self-install**, **script-coding**, **fedora-redhat-cli-coding**, **debian-cli-coding**, **macos-cli-coding**, **termux-cli-coding**, **windows-git-bash-cli-coding**, **termux-ish**, **path-and-shell-support**, **sudoer**, and **config-backup**), **three** pointer files (`requirement-sshd-config-backup`, `requirement-sudoer-json-file`, `requirement-three-layer-privilege-model`), and **one** domain file (`requirement-domain-sshd`). Registry: `index.md`. Specialized from bootstrap origin **selfmanaged** (A → B). You run as yourself (catalog: Type 0). Product version SSOT: `VERSION="1.35.0"`. When sshd is missing, POSIX Linux names `dnf` (Fedora and RHEL) and `apt` (Debian and Ubuntu) and says this program does not run that command. Git Bash, Windows cmd, and macOS each have their own next step. Termux still uses `sshd-cli install`. TTY `ssh`, `download`, and `upload` prompt user with default; **`download`** remote `~/folder` is the ssh user home; **`upload`** local `~/folder` is this login. Do **not** invent additional requirement paths without a real ownership gap — verify on disk and register new files in `index.md` in the same change.

## Purpose

- **Plan mode** designs work by reading and **updating** these docs — not only the session `plan.md`.
- **Implement** delivers code and docs that **trace** to requirement IDs.
- **Review** verifies delivery against requirements **and** defensive (CIAO) checklists.

## Layout

| Path | Role |
|------|------|
| `docs/requirements/index.md` | Registry of all requirements (IDs, status, owners) — keep in sync with files |
| `docs/requirements/requirement-*.md` | CIAO-style project requirements (flat; primary live convention) |
| `docs/requirements/<area>/<REQ-ID>.md` | Optional council-style `REQ-<AREA>-<NNN>` files |

Suggested areas (if using subdirs): `product/`, `platform/`, `security/`, `ops/` — create as needed.

## ID scheme

- **Primary live convention:** `requirement-<topic>.md` or `requirement-<language>-<topic>.md` (e.g. `requirement-shell-cli-interface.md`, `requirement-class-software-dev.md`).
- Optional council-style: `REQ-<AREA>-<NNN>` (example: `REQ-PLAT-001`) if using area subdirs.
- IDs/keys are stable. Prefer status/`supersedes` over renumbering.
- Record every key in `index.md` when created or status changes.

## Status values

Live product law on this project uses the **file header Status** (and matching registry **Status** column):

| Status | Meaning |
|--------|---------|
| `Active` | Normative product law — implement and review against it |
| `Draft` | Proposed; not yet approved as binding law |
| `Deprecated` | No longer active; keep file for history |
| `Superseded` | Replaced by another requirement key (link it) |

Legacy/council synonyms sometimes seen in older docs (`approved`, `in-progress`, `done`) map to **Active** when the file is registered and binding. Prefer **Active** for this registry.

## Plan-mode rules (mandatory)

When planning non-trivial work:

1. Search `docs/requirements/` (and `index.md`) for related requirements.
2. Decide: **new requirement**, **update existing**, or **no requirements impact** (state why).
3. Apply requirement file changes **before** or as part of finishing the plan.
4. Session plan (`plan.md`) must list affected REQ-IDs and whether each is create / update / no-change.
5. Do not implement against unstated intent — if behavior is required, it belongs in a requirement file.

## Implementation rules

- Every non-trivial PR/change set cites one or more REQ-IDs in commit/PR/summary when requirements exist.
- Do not invent requirements only in code comments; promote durable intent here.
- **No placeholders** in requirement files: no `TBD`/`TODO` acceptance criteria, hollow sections, or stub “later” text. See `AGENTS.md` → **No-placeholder policy**.
- Product source comments cite only **live** `requirement-*.md` files (never invent basenames).

## Review rules

- Requirements changes and code/docs delivery use the project’s plan/implement/code-review/security checklist process.
- Empty registry is valid for genesis; do not invent requirements to “fill” the index.
- Software-development class requires Active `requirement-class-software-dev.md` in the registry.
