**file**: docs/requirements/requirement-shell-cli-self-install.md  
**Status**: Retired (Python generation 2.0.0. The live ship unit is the SshCli package. This file records the /bin/sh ship unit through 1.35.1. Where it disagrees with requirement-domain-sshd 1.28.0 or an Active requirement-python-*.md / requirement-runtime-prerequisites.md file, those win.) Was  (Version 1.1.2)  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the product law for **how sshd-cli places itself**: the `self-install` verb, and a **non-interactive zero-cli-verb** (`curl | sh`, `--quiet` or `--json` with no verb, no TTY). That path puts the program file on disk (or says it is already there). It does **not** install OpenSSH, does **not** start sshd, and does **not** print help. Switches are not a verb. An interactive zero-cli-verb is the main menu, not this path.

Payload (Termux packages, start sshd, login rc companion as part of domain setup) stays on explicit `install`.

### 1.1 Human-facing

**In one sentence:** A pipe with no extra words copies **this program** into your bin; if you already ran the file (`./sshd-cli self-install`), it copies **that file** and does not download.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | First-time pipe, or a checkout you already have | `curl … \| sh` · `./sshd-cli self-install` |
| The other role | Payload / sshd packages / start | `sshd-cli install` |
| Not this file | TTY numbered menu; checksum math; `self-update` channel compare | `requirement-shell-cli-zero-arguments.md` · `requirement-shell-self-management.md` |

| Includes | Excludes |
|----------|----------|
| `self-install`; non-interactive zero-cli-verb CLI place (no verb; switches allowed); copy when `$0` is the script; dest mode 0700 local / 0755 global | Payload `pkg`; start sshd; interactive zero-cli-verb menu |
| Already-installed success no-op | Help as empty-argv default |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./sshd-cli` | Ship unit | Copy source when you run it |
| `sshd-cli self-install` | Command | Same ensure as a pipe with no args |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| First install from the internet | The pipe has no human to answer. The program **places itself** (user bin, or system bin if you are root). OpenSSH is a later step. | `curl -fsSL https://raw.githubusercontent.com/cloudgen/sshd-cli/main/sshd-cli \| /bin/sh` |
| Install from a file you already have | `$0` is the script, not `sh`. Copy that file into bin. No network. | `./sshd-cli self-install` · `sh ./sshd-cli self-install` |
| Payload after the CLI is there | Packages + start sshd. Not the pipe default. | `sshd-cli install` |

Jargon: **Type O** (letter) means a non-interactive **zero-cli-verb** **places the CLI**. That is not Type **0** (you run as yourself). On a real terminal, with quiet and json off, no command is the **main menu**.

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Route

1. When the line is a **zero-cli-verb** (no verb after switches) and the run is **non-interactive** (no TTY, or `JSON=1`, or `QUIET=1`), `app_main` **MUST** call `inst_self_install` — **MUST NOT** call `inst_perform_install`, **MUST NOT** open the menu, **MUST NOT** call `app_help`. `sshd-cli --quiet` and `sshd-cli --json` with no verb are this rule.  
2. `sshd-cli self-install` **MUST** call `inst_self_install`.  
3. `sshd-cli install` remains payload (companion + start) — dual mention `requirement-shell-self-management` · `requirement-domain-sshd`.  
4. Interactive zero-cli-verb remains the main menu — `requirement-shell-cli-zero-arguments` · `requirement-shell-cli-default-interaction`.

### 2.2 `$0` source

| `$0` | Place |
|------|-------|
| Interpreter basename `sh` `bash` `dash` `ash` `zsh` `ksh` `mksh` `yash` `posh` `csh` `tcsh` `fish` `busybox` (login dash prefix stripped; paths like `/bin/sh` count) | Download from `SCRIPT_URL` + companion digest |
| Readable regular file (`./sshd-cli`, `sh /path/to/sshd-cli`) | **Copy** that file — **MUST NOT** download |
| Basename-only, `command -v` finds a readable file | Copy that file |

### 2.3 Copy (no download)

1. Resolve an absolute readable path of the running script.  
2. `mktemp -t` under isolated `TMPDIR` (storage resolver): leaf `sshd-cli-XXXXXX`.  
3. `cp` source → stage.  
4. `chmod` dest mode on stage **before** `mv`. **MUST NOT** `chmod +x` alone.  
5. `mv` onto `INSTALL_PATH`.  
6. `chmod` dest mode on dest.  
7. **MAY** run PATH rc ensure (`path_add_shell`). **MUST NOT** `sshd_pkg_ensure`. **MUST NOT** `sshd_start_after_install`.

### 2.4 Dest mode

| Invoker | Path | Mode |
|---------|------|------|
| root | `${GLOBAL_BIN}/sshd-cli` | **0755** |
| non-root | `${USER_BIN}/sshd-cli` | **0700** |

### 2.5 Already installed

Force off → `out_success` already installed; exit 0; no re-copy; no download; no payload. Force → replace via copy or download per `$0`.

### 2.6 Implementation Notes (this product)

| Item | Value for sshd-cli |
|------|-------------------|
| **Handler** | `inst_self_install` |
| **Detect** | `inst_argv0_is_shell_interpreter` · `inst_resolve_self_script` |
| **Copy** | `inst_self_install_copy_from_script` |
| **Download peer** | `inst_perform_install_download_*` + `inst_perform_install_atomic_install` then dest-mode chmod |
| **PATH** | `path_add_shell` on this path (CLI on PATH). Package + start stay on `install`. |
| **Dispatcher** | `app_main` non-interactive zero-cli-verb → `inst_self_install`; command `self-install` same |
| **TTY menu** | Self-management **67** `self-install` |
| **Global bin** | `/usr/local/bin` or `${PREFIX}/bin` on Termux |
| **Local bin** | `${HOME}/.local/bin` |
| **Tests** | `tests/test_cli.sh` **TP-SI-01** .. **TP-SI-06** · **TP-CLI-23** |

#### Dispatcher sample

```sh
# Zero-cli-verb after switch parse. Switches are not a verb.
# Interactive → menu. Non-interactive → inst_self_install.
# Ship unit: no-token fast path, and the same split after flag parse.
if [ -z "${COMMAND-}" ]; then
    if [ "${TTY}" -eq 1 ] && [ "${JSON}" -eq 0 ] && [ "${QUIET}" -eq 0 ]; then
        app_cmd_menu
        exit $?
    fi
    inst_self_install
    exit $?
fi
```

#### Invocation samples

| Verb | Sample |
|------|--------|
| zero-cli-verb (pipe) | `curl -fsSL https://raw.githubusercontent.com/cloudgen/sshd-cli/main/sshd-cli \| /bin/sh` |
| zero-cli-verb (quiet / json, no verb) | `sshd-cli --quiet` · `sshd-cli --json` |
| `self-install` | `sshd-cli self-install` · `./sshd-cli self-install` |

### 2.x Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): Copy does not need a live channel; download still verifies.  
- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): Pipe = CLI place; `install` = payload.  
- **CIAO Principle 3 – Anti-fragile** (https://github.com/cloudgen/ciao): Checkout works offline.  
- **CIAO Principle 6 – Single Point of Entry** (https://github.com/cloudgen/ciao): `app_main` owns empty argv.  
- **CIAO Principle 16 – Interactive vs Non-Interactive** (https://github.com/cloudgen/ciao): TTY menu vs pipe place.  
- **CIAO Principle 22 – File modes** (https://github.com/cloudgen/ciao): 0755 global / 0700 local.

## Under command line for normal user only

When Termux, Git Bash, Windows cmd, or the same class is detected: Type 1/2 unused; no in-tool sudo; no `sudo curl | sh`. **This requirement:** self-install stays this-login place (local **0700**, or Termux `$PREFIX/bin` when that directory is the global dest). Git Bash and Windows cmd do not invoke Termux `pkg` on this path.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Fail closed on copy/download I/O.  
- **Intentional:** One meaning for NI empty argv.  
- **Anti-fragile:** Script `$0` does not need curl.  
- **Over-protect:** Interpreter list; dest-mode table; no payload on this path.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Route non-interactive empty argv to `inst_perform_install` (payload + start).  
2. Download when `$0` is a readable script.  
3. Start sshd or run `pkg` from `inst_self_install`.  
4. Leave local dest **0711** or global dest **0700**/**0711** on this path.  
5. Drop `self-install` from help or dispatcher.  
6. Basename-gate main so `curl | sh` never reaches `inst_self_install`.  
7. Strip **Under command line for normal user only**.

## 5. Definition of done

1. NI empty argv places the CLI (copy or download per `$0`) without payload start.  
2. `./sshd-cli self-install` with a dead `SCRIPT_URL` still places (copy).  
3. Local dest **0700**; global dest **0755**.  
4. Already-installed no-op.  
5. Help lists `self-install`.  
6. Tests **TP-SI-01** .. **TP-SI-06**.  
7. Changes cite this file.

### Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-SI-01** script `$0` copy, no network | `tests/test_cli.sh` | have |
| **TP-SI-02** local dest **0700** | `tests/test_cli.sh` | have |
| **TP-SI-03** NI empty argv not payload | `tests/test_cli.sh` | have |
| **TP-SI-04** interpreter `$0` download | `tests/test_cli.sh` | have |
| **TP-SI-05** already-installed no-op | `tests/test_cli.sh` | have |
| **TP-SI-06** help lists `self-install` | `tests/test_cli.sh` | have |
| **TP-CLI-23** `--quiet` / `--json` / non-TTY `--debug` with no verb place the CLI | `tests/test_cli.sh` | have |

**Map:** `reviews/test-plan.md`

## 6. Related artifacts

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry |
| `docs/requirements/requirement-shell-cli-zero-arguments.md` | TTY menu vs NI place |
| `docs/requirements/requirement-shell-cli-interface.md` | Dual mention `self-install` |
| `docs/requirements/requirement-shell-self-management.md` | `install` payload + `self-update` |
| `docs/requirements/requirement-domain-sshd.md` | Payload packages + start |
| `docs/requirements/requirement-shell-termux-ish.md` | `pkg` on `install` only |
| `./sshd-cli` | Implementation |

**Last Updated**: 2026-10-14 (1.1.2 self-management row **67** `self-install`. 1.1.1 interactive empty command calls `app_cmd_menu`)  
**Owner**: sshd-cli project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
