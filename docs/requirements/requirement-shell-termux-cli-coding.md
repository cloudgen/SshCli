**file**: docs/requirements/requirement-shell-termux-cli-coding.md  
**Status**: Active (Version 1.0.1)  
**Area**: shell  
**Key**: `requirement-shell-termux-cli-coding`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This is the **Termux CLI coding** home for sshd-cli. It says how to write `./sshd-cli` when the host is Termux. Detect stays `sshd_is_termux`. Package ensure and the Android wake lock stay on `requirement-shell-termux-ish`. This file owns the coding fence: one detect, POSIX `/bin/sh`, no second Termux test, no `systemctl`, no `apt` / `dnf`, and no Linux `/usr` assumption for Termux binaries.

### 1.1 Human-facing

**In one sentence:** Termux code uses `sshd_is_termux` once, runs as you, and does not grow a second Termux check or a Linux package command.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | The Termux login editing or running the CLI | `sshd-cli install` |
| The other role | `pkg` and `termux-wake-lock` | `requirement-shell-termux-ish.md` |
| Not this file | Named package list; which sshd verbs exist | `requirement-domain-sshd.md` |

| Includes | Excludes |
|----------|----------|
| Detect rule; coding fences; menu class pointers | A second copy of `pkg install -y openssh termux-auth` |
| No `systemctl` / `sudo` / `apt` on this detect | Git Bash and Windows cmd coding |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./sshd-cli` | Ship unit | `sshd_is_termux` |
| Front menu | Hide cause | `sudoers not available for termux` |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Add a Termux branch | Call `sshd_is_termux`; do not re-test `PREFIX` inline | Edit `./sshd-cli` |
| Install OpenSSH | Named `pkg` stays on the Termux-ish requirement | `sshd-cli install` |

---

## 2. Core Rules / Requirements (Mandatory)

1. **MUST** detect Termux only with `sshd_is_termux`: `PREFIX` contains `com.termux` and `${PREFIX}/bin` is a directory, or `TERMUX_VERSION` is set, or `/data/data/com.termux/files/usr` exists. **MUST NOT** add a second detect with a different predicate.  
2. `sshd_fix_os_class` **MUST** return `termux` on that detect (unless `SSHD_CLI_OS` is the allowed override `alpine`, `termux`, or `posix`). Keyword commenting for that class stays on `requirement-domain-sshd`.  
3. This host **MUST** stay a command line for normal user only. Type 1 and Type 2 **MUST** stay unused. **MUST NOT** call `sudo`, `systemctl`, `apt`, `apt-get`, `dnf`, or `yum` because Termux was detected.  
4. Named `pkg` and `termux-wake-lock` / `termux-wake-unlock` **MUST** stay on `requirement-shell-termux-ish`. This file **MUST NOT** copy the package table or the wake-lock return codes.  
5. **MUST NOT** invoke `pkg` or `termux-wake-lock` from a Git Bash or Windows cmd branch. Those detects are `sshd_is_git_bash` and `sshd_is_windows_cmd`.  
6. Cache kind on Termux is `linux` (`util_cache_host_kind`), including `/dev/shm/cache` when that directory works. The folder is scratch and may be `noexec`. The path table is `requirement-shell-cli-storage`. **MUST NOT** switch Termux to the Mac or Git Bash cache chain.  
7. Binaries this login installs live under `$PREFIX` (typical `PREFIX/bin`, `PREFIX/etc`). **MUST NOT** assume `/usr/sbin/sshd` or `/lib/systemd` on this detect.  
8. Menu coding **MUST** follow the live boards: front **5** sudoers hidden with `[INFO] sudoers not available for termux` before the numbers; client **18** `sync-from-remote` instead of **15** / **16**; server **22–24** shown for this login. Numbers and sentences stay owned by `requirement-shell-cli-default-interaction` and `requirement-domain-sshd`.  
9. The script **MUST** stay POSIX `/bin/sh`. **MUST NOT** require bash arrays or GNU `grep -P`. In-place `sed` **MUST** use `sed -i.bak`.  
10. Portable style stays on `requirement-shell-script-coding`.  
11. `download` and `upload` **MUST** keep the streamed pipe. They **MUST NOT** use the MSYS2 finished-file transfer. That ban is `requirement-shell-windows-git-bash-cli-coding`.

### 2.1 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Detect | `sshd_is_termux` |
| OS class | `termux` via `sshd_fix_os_class` |
| Privilege | Type 0 only (`sshd_is_normal_user_only_cli`) |
| Packages / wake lock | `requirement-shell-termux-ish` |
| Service manager | not used (`systemctl` is not called) |
| Cache kind | `linux` |
| Menu token | `termux` in the sudoers and backup hide sentences |
| In-tool sudo | none |

### 2.2 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): Termux coding is a named home, separate from the `pkg` companion.  
- **CIAO Principle 9 – Type 0/1/2** (https://github.com/cloudgen/ciao): This login stays Type 0.  
- **CIAO Principle 10 – Least privilege** (https://github.com/cloudgen/ciao): No sudo and no `systemctl`.  
- **CIAO Principle 21 – Dual policies** (https://github.com/cloudgen/ciao): Termux-ish owns `pkg`; this file owns how the CLI is written.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: One detect. A second `PREFIX` test will drift.  
- **Intentional**: `pkg` stays in the Termux-ish requirement.  
- **Anti-fragile**: The CLI runs without systemd and without root.  
- **Over-protect**: Do not “help” Termux by calling `apt`.

## Under command line for normal user only

When the ship unit detects a **command line for normal user only** (Termux, Git Bash, Windows cmd, or the same class):

| MUST | MUST NOT |
|------|----------|
| Keep **normal user privilege** (Type 0) only | Implement or enable **admin privilege** (Type 1) or **dedicated system user privilege** (Type 2) |
| Document Type 1 **unused** and Type 2 **unused** | In-tool `sudo`; wrap `apt` / `dnf` / `yum`; create a dedicated system user |
| Termux: named `pkg` as this login remains Type 0 | Recommend `sudo curl \| sh` as the install path |
| Git Bash / Windows cmd: same privilege ceiling | Invoke Termux `pkg` because Git Bash or Windows cmd was detected |

Helpers (this product): `sshd_is_termux`, `sshd_is_git_bash`, `sshd_is_windows_cmd`, `sshd_is_normal_user_only_cli`. Dual mention: `requirement-shell-cli-interface` · `requirement-shell-termux-ish`.

**This requirement:** Termux **is** this class. Coding branches for Termux **MUST** use `sshd_is_termux`. `pkg` and the wake lock run only on that detect.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Add a second Termux detect that disagrees with `sshd_is_termux`.  
2. Copy the `pkg` package table or wake-lock return codes into this file.  
3. Call `sudo`, `systemctl`, `apt`, `dnf`, or `yum` on Termux.  
4. Call `pkg` or `termux-wake-lock` on Git Bash or Windows cmd.  
5. Point Termux cache at `Library/Caches` or AppData.  
6. Assume `/usr/sbin/sshd` or `/lib/systemd` on this detect.  
7. Strip the **Under command line for normal user only** section.

## 5. Definition of done

1. Termux branches call `sshd_is_termux`.  
2. `sshd_fix_os_class` returns `termux` on that detect.  
3. `pkg` and wake-lock law remain only in `requirement-shell-termux-ish`.  
4. Termux start does not invoke `systemctl`.  
5. The front board omits sudoers and prints `sudoers not available for termux`.  
6. Missing sshd on Termux still says to run `${APP_NAME} install`. It does not use the POSIX Linux `dnf` / `apt` sentence.

## 6. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry |
| `docs/requirements/requirement-shell-termux-ish.md` | `pkg` and Android wake lock |
| `docs/requirements/requirement-shell-script-coding.md` | Portable style |
| `docs/requirements/requirement-domain-sshd.md` | Keyword class `termux`; daemon rows; `$PREFIX` sshd |
| `docs/requirements/requirement-shell-cli-default-interaction.md` | Front **5** hide sentence |
| `docs/requirements/requirement-shell-cli-storage.md` | Linux cache chain; Termux scratch may be `noexec` |
| `docs/requirements/requirement-shell-windows-git-bash-cli-coding.md` | Other normal-user-only detect; not Termux |
| `./sshd-cli` | `sshd_is_termux` |

## 7. Design-time verification

| TP family / ID | What it shows | Status |
|----------------|---------------|--------|
| **TP-SSHD-04** | Termux menu prints the sudoers hide sentence, omits `5. `, still shows language | have |
| **TP-SSHD-13** | Termux start does not invoke `systemctl` | have |
| **TP-CFG-04** | Front sudoers INFO for `termux` | have |
| **TP-LC-15..19** · **TP-TX-08..16** | `pkg` and wake lock | have on `requirement-shell-termux-ish` |

This file adds no new test.

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

**Last Updated**: 2026-10-14 (1.0.1 streamed pipe stays. 1.0.0 family coding home)  
**Owner**: Cloudgen Wong  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
