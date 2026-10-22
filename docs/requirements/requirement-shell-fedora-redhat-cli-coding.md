**file**: docs/requirements/requirement-shell-fedora-redhat-cli-coding.md  
**Status**: Retired (Python generation 2.0.0. The live ship unit is the SshCli package. This file records the /bin/sh ship unit through 1.35.1. Where it disagrees with requirement-domain-sshd 1.28.0 or an Active requirement-python-*.md / requirement-runtime-prerequisites.md file, those win.) Was  (Version 1.0.1)  
**Area**: shell  
**Key**: `requirement-shell-fedora-redhat-cli-coding`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This is the **Fedora / Red Hat CLI coding** home for sshd-cli. It says how to write `./sshd-cli` when the host is Fedora, RHEL, CentOS Stream, Rocky, or Alma. Those names are **one family**. The ship unit does not detect them apart from other POSIX Linux.

Portable style (`set -u`, prefixes, do-not-capture-read) stays on `requirement-shell-script-coding`. OpenSSH start/stop, the systemd unit probe, and `fix-config` stay on `requirement-domain-sshd`. Cache paths stay on `requirement-shell-cli-storage`. This file owns the family fence so an agent does not add a Fedora package-manager branch.

### 1.1 Human-facing

**In one sentence:** On Fedora and Red Hat, the CLI stays POSIX `/bin/sh`, does not run `dnf` or `yum`, and uses the same systemd probe as other Linux.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Someone changing `./sshd-cli` for this family | Keep one `posix` path |
| The other role | `systemctl` on a root login when systemd is up | `sshd_is_systemd_host` |
| Not this file | Which sshd verbs exist; Termux `pkg` | `requirement-domain-sshd.md` · `requirement-shell-termux-ish.md` |

| Includes | Excludes |
|----------|----------|
| One coding family for Fedora, RHEL, CentOS Stream, Rocky, Alma | A helper `sshd_is_fedora` / `sshd_is_rhel` |
| No `dnf` / `yum` wrap; no hardcoded “Fedora” in the non-root sentence | Copying the systemd unit-probe table |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./sshd-cli` | Ship unit | `sshd_fix_os_class` returns `posix` here |
| `sshd-cli about` | JSON | `sshd_unit` is `ssh.service` or `sshd.service` |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Add a host check | Do not branch on `ID=fedora` or `ID_LIKE=rhel` | Keep `sshd_fix_os_class` |
| Start sshd on this family | Root login and a loaded unit; probe, do not hardcode one unit name | `sshd-cli start` |

---

## 2. Core Rules / Requirements (Mandatory)

1. **MUST** treat Fedora, RHEL, CentOS Stream, Rocky, and Alma as **one** coding family. **MUST NOT** add `sshd_is_fedora`, `sshd_is_rhel`, or a fourth `sshd_fix_os_class` value for them.  
2. On this family, `sshd_fix_os_class` **MUST** stay `posix` (unless the process is also Termux, or `/etc/os-release` `ID` / `ID_LIKE` contains `alpine`). Alpine keyword commenting stays on `requirement-domain-sshd`. **MUST NOT** comment `GSSAPI*` or `HostKeyAlgorithms` because the host is Fedora or RHEL.  
3. **MUST NOT** wrap `dnf`, `yum`, or `rpm` as an install companion. **MUST NOT** invoke them because Termux `pkg` exists on another host.  
4. **MUST NOT** hardcode the menu-hidden OS name as Fedora, Red Hat, or Ubuntu. Operator copy uses `sshd_os_name` (`/etc/os-release` `NAME=`, else `uname -s`, else `Linux`).  
5. When `sshd_is_systemd_host` is true, start/stop/restart coding **MUST** keep the domain probe: `ssh.service` then `sshd.service`; both exist → the active one, else `ssh.service`. The usual unit on this family is `sshd.service`. That usual name **MUST NOT** replace the probe. **MUST NOT** add a routed `systemctl` verb.  
6. Daemon rows **22–24** on this family follow POSIX Linux: print them only when this login is root. Non-root prints the menu-hidden sentence and does not dispatch those numbers. **MUST NOT** wrap `sudo` to unhide them. `util_sudo` stays the `backup-config` slice on `requirement-shell-sudoer`.  
7. Cache coding **MUST** use the Linux chain (`/dev/shm/cache` → `/tmp/cache` → `${HOME}/.cache`). The path table is `requirement-shell-cli-storage`.  
8. In-place `sed` **MUST** use `sed -i.bak` and then remove the `.bak`. Bare `sed -i` breaks the macOS coding home.  
9. **MUST NOT** add `setenforce`, `chcon`, `semanage`, or `firewall-cmd`. This product does not manage SELinux or firewalld.  
10. **MUST** keep portable style on `requirement-shell-script-coding` (`set -u`, prefixes, `out_*`, do-not-capture-read).  
11. When sshd is missing on POSIX Linux, `sshd_openssh_server_hint` **MUST** name `dnf` for Fedora and RHEL and `apt` for Debian and Ubuntu in **one** sentence, and **MUST** say `${APP_NAME}` does not run that command. **MUST NOT** branch on `ID=` or `ID_LIKE` to pick a single distro sentence. **MUST NOT** run `dnf`, `yum`, or `apt`. Termux keeps the `sshd-cli install` next step.  
12. `download` and `upload` **MUST** keep the streamed pipe. They **MUST NOT** use the MSYS2 finished-file transfer. That ban is `requirement-shell-windows-git-bash-cli-coding`.

### 2.1 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Family | Fedora, RHEL, CentOS Stream, Rocky, Alma |
| OS class | `posix` via `sshd_fix_os_class` |
| Distro helper | none (do not add one) |
| Package tools | not wrapped (`dnf` / `yum` / `rpm`) |
| Service | `sshd_is_systemd_host`; unit probe in `requirement-domain-sshd` |
| Usual unit | `sshd.service` (probe still wins) |
| Display name | `sshd_os_name` |
| Cache kind | `linux` (`util_cache_host_kind`) |
| In-tool sudo | none, except `util_sudo` for `backup-config` |

### 2.2 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): Fedora and RHEL are named as one family, not as a new OS class.  
- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): No `dnf` wrap and no hardcoded unit name.  
- **CIAO Principle 21 – Dual policies** (https://github.com/cloudgen/ciao): Portable script-coding; this file is the filled family fence.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: A `NAME=Fedora` string is display text, not a code branch.  
- **Intentional**: One probe serves Debian’s `ssh.service` and this family’s `sshd.service`.  
- **Anti-fragile**: The CLI still runs when `dnf` is absent.  
- **Over-protect**: Do not add SELinux or firewalld helpers “because this is RHEL”.

## Under command line for normal user only

When the ship unit detects a **command line for normal user only** (Termux, Git Bash, Windows cmd, or the same class):

| MUST | MUST NOT |
|------|----------|
| Keep **normal user privilege** (Type 0) only | Implement or enable **admin privilege** (Type 1) or **dedicated system user privilege** (Type 2) |
| Document Type 1 **unused** and Type 2 **unused** | In-tool `sudo`; wrap `apt` / `dnf` / `yum`; create a dedicated system user |
| Termux: named `pkg` as this login remains Type 0 | Recommend `sudo curl \| sh` as the install path |
| Git Bash / Windows cmd: same privilege ceiling | Invoke Termux `pkg` because Git Bash or Windows cmd was detected |

Helpers (this product): `sshd_is_termux`, `sshd_is_git_bash`, `sshd_is_windows_cmd`, `sshd_is_normal_user_only_cli`. Dual mention: `requirement-shell-cli-interface` · `requirement-shell-termux-ish`.

**This requirement:** Fedora / Red Hat is **not** that class. `sshd_is_normal_user_only_cli` is false here, so root may see rows **22–24** and `systemctl` may run. That is still not Type 1 inside the tool: no in-tool `sudo` to become root, and no `dnf` / `yum` wrap.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Add `sshd_is_fedora` or branch on `ID=fedora` / `ID_LIKE=rhel`.  
2. Wrap `dnf`, `yum`, or `rpm`.  
3. Hardcode `sshd.service` and skip the probe.  
4. Hardcode “Fedora”, “Red Hat”, or “Ubuntu” in the non-root menu-hidden sentence.  
5. Comment Alpine `GSSAPI*` lines or Termux algorithm lines because the host is this family.  
6. Add SELinux or firewalld commands.  
7. Treat this family as Termux, Git Bash, or Windows cmd.

## 5. Definition of done

1. No new distro helper, and `sshd_fix_os_class` still returns `posix` on this family.  
2. No `dnf` / `yum` / `rpm` invocation in `./sshd-cli`.  
3. Unit choice remains the domain probe (`ssh.service` or `sshd.service`).  
4. Non-root menu-hidden sentence still uses `sshd_os_name`.  
5. The missing-sshd next step names `dnf` and `apt` together and does not run either.

## 6. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry |
| `docs/requirements/requirement-shell-script-coding.md` | Portable style |
| `docs/requirements/requirement-shell-debian-cli-coding.md` | Sibling family; same `posix` path |
| `docs/requirements/requirement-domain-sshd.md` | systemd probe; `fix-config` |
| `docs/requirements/requirement-shell-cli-storage.md` | Linux cache chain |
| `docs/requirements/requirement-shell-sudoer.md` | `util_sudo` for `backup-config` only |
| `./sshd-cli` | Implementation |

## 7. Design-time verification

| TP family / ID | What it shows | Status |
|----------------|---------------|--------|
| **TP-SSHD-03** | Non-root menu-hidden sentence | have |
| **TP-SSHD-10** | About names `ssh.service` or `sshd.service` | have |
| **TP-SSHD-09..14** | systemd unit path | have |
| **TP-SSHD-17** | Missing-sshd hint names `dnf` and `apt` and does not run them | have |
| `dnf` / `yum` wrap | Not a verb | n/a (absent by design) |

This file adds no new test. There is no Fedora-only suite host.

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

**Last Updated**: 2026-10-14 (1.0.1 streamed pipe stays. 1.0.0 family coding home)  
**Owner**: Cloudgen Wong  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
