**file**: docs/requirements/requirement-shell-termux-ish.md  
**Status**: Active (Version 1.2.1)  
**Area**: shell  
**Key**: `requirement-shell-termux-ish`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This is the **shell Termux-ish** law for **sshd-cli**: Termux-like userspace is the first home. Wrapping **named** `pkg` ensure as this login **is in scope**. This file owns detect, invoke contract, fail-closed, the fence that `pkg` is **not** Linux `apt`, and **Android wake lock** (auto-acquire on start plus Type 0 `wake-lock` / `wake-unlock`). Domain law names **which** packages (`openssh`, `termux-auth`) and when to start sshd.

A stated Termux sshd job **MUST NOT** be emptied by a portable habit of “do not wrap package managers.”

### 1.1 Human-facing

**In one sentence:** On Termux, `sshd-cli install` also runs `pkg` for the named OpenSSH packages as **you**; on ordinary Linux it does not run `apt`.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | The Termux (or POSIX) login that typed the command | `sshd-cli install` |
| The other role | Termux `pkg` writing into `$PREFIX` | `pkg install -y openssh termux-auth` |
| Not this file | Which sshd verbs exist; starting the daemon; placing **this** CLI file | `requirement-domain-sshd.md` · `requirement-shell-self-management.md` |

| Includes | Excludes |
|----------|----------|
| Detect Termux-ish; named `pkg install -y`; fail closed | Linux `apt` / `dnf` / `yum`; in-tool `sudo` |
| Keep `pkg` in scope when the purpose needs those packages | Unbounded `pkg` of unnamed packages; skip `pkg` because the CLI is already placed |
| Android wake lock: auto-acquire on `start`; `wake-lock` / `wake-unlock` | Termux:Boot as a substitute; auto-unlock on `stop`; systemd-inhibit |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./sshd-cli` | Program | `install` companion calls `sshd_pkg_ensure` |
| `sshd-cli help` | Command | `install` row names Termux packages |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Prepare Termux so sshd can exist | Place this program **and** ensure OpenSSH packages via `pkg` | `sshd-cli install` |
| Keep sshd listening with the screen off | Android may sleep Termux; this program acquires a wake lock on `start`. Acquire again if it was dropped. | `sshd-cli start` · `sshd-cli wake-lock` |
| Run the same command on Linux | CLI install only; no `apt` wrap; wake lock is a no-op | `sshd-cli install` |

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Detect

**MUST** treat the host as Termux-ish when any of: `PREFIX` contains `com.termux`; `TERMUX_VERSION` is set; `/data/data/com.termux/files/usr` exists. Helper: `sshd_is_termux`.

Termux is a **command line for normal user only**. Git Bash and Windows cmd are the same class (`sshd_is_git_bash` · `sshd_is_windows_cmd`; union helper `sshd_is_normal_user_only_cli`). On that class, **admin privilege** and **dedicated system user privilege** **MUST** stay unused. Dual mention: `requirement-shell-cli-interface`.

Off detect: **MUST NOT** invoke `pkg`; **MUST NOT** wrap `apt` / `dnf` / `yum`. Git Bash **MUST NOT** invoke `pkg`.

### 2.2 Named package list (closed)

| Package | Why | Owner of the name |
|---------|-----|-------------------|
| `openssh` | Provides `sshd` | `requirement-domain-sshd` |
| `termux-auth` | Password helper for Termux sshd | `requirement-domain-sshd` |

**MUST NOT** add unnamed packages. **MUST NOT** run `pkg upgrade`, unrelated `pkg uninstall`, or interactive `pkg search` as this companion.

### 2.3 Invoke

`install` **MUST** call `sshd_pkg_ensure` (via `inst_ensure_companion`) **before** the already-installed binary no-op. Dual mention: `requirement-shell-self-management` (call site) · `requirement-domain-sshd` (package names + start after) · `requirement-shell-cli-interface` (`install` row). **Non-interactive empty argv** and `self-install` **MUST NOT** call `sshd_pkg_ensure` (`requirement-shell-cli-self-install`).

| Host | MUST | MUST NOT |
|------|------|----------|
| **Termux-ish** | `pkg install -y openssh termux-auth` (quiet/json suppress pkg stdout) | Hang on prompts; skip because the CLI is already placed |
| **POSIX Linux** | No-op | Wrap `apt` / `dnf` / `yum` |
| **`pkg` missing** | Fail closed; Next: `pkg install openssh termux-auth` | Pretend sshd is ready |
| **`pkg` non-zero** | Fail closed; same Next | Continue as success |

Interactive empty argv is the menu and **MUST NOT** run package ensure as a side effect (`requirement-shell-cli-zero-arguments`).

**MUST NOT** treat this companion as Type 1 host bootstrap or host-mutating domain. It is this login into `$PREFIX`.

### 2.3.1 Android wake lock

sshd is a **background daemon**. On Termux, Android may sleep the CPU when the screen is off. This product **chooses both**: auto-acquire on `start` **and** Type 0 verbs to acquire again / release.

| Path | MUST | MUST NOT |
|------|------|----------|
| **Auto-acquire** | `sshd_cmd_start` (including already-running no-op and `restart`) calls `sshd_wake_lock_acquire` on Termux. Missing `termux-wake-lock`: **warn** + Next; **MUST NOT** fail sshd start solely for that. JSON/quiet: no second JSON object | Treat OpenSSH daemonize as a substitute; wrap systemd-inhibit |
| **`wake-lock`** | Type 0; idempotent; handler `sshd_cmd_wake_lock`. On Termux, missing helper → `out_die` with Next: `pkg install termux-tools` then `sshd-cli wake-lock`. Off-detect: success no-op | Hang; invoke because Git Bash or Windows cmd was detected |
| **`wake-unlock`** | Type 0; handler `sshd_cmd_wake_unlock`; operator-owned. Off-detect: success no-op | Auto-call from `stop` (lock is Termux-app-wide) |
| **Git Bash / Windows cmd / POSIX Linux** | Skip | Call `termux-wake-lock` / `termux-wake-unlock` |

Dual mention: `requirement-shell-cli-interface` (verb rows) · `requirement-domain-sshd` (`start` companion).

**Invocation samples:**

```sh
sshd-cli start
sshd-cli wake-lock
sshd-cli wake-unlock
sshd-cli --json wake-lock
```

### 2.4 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Product | `sshd-cli` 1.8.0 |
| Detect | `sshd_is_termux` |
| Class union | `sshd_is_normal_user_only_cli` (Termux **or** Git Bash **or** Windows cmd) |
| Git Bash | `sshd_is_git_bash` — no `pkg`; no `termux-wake-lock` |
| Windows cmd | `sshd_is_windows_cmd` — no `pkg`; no `termux-wake-lock` |
| Helper | `sshd_pkg_ensure` |
| Call site | `inst_ensure_companion` on `install` / non-interactive empty-argv |
| Named list | `openssh` · `termux-auth` |
| Android wake lock | **both** auto-acquire on `start` (`sshd_wake_lock_acquire`) **and** verbs `wake-lock` / `wake-unlock`. Helper: `termux-wake-lock` / `termux-wake-unlock` (typical `termux-tools`). **MUST NOT** auto-unlock on `stop` |
| Linux | no-op (no `apt`; wake lock no-op) |
| In-tool sudo | none |

#### Worked samples (this project)

```sh
sshd_is_termux() {
    : "${PREFIX:=}"
    if [ -n "${PREFIX}" ] && [ -d "${PREFIX}/bin" ]; then
        case "${PREFIX}" in
            */com.termux/*) return 0 ;;
        esac
    fi
    if [ -n "${TERMUX_VERSION-}" ] || [ -d /data/data/com.termux/files/usr ]; then
        return 0
    fi
    return 1
}

sshd_is_normal_user_only_cli() {
    sshd_is_termux && return 0
    sshd_is_git_bash && return 0
    sshd_is_windows_cmd && return 0
    return 1
}
```

`sshd_pkg_ensure`: on Termux `pkg install -y openssh termux-auth` (quiet/json suppress stdout); missing `pkg` / non-zero → `out_die` with Next. Off-Termux: return 0. Git Bash / Windows cmd **MUST NOT** call this helper’s `pkg` path (union detect returns before `pkg`).

Wake lock: `sshd_termux_wake_lock_invoke` returns 0 acquired / 1 not Termux / 2 helper missing / 3 helper failed. `sshd_wake_lock_acquire` on `start`: not-Termux no-op; missing helper **warn**. Verb `wake-lock`: missing helper **`out_die`**. **MUST NOT** auto-unlock on `stop`.

### 2.5 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): Termux `pkg` and Linux `apt` are named as different tools.  
- **CIAO Principle 9 – Type 0/1/2** (https://github.com/cloudgen/ciao): Privilege follows who/where; `pkg` as this login is not Type 1.  
- **CIAO Principle 10 – Least privilege** (https://github.com/cloudgen/ciao): No sudo for Termux `pkg`.  
- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): Fail closed on missing/`pkg` error.  
- **CIAO Principle 21 – Dual policies** (https://github.com/cloudgen/ciao): Portable core; filled notes.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: Do not pretend OpenSSH exists after `pkg` fail.  
- **Intentional**: Purpose “simplify Termux to install sshd” includes `pkg`.  
- **Anti-fragile**: Works when systemd and root are absent (Termux).  
- **Over-protect**: Never wrap Linux `apt` as a shortcut; never unbounded `pkg`.

## Under command line for normal user only

When the ship unit detects a **command line for normal user only** (Termux, Git Bash, Windows cmd, or the same class):

| MUST | MUST NOT |
|------|----------|
| Keep **normal user privilege** (Type 0) only | Implement or enable **admin privilege** (Type 1) or **dedicated system user privilege** (Type 2) |
| Document Type 1 **unused** and Type 2 **unused** | In-tool `sudo`; wrap `apt` / `dnf` / `yum`; create a dedicated system user |
| Termux: named `pkg` as this login remains Type 0 | Recommend `sudo curl \| sh` as the install path |
| Git Bash / Windows cmd: same privilege ceiling | Invoke Termux `pkg` because Git Bash or Windows cmd was detected |

Helpers (this product): `sshd_is_termux`, `sshd_is_git_bash`, `sshd_is_windows_cmd`, `sshd_is_normal_user_only_cli`. Dual mention: `requirement-shell-cli-interface`.

**This requirement:** `pkg` and `termux-wake-lock` run only on Termux detect; Git Bash and Windows cmd are the same privilege class and **MUST NOT** invoke `pkg` or `termux-wake-lock`; **MUST NOT** invoke `systemctl` on this class (POSIX Linux unit path is `requirement-domain-sshd` §2.2.1). This companion is not Type 1 host bootstrap.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. List wrapping Termux `pkg` as a non-goal, or lump it with wrapping `apt`.  
2. Skip `pkg install -y openssh termux-auth` on Termux `install` / non-interactive empty-argv because the CLI binary is already placed.  
3. Treat Termux `pkg` as Type 1 host bootstrap or as in-tool sudo.  
3b. Enable Type 1 or Type 2 on Termux, Git Bash, or Windows cmd, or invoke `pkg` because Git Bash or Windows cmd was detected.  
4. Wrap Linux `apt` / `dnf` / `yum` because Termux `pkg` is in scope.  
5. Run unnamed `pkg` subcommands as this companion.  
6. Empty a stated Termux install/manage purpose with a portable “do not wrap package managers” habit.  
7. Strip the **Under command line for normal user only** section.  
8. Skip Android wake lock on Termux `start`, auto-unlock on `stop`, invoke `termux-wake-lock` on Git Bash / Windows cmd, or treat Termux:Boot / `termux-services` as the wake lock.

## 5. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-domain-sshd.md` | Package names; start sshd after |
| `docs/requirements/requirement-shell-self-management.md` | `inst_ensure_companion` call site |
| `docs/requirements/requirement-shell-cli-interface.md` | Dual mention `install`; not Type 1 |
| `docs/requirements/requirement-shell-cli-zero-arguments.md` | Interactive empty argv is not pkg-ensure |
| `docs/requirements/requirement-shell-idempotency.md` | Re-run `pkg` must not hang |
| `docs/requirements/requirement-class-software-dev.md` | Class residual points here |
| `docs/requirements/requirement-shell-termux-cli-coding.md` | How to write the CLI on Termux (one detect). This file still owns `pkg` and the wake lock |
| `./sshd-cli` | Implementation |

## 6. Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-LC-15** | `tests/test_local_lifecycle.sh` | have |
| **TP-LC-16** | `tests/test_local_lifecycle.sh` | have |
| **TP-LC-18** | `tests/test_local_lifecycle.sh` | have |
| **TP-LC-19** | `tests/test_local_lifecycle.sh` | have |
| **TP-TX-08** .. **TP-TX-16** | `tests/test_local_lifecycle.sh` | have |
| **TP-CLI-04** (`wake-lock` in help) | `tests/test_cli.sh` | have |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

**Last Updated**: 2026-10-14 (1.2.1 points at `requirement-shell-termux-cli-coding` for Termux CLI coding. `pkg` and the wake lock stay here. 2026-09-07)  
**Owner**: Cloudgen Wong  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
