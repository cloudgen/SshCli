**file**: docs/requirements/requirement-shell-debian-cli-coding.md  
**Status**: Retired (Python generation 2.0.0. The live ship unit is the SshCli package. This file records the /bin/sh ship unit through 1.35.1. Where it disagrees with requirement-domain-sshd 1.28.0 or an Active requirement-python-*.md / requirement-runtime-prerequisites.md file, those win.) Was  (Version 1.0.1)  
**Area**: shell  
**Key**: `requirement-shell-debian-cli-coding`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This is the **Debian CLI coding** home for sshd-cli. It says how to write `./sshd-cli` when the host is Debian, Ubuntu, or another Debian-family Linux that is not Alpine. Those names are **one family**. The ship unit does not detect them apart from other POSIX Linux.

Portable style stays on `requirement-shell-script-coding`. OpenSSH start/stop, the systemd unit probe, and `fix-config` stay on `requirement-domain-sshd`. Cache paths stay on `requirement-shell-cli-storage`. This file owns the family fence so an agent does not add an `apt` branch or hardcode Ubuntu.

### 1.1 Human-facing

**In one sentence:** On Debian and Ubuntu, the CLI stays POSIX `/bin/sh`, does not run `apt`, and the non-root menu sentence does not hardcode “Ubuntu”.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Someone changing `./sshd-cli` for this family | Keep one `posix` path |
| The other role | `systemctl` on a root login when systemd is up | `sshd_is_systemd_host` |
| Not this file | Which sshd verbs exist; Termux `pkg` | `requirement-domain-sshd.md` · `requirement-shell-termux-ish.md` |

| Includes | Excludes |
|----------|----------|
| One coding family for Debian and Ubuntu | A helper `sshd_is_debian` / `sshd_is_ubuntu` |
| No `apt` / `apt-get` wrap; OS name from `sshd_os_name` | Copying the systemd unit-probe table |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./sshd-cli` | Ship unit | `sshd_fix_os_class` returns `posix` here |
| Server menu, non-root | Menu-hidden sentence | OS name is the live `NAME=`, not Ubuntu |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Add a host check | Do not branch on `ID=debian` or `ID=ubuntu` | Keep `sshd_fix_os_class` |
| Start sshd on this family | Root login and a loaded unit; probe, do not hardcode `ssh.service` only | `sshd-cli start` |

---

## 2. Core Rules / Requirements (Mandatory)

1. **MUST** treat Debian, Ubuntu, and other Debian-family Linux that is not Alpine as **one** coding family. **MUST NOT** add `sshd_is_debian` or `sshd_is_ubuntu`.  
2. On this family, `sshd_fix_os_class` **MUST** stay `posix` (unless the process is also Termux, or `/etc/os-release` `ID` / `ID_LIKE` contains `alpine`). **MUST NOT** comment `GSSAPI*` because the host is Debian or Ubuntu. Alpine owns that comment. **MUST NOT** comment `HostKeyAlgorithms` / `PubkeyAcceptedAlgorithms` / `PubkeyAcceptedKeyTypes` because the host is this family. Termux owns that comment.  
3. **MUST NOT** wrap `apt`, `apt-get`, or `dpkg`. **MUST NOT** invoke them because Termux `pkg` exists on another host.  
4. **MUST NOT** hardcode the menu-hidden OS name as Ubuntu, Debian, or Fedora. Operator copy uses `sshd_os_name`.  
5. When `sshd_is_systemd_host` is true, start/stop/restart coding **MUST** keep the domain probe: `ssh.service` then `sshd.service`; both exist → the active one, else `ssh.service`. The usual unit on Debian and Ubuntu is `ssh.service`. That usual name **MUST NOT** replace the probe. **MUST NOT** add a routed `systemctl` verb.  
6. Daemon rows **22–24** on this family follow POSIX Linux: print them only when this login is root. **MUST NOT** wrap `sudo` to unhide them. `util_sudo` stays the `backup-config` slice on `requirement-shell-sudoer`.  
7. Cache coding **MUST** use the Linux chain (`/dev/shm/cache` → `/tmp/cache` → `${HOME}/.cache`). The path table is `requirement-shell-cli-storage`.  
8. In-place `sed` **MUST** use `sed -i.bak` and then remove the `.bak`.  
9. **MUST** keep portable style on `requirement-shell-script-coding`.  
10. When sshd is missing on POSIX Linux, the next step **MUST** name `apt` for Debian and Ubuntu in the same sentence as `dnf` for Fedora and RHEL, and **MUST** say this program does not run that command. **MUST NOT** print only “On Debian/Ubuntu: apt install openssh-server”. **MUST NOT** run `apt`.  
11. `download` and `upload` **MUST** keep the streamed pipe. They **MUST NOT** use the MSYS2 finished-file transfer. That ban is `requirement-shell-windows-git-bash-cli-coding`.

### 2.1 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Family | Debian, Ubuntu, and Debian-family Linux that is not Alpine |
| OS class | `posix` via `sshd_fix_os_class` |
| Distro helper | none (do not add one) |
| Package tools | not wrapped (`apt` / `apt-get` / `dpkg`) |
| Service | `sshd_is_systemd_host`; unit probe in `requirement-domain-sshd` |
| Usual unit | `ssh.service` (probe still wins) |
| Display name | `sshd_os_name` |
| Cache kind | `linux` (`util_cache_host_kind`) |
| In-tool sudo | none, except `util_sudo` for `backup-config` |

### 2.2 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): Debian and Ubuntu are named, and Ubuntu is not a hardcoded string.  
- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): No `apt` wrap and no single hardcoded unit.  
- **CIAO Principle 21 – Dual policies** (https://github.com/cloudgen/ciao): Portable script-coding; this file is the filled family fence.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: `NAME=Ubuntu` is display text, not a code branch.  
- **Intentional**: The same probe covers `ssh.service` and `sshd.service`.  
- **Anti-fragile**: The CLI still runs when `apt` is absent.  
- **Over-protect**: Do not “fix” Debian by commenting Alpine GSSAPI lines.

## Under command line for normal user only

When the ship unit detects a **command line for normal user only** (Termux, Git Bash, Windows cmd, or the same class):

| MUST | MUST NOT |
|------|----------|
| Keep **normal user privilege** (Type 0) only | Implement or enable **admin privilege** (Type 1) or **dedicated system user privilege** (Type 2) |
| Document Type 1 **unused** and Type 2 **unused** | In-tool `sudo`; wrap `apt` / `dnf` / `yum`; create a dedicated system user |
| Termux: named `pkg` as this login remains Type 0 | Recommend `sudo curl \| sh` as the install path |
| Git Bash / Windows cmd: same privilege ceiling | Invoke Termux `pkg` because Git Bash or Windows cmd was detected |

Helpers (this product): `sshd_is_termux`, `sshd_is_git_bash`, `sshd_is_windows_cmd`, `sshd_is_normal_user_only_cli`. Dual mention: `requirement-shell-cli-interface` · `requirement-shell-termux-ish`.

**This requirement:** Debian / Ubuntu is **not** that class. `sshd_is_normal_user_only_cli` is false here, so root may see rows **22–24** and `systemctl` may run. That is still not Type 1 inside the tool: no in-tool `sudo` to become root, and no `apt` wrap.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Add `sshd_is_debian` or `sshd_is_ubuntu`.  
2. Wrap `apt`, `apt-get`, or `dpkg`.  
3. Hardcode `ssh.service` and skip the probe.  
4. Hardcode “Ubuntu” or “Debian” in the non-root menu-hidden sentence.  
5. Comment Alpine `GSSAPI*` lines or Termux algorithm lines because the host is this family.  
6. Treat this family as Termux, Git Bash, or Windows cmd.

## 5. Definition of done

1. No new distro helper, and `sshd_fix_os_class` still returns `posix` on this family.  
2. No `apt` / `apt-get` / `dpkg` invocation in `./sshd-cli`.  
3. Unit choice remains the domain probe.  
4. Non-root menu-hidden sentence still uses `sshd_os_name`.  
5. The missing-sshd next step is not a Debian-only `apt install` line.

## 6. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry |
| `docs/requirements/requirement-shell-script-coding.md` | Portable style |
| `docs/requirements/requirement-shell-fedora-redhat-cli-coding.md` | Sibling family; same `posix` path |
| `docs/requirements/requirement-domain-sshd.md` | systemd probe; `fix-config`; no hardcoded Ubuntu |
| `docs/requirements/requirement-shell-cli-storage.md` | Linux cache chain |
| `docs/requirements/requirement-shell-sudoer.md` | `util_sudo` for `backup-config` only |
| `./sshd-cli` | Implementation |

## 7. Design-time verification

| TP family / ID | What it shows | Status |
|----------------|---------------|--------|
| **TP-SSHD-03** | Non-root menu-hidden sentence | have |
| **TP-SSHD-10** | About names `ssh.service` or `sshd.service` | have |
| **TP-SSHD-09..14** | systemd unit path | have |
| **TP-SSHD-17** | Missing-sshd hint is not “On Debian/Ubuntu: apt install openssh-server” | have |
| `apt` wrap | Not a verb | n/a (absent by design) |

This file adds no new test. There is no Debian-only suite host.

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

**Last Updated**: 2026-10-14 (1.0.1 streamed pipe stays. 1.0.0 family coding home)  
**Owner**: Cloudgen Wong  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
