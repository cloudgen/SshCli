**file**: docs/requirements/requirement-shell-windows-git-bash-cli-coding.md  
**Status**: Active (Version 1.0.0)  
**Area**: shell  
**Key**: `requirement-shell-windows-git-bash-cli-coding`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This is the **Windows Git Bash CLI coding** home for sshd-cli. It says how to write `./sshd-cli` when Git for Windows (MSYS / MINGW) is the shell. The script stays POSIX `/bin/sh` inside that shell. It does not become a `cmd.exe` or PowerShell program.

Windows cmd is a different detect (`sshd_is_windows_cmd`). This file does not own it. Both detects share the normal-user-only privilege ceiling.

### 1.1 Human-facing

**In one sentence:** Under Git Bash, the CLI hides sudoers, does not run `pkg` or `systemctl`, and stores cache under `/tmp/cache` then AppData.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Someone in Git Bash changing `./sshd-cli` | `MSYSTEM=MINGW64` |
| The other role | Windows cmd | `sshd_is_windows_cmd` (not this file) |
| Not this file | Termux `pkg`; the cache path table | `requirement-shell-termux-ish.md` · `requirement-shell-cli-storage.md` |

| Includes | Excludes |
|----------|----------|
| `sshd_is_git_bash` coding fence; cache kind `gitbash` | Rewriting the CLI as a `.bat` or PowerShell script |
| No `pkg`, no `systemctl`, no `/dev/shm` preference | Windows cmd detect and its tests |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./sshd-cli` | Ship unit | `sshd_is_git_bash` |
| Front menu | Hide cause | `sudoers not available for gitbash` |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Run in Git Bash | Omit sudoers; do not call `pkg` | `sshd-cli` with no verb, on a terminal |
| Read cache | `/tmp/cache`, then AppData; no 2nd fallback | `sshd-cli about` |

---

## 2. Core Rules / Requirements (Mandatory)

1. **MUST** detect Git Bash for privilege and menu hides with `sshd_is_git_bash`: `MSYSTEM` is `MINGW*`, `MSYS*`, `UCRT*`, or `CLANG*`, or `uname -s` is `MINGW*` or `MSYS*`. **MUST NOT** add a second privilege detect.  
2. Cache kind **MUST** stay `util_cache_host_kind`. Any non-empty `MSYSTEM` is kind `gitbash`, as is `uname -s` `MINGW*` / `MSYS*`. Test override `SSHD_CLI_CACHE_HOST=gitbash` **MUST** stay a test hook. **MUST NOT** merge this helper into `sshd_is_git_bash` or the reverse. They answer different questions.  
3. **MUST NOT** treat Git Bash as Windows cmd. `sshd_is_windows_cmd` returns false when `sshd_is_git_bash` is true. Hide sentences use the token `gitbash`, not `windows-cmd`.  
4. This host **MUST** stay a command line for normal user only. **MUST NOT** call `sudo`, `systemctl`, `apt`, `dnf`, `yum`, `pkg`, or `termux-wake-lock` because Git Bash was detected.  
5. **MUST NOT** add `gitbash` to `sshd_fix_os_class`. That helper stays `alpine`, `termux`, or `posix`. Git Bash is `posix` unless Termux detect wins or `/etc/os-release` `ID` / `ID_LIKE` contains `alpine`. **MUST NOT** comment Termux algorithm keywords because the shell is Git Bash.  
6. Cache coding **MUST** use the Git Bash chain in `requirement-shell-cli-storage`: `/tmp/cache/cache-${APP_NAME}-${login}-$$`, then `${HOME}/AppData/Local/Temp/cache-${APP_NAME}-$$`. There is **no** 2nd fallback. **MUST NOT** prefer `/dev/shm/cache` and **MUST NOT** print a 2nd-fallback about line for this kind.  
7. Paths inside the script **MUST** stay MSYS paths (`/tmp`, `/c/...` as Git Bash shows them). **MUST NOT** build commands for `cmd.exe`, PowerShell, or `wsl.exe`.  
8. Menu coding **MUST** follow the live boards: front **5** hidden with `[INFO] sudoers not available for gitbash` before the numbers; client backup/sync hidden with `backup-config and sync-config not available for gitbash`; client **18** `sync-from-remote`; server **22–24** shown for this login. Sentence text and numbers stay on `requirement-shell-cli-default-interaction` and `requirement-domain-sshd`.  
9. The script **MUST** stay POSIX `/bin/sh`. **MUST NOT** require Bash `[[ ]]` as the only form, bash arrays, or GNU `grep -P`. In-place `sed` **MUST** use `sed -i.bak`.  
10. Portable style stays on `requirement-shell-script-coding`.  
11. When sshd is missing, `sshd_openssh_server_hint` **MUST** say Git Bash does not provide sshd. **MUST NOT** tell that shell to run `apt` or `dnf`. Windows cmd is the next branch in that same helper (`Windows cmd does not provide sshd`). This file does not own the cmd detect.

### 2.1 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Privilege detect | `sshd_is_git_bash` |
| Cache kind | `gitbash` via `util_cache_host_kind` (any non-empty `MSYSTEM`) |
| Menu token | `gitbash` |
| OS class | not a `sshd_fix_os_class` value |
| Privilege | Type 0 only |
| Package / wake lock | not invoked |
| Service manager | not used |
| Windows cmd | `sshd_is_windows_cmd` — out of this file |
| In-tool sudo | none |

### 2.2 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): Git Bash and Windows cmd are different detects with one privilege ceiling.  
- **CIAO Principle 9 – Type 0/1/2** (https://github.com/cloudgen/ciao): This shell stays Type 0.  
- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): `/dev/shm` is not the Git Bash cache.  
- **CIAO Principle 21 – Dual policies** (https://github.com/cloudgen/ciao): Storage owns the path table; this file owns the coding fence.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: `MSYSTEM` means cache kind `gitbash` even when the privilege helper’s prefix list is what the menu uses. Do not collapse the two helpers.  
- **Intentional**: The hide token is `gitbash`.  
- **Anti-fragile**: The CLI runs with no Windows service manager and no `pkg`.  
- **Over-protect**: Do not rewrite the ship unit as PowerShell.

## Under command line for normal user only

When the ship unit detects a **command line for normal user only** (Termux, Git Bash, Windows cmd, or the same class):

| MUST | MUST NOT |
|------|----------|
| Keep **normal user privilege** (Type 0) only | Implement or enable **admin privilege** (Type 1) or **dedicated system user privilege** (Type 2) |
| Document Type 1 **unused** and Type 2 **unused** | In-tool `sudo`; wrap `apt` / `dnf` / `yum`; create a dedicated system user |
| Termux: named `pkg` as this login remains Type 0 | Recommend `sudo curl \| sh` as the install path |
| Git Bash / Windows cmd: same privilege ceiling | Invoke Termux `pkg` because Git Bash or Windows cmd was detected |

Helpers (this product): `sshd_is_termux`, `sshd_is_git_bash`, `sshd_is_windows_cmd`, `sshd_is_normal_user_only_cli`. Dual mention: `requirement-shell-cli-interface` · `requirement-shell-termux-ish`.

**This requirement:** Git Bash **is** this class. Coding for that shell **MUST** use `sshd_is_git_bash` for menu hides and **MUST NOT** call `pkg`. Windows cmd remains `sshd_is_windows_cmd` and is not re-specified here.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Merge `sshd_is_git_bash` and `util_cache_host_kind` into one helper.  
2. Use the token `windows-cmd` for a Git Bash hide sentence.  
3. Call `pkg`, `termux-wake-lock`, `sudo`, `systemctl`, `apt`, or `dnf` on Git Bash.  
4. Prefer `/dev/shm/cache` or print a 2nd cache fallback for kind `gitbash`.  
5. Add `gitbash` to `sshd_fix_os_class`.  
6. Rewrite `./sshd-cli` as `cmd.exe`, PowerShell, or a WSL launcher.  
7. Strip the **Under command line for normal user only** section.

## 5. Definition of done

1. Menu hides on Git Bash use the token `gitbash` and `sshd_is_git_bash`.  
2. `install` on a Git Bash mock does not call `pkg`.  
3. Cache kind `gitbash` uses `/tmp/cache` then AppData and an empty 2nd fallback.  
4. The ship unit is still POSIX `/bin/sh`.

## 6. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry |
| `docs/requirements/requirement-shell-script-coding.md` | Portable style |
| `docs/requirements/requirement-shell-cli-storage.md` | Git Bash cache path table |
| `docs/requirements/requirement-shell-termux-ish.md` | `pkg` must not run here |
| `docs/requirements/requirement-shell-termux-cli-coding.md` | Termux detect; not Git Bash |
| `docs/requirements/requirement-shell-cli-default-interaction.md` | Front **5** hide sentence |
| `docs/requirements/requirement-domain-sshd.md` | Client **18**; no `systemctl` on this class |
| `./sshd-cli` | `sshd_is_git_bash`, `util_cache_host_kind` |

## 7. Design-time verification

| TP family / ID | What it shows | Status |
|----------------|---------------|--------|
| **TP-CFG-05** | Git Bash backup INFO and `sudoers not available for gitbash`; omits sudoers row | have |
| **TP-CLI-12** | Git Bash cache `/tmp/cache` then AppData; empty 2nd fallback | have |
| **TP-LC-18** | Git Bash `install` does not call `pkg` | have |
| **TP-SSHD-17** | Git Bash missing-sshd hint does not name `apt` | have |
| **TP-LC-19** | Windows cmd `install` does not call `pkg` | have on the cmd detect; not this file’s ownership |

This file adds no new test.

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

**Last Updated**: 2026-10-14 (1.0.0 family coding home)  
**Owner**: Cloudgen Wong  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
