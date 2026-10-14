**file**: docs/requirements/requirement-shell-macos-cli-coding.md  
**Status**: Active (Version 1.0.1)  
**Area**: shell  
**Key**: `requirement-shell-macos-cli-coding`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This is the **macOS CLI coding** home for sshd-cli. It says how to write `./sshd-cli` when `uname -s` is `Darwin`. The ship unit does not have a macOS OpenSSH class. Keyword commenting stays `posix` unless the process is Termux or Alpine. Cache tiers for Mac are already law on `requirement-shell-cli-storage`. This file owns the coding fence: no `brew`, no `launchctl`, no `systemctl`, and digest tools stay in `util_sha256_file`.

### 1.1 Human-facing

**In one sentence:** On a Mac, the CLI uses the Mac cache folders, hashes with `shasum` when `sha256sum` is missing, and does not call Homebrew or `launchctl`.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Someone changing `./sshd-cli` for Darwin | Cache kind `mac` |
| The other role | OpenSSH fallback when systemd is absent | Domain start path |
| Not this file | The cache path table; Linux `systemctl` | `requirement-shell-cli-storage.md` · `requirement-domain-sshd.md` |

| Includes | Excludes |
|----------|----------|
| Darwin detect for cache; `sed -i.bak`; digest tool order | A `macos` value in `sshd_fix_os_class` |
| No `brew` / `launchctl` / `systemctl` on Darwin | Copying the three cache paths into a second table |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./sshd-cli` | Ship unit | `util_cache_host_kind` prints `mac` |
| `sshd-cli about` | Cache lines | `/tmp/cache`, then `Library/Caches`, then `~/cache` |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Run on a Mac | Prefer `/tmp/cache`; do not use `/dev/shm/cache` | `sshd-cli about` |
| Check a file digest | `sha256sum`, else `shasum -a 256`, else `openssl dgst` | `util_sha256_file` |

---

## 2. Core Rules / Requirements (Mandatory)

1. **MUST** treat `uname -s` = `Darwin` as the macOS coding family. Cache kind **MUST** be `mac` (`util_cache_host_kind`). Test override `SSHD_CLI_CACHE_HOST=mac` **MUST** stay a test hook, not a second product detect.  
2. **MUST NOT** add `macos` or `darwin` to `sshd_fix_os_class`. On Darwin that helper stays `posix` unless Termux or Alpine wins. **MUST NOT** comment `GSSAPI*` or the Termux algorithm keywords because the host is a Mac.  
3. **MUST NOT** call `brew`, `port`, `launchctl`, or `systemctl` because the host is Darwin. `sshd_is_systemd_host` is false here (`/run/systemd/system` is absent). Start/stop/restart use the OpenSSH fallback in `requirement-domain-sshd`, not a launchd job.  
4. **MUST NOT** use `/dev/shm/cache` as the preferred cache on this family. The path table is `requirement-shell-cli-storage`: `/tmp/cache/cache-${APP_NAME}-${login}-$$`, then `${HOME}/Library/Caches/cache-${APP_NAME}-$$`, then `${HOME}/cache/cache-${APP_NAME}-$$`.  
5. Digest coding **MUST** stay inside `util_sha256_file`: `sha256sum`, then `shasum -a 256`, then `openssl dgst -sha256`. **MUST NOT** add a Darwin-only `shasum` call beside that helper.  
6. In-place `sed` **MUST** use `sed -i.bak` and then remove the `.bak`. BSD `sed` rejects bare `sed -i`. GNU `sed` accepts the suffix.  
7. Daemon rows **22–24** follow the POSIX rule: this family is not a command line for normal user only, so those rows show only for root. **MUST NOT** wrap `sudo` to unhide them.  
8. **MUST NOT** use GNU-only `grep -P` or bash arrays. The ship unit stays POSIX `/bin/sh`.  
9. **MUST** keep portable style on `requirement-shell-script-coding`.  
10. When sshd is missing and `uname -s` is `Darwin`, `sshd_openssh_server_hint` **MUST** say to install the OpenSSH server on this Mac. **MUST NOT** name `brew` or run it.  
11. `download` and `upload` **MUST** keep the streamed pipe. They **MUST NOT** use the MSYS2 finished-file transfer. That ban is `requirement-shell-windows-git-bash-cli-coding`.

### 2.1 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Detect | `uname -s` = `Darwin` → cache kind `mac` |
| OS class | `posix` via `sshd_fix_os_class` (no `macos` value) |
| Package tools | not wrapped (`brew` / `port`) |
| Service manager | not used (`launchctl` / `systemctl`) |
| Digest | `util_sha256_file` |
| In-place edit | `sed -i.bak` then `rm -f` the `.bak` |
| Cache | storage requirement; kind `mac` |
| In-tool sudo | none, except `util_sudo` for `backup-config` |

### 2.2 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): Darwin cache and digest tools are named. Homebrew is not.  
- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): `sed -i.bak` is the form both BSD and GNU accept.  
- **CIAO Principle 21 – Dual policies** (https://github.com/cloudgen/ciao): Storage owns the path table; this file owns the coding fence.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: Missing `sha256sum` is normal on macOS; the helper already falls through.  
- **Intentional**: Darwin changes cache kind, not the OpenSSH keyword class.  
- **Anti-fragile**: No launchd unit is required for the CLI to run.  
- **Over-protect**: Do not add `brew install openssh` as a companion.

## Under command line for normal user only

When the ship unit detects a **command line for normal user only** (Termux, Git Bash, Windows cmd, or the same class):

| MUST | MUST NOT |
|------|----------|
| Keep **normal user privilege** (Type 0) only | Implement or enable **admin privilege** (Type 1) or **dedicated system user privilege** (Type 2) |
| Document Type 1 **unused** and Type 2 **unused** | In-tool `sudo`; wrap `apt` / `dnf` / `yum`; create a dedicated system user |
| Termux: named `pkg` as this login remains Type 0 | Recommend `sudo curl \| sh` as the install path |
| Git Bash / Windows cmd: same privilege ceiling | Invoke Termux `pkg` because Git Bash or Windows cmd was detected |

Helpers (this product): `sshd_is_termux`, `sshd_is_git_bash`, `sshd_is_windows_cmd`, `sshd_is_normal_user_only_cli`. Dual mention: `requirement-shell-cli-interface` · `requirement-shell-termux-ish`.

**This requirement:** Darwin is **not** that class. Rows **22–24** stay hidden for a non-root Mac login. **MUST NOT** call `brew` or `launchctl` to unhide them.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Add `macos` / `darwin` to `sshd_fix_os_class`.  
2. Call `brew`, `port`, `launchctl`, or `systemctl` on Darwin.  
3. Prefer `/dev/shm/cache` on Darwin.  
4. Call `shasum` outside `util_sha256_file`.  
5. Use bare `sed -i`.  
6. Treat a Mac as Termux, Git Bash, or Windows cmd.

## 5. Definition of done

1. `util_cache_host_kind` still prints `mac` for Darwin.  
2. Cache tiers match the storage requirement (no second table here).  
3. `util_sha256_file` still tries `sha256sum`, then `shasum -a 256`, then `openssl`.  
4. In-place edits still use `sed -i.bak`.  
5. No `brew` or `launchctl` invocation in `./sshd-cli`.

## 6. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry |
| `docs/requirements/requirement-shell-script-coding.md` | Portable style; `sed -i.bak` |
| `docs/requirements/requirement-shell-cli-storage.md` | Mac cache path table |
| `docs/requirements/requirement-domain-sshd.md` | OpenSSH fallback when systemd is absent |
| `docs/requirements/requirement-shell-automatic-checksum.md` | Companion digest uses the same hash helper |
| `./sshd-cli` | `util_cache_host_kind`, `util_sha256_file` |

## 7. Design-time verification

| TP family / ID | What it shows | Status |
|----------------|---------------|--------|
| **TP-CLI-12** | Mac preferred `/tmp/cache`; 1st fallback `Library/Caches` | have |
| **TP-CLI-20** | Resolver names `Library/Caches` | have |
| **TP-SSHD-17** | Mac hint does not name `brew` | have |
| `brew` / `launchctl` | Not a verb | n/a (absent by design) |

This file adds no new test.

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

**Last Updated**: 2026-10-14 (1.0.1 streamed pipe stays. 1.0.0 family coding home)  
**Owner**: Cloudgen Wong  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
