**file**: docs/requirements/requirement-shell-other-linux-cli-coding.md  
**Status**: Retired (Python generation 2.0.0. The live ship unit is the SshCli package. This file records the /bin/sh ship unit through 1.35.1. Where it disagrees with requirement-domain-sshd 1.28.0 or an Active requirement-python-*.md / requirement-runtime-prerequisites.md file, those win.) Was  (Version 1.0.0)  
**Area**: shell  
**Key**: `requirement-shell-other-linux-cli-coding`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This file owns POSIX Linux CLI coding that is not Debian family, not Fedora or Red Hat family, not Alpine, and not Termux. Those logins keep the streamed `tar.gz` pipe. This file does not invent a package manager for them.

### 1.1 Human-facing

**In one sentence:** On a Linux that is not Debian, Fedora, Alpine, or Termux, folder upload keeps the `tar.gz` pipe, and the program does not guess a new package tool.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Someone on another Linux changing `./sshd-cli` | `sshd_fix_os_class` is `posix` and the named families do not match |
| The other role | The named families | Debian, Fedora, Alpine, Termux files |
| Not this file | The MSYS2 file transfer | Git Bash coding home |

| Includes | Excludes |
|----------|----------|
| The leftover Linux class and the streamed pipe | A made-up package name |
| The shipped POSIX missing-sshd sentence | An `apt` / `dnf` / `apk` wrap |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Upload a folder | The pipe stays | `sshd-cli upload phone ./box` |

---

## 2. Core Rules / Requirements (Mandatory)

1. This class is POSIX Linux that is not Debian family, not Fedora or Red Hat family, not Alpine, and not Termux. **MUST NOT** add a new `sshd_fix_os_class` value for it.  
2. `download` and `upload` **MUST** keep the streamed pipe. They **MUST NOT** use the MSYS2 finished-file transfer. That ban is `requirement-shell-windows-git-bash-cli-coding`.  
3. The missing-sshd sentence stays the POSIX sentence owned with the Debian and Fedora files: it names `dnf` and `apt` in one sentence and says this program does not run that command. This file **MUST NOT** invent a third package tool. **MUST NOT** run `apt`, `dnf`, or `apk`.  
4. The systemd unit probe stays on `requirement-domain-sshd`. This file **MUST NOT** add a second probe.  
5. This file **MUST NOT** call `sudo`, `brew`, or Termux `pkg`.

### 2.1 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Class | `posix` when the named families do not match |
| Transfer | streamed pipe. Ship unit already pipes |
| Missing sshd | the POSIX `dnf` and `apt` sentence |
| Proof | **TP-OS-OTH-01** todo |

### 2.2 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 4 – Over-protect** (https://github.com/cloudgen/ciao): A Linux that was not named still keeps the pipe, and it does not inherit the MSYS2 file transfer.  
- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): Do not invent a package tool for an unnamed distro.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: The leftover class is not a new OS class value.  
- **Intentional**: The pipe is the transfer.  
- **Anti-fragile**: The missing-sshd sentence stays the one POSIX sentence.  
- **Over-protect**: Do not copy the MSYS file transfer here.

## 4. Protection Rules

**Future AI assistants or maintainers MUST NOT**:

1. Use the MSYS2 finished-file transfer on this class.  
2. Invent a package tool name that the ship unit does not already print.  
3. Add a `sshd_fix_os_class` value for this leftover class.

## 5. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/requirement-shell-debian-cli-coding.md` | Debian family |
| `docs/requirements/requirement-shell-fedora-redhat-cli-coding.md` | Fedora and Red Hat |
| `docs/requirements/requirement-shell-alpine-cli-coding.md` | Alpine |
| `docs/requirements/requirement-shell-termux-cli-coding.md` | Termux |
| `docs/requirements/requirement-domain-sshd.md` | Pipe and systemd probe |
| `docs/requirements/requirement-shell-windows-git-bash-cli-coding.md` | MSYS2 exception |
| `docs/requirements/index.md` | Registry |

## 6. Design-time verification

| TP family / ID | What it shows | Status |
|----------------|---------------|--------|
| **TP-OS-OTH-01** | Other Linux keeps the streamed pipe | todo |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

**Last Updated**: 2026-10-14 (1.0.0 other Linux keeps the streamed pipe)  
**Owner**: sshd-cli project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
