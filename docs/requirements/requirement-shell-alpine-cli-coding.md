**file**: docs/requirements/requirement-shell-alpine-cli-coding.md  
**Status**: Active (Version 1.0.0)  
**Area**: shell  
**Key**: `requirement-shell-alpine-cli-coding`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This file owns Alpine CLI coding for the operating-system set: `sshd_fix_os_class` returns `alpine`, folder transfer keeps the streamed pipe, and the GSSAPI comment stays on `requirement-domain-sshd`.

### 1.1 Human-facing

**In one sentence:** On Alpine, folder upload keeps the `tar.gz` pipe, and an active GSSAPI line is commented by the existing fix-config pass.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Someone on Alpine changing `./sshd-cli` | `/etc/os-release` `ID=alpine` |
| The other role | OpenSSH client config | `fix-config` comments `GSSAPI*` |
| Not this file | The MSYS2 file transfer; an `apk` wrap | Git Bash coding home |

| Includes | Excludes |
|----------|----------|
| Alpine class and the streamed pipe | Running `apk` |
| A pointer at the GSSAPI comment | A second comment procedure |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Upload a folder | The pipe stays | `sshd-cli upload phone ./box` |
| Start with no sshd | The POSIX sentence names `dnf` and `apt` and does not run them | `sshd-cli start` |

---

## 2. Core Rules / Requirements (Mandatory)

1. **MUST** treat Alpine as `sshd_fix_os_class` value `alpine` when `ID` or `ID_LIKE` contains `alpine`. **MUST NOT** add a second Alpine detect.  
2. `download` and `upload` **MUST** keep the streamed pipe. They **MUST NOT** use the MSYS2 finished-file transfer. If `tar` is BusyBox, `requirement-shell-busybox-cli-coding` also applies.  
3. Commenting an active `GSSAPI*` keyword stays on `requirement-domain-sshd`. This file **MUST NOT** restate that procedure.  
4. The missing-sshd sentence on Alpine is the POSIX Linux sentence owned with the Debian and Fedora files: it names `dnf` and `apt` in one sentence and says this program does not run that command. This file **MUST NOT** add an `apk` wrap. **MUST NOT** run `apk`.  
5. This file **MUST NOT** call `sudo`, `apt`, `dnf`, or Termux `pkg`.

### 2.1 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Class | `sshd_fix_os_class` → `alpine` |
| Transfer | streamed pipe. Ship unit already pipes |
| Missing sshd | the POSIX `dnf` and `apt` sentence. No `apk` run |
| Proof | **TP-OS-ALP-01** todo. GSSAPI proof stays **TP-FIX-*** |

### 2.2 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 5 – SSOT** (https://github.com/cloudgen/ciao): The pipe choice is here. The keyword comment stays on the domain requirement.  
- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): Alpine is not the MSYS reader.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: Do not copy the Git Bash file transfer onto Alpine.  
- **Intentional**: `apk` is not invoked.  
- **Anti-fragile**: BusyBox `tar` still uses the pipe, or fails closed under the BusyBox file.  
- **Over-protect**: Do not invent a second GSSAPI procedure.

## 4. Protection Rules

**Future AI assistants or maintainers MUST NOT**:

1. Use the MSYS2 finished-file transfer on Alpine.  
2. Run `apk`.  
3. Move the GSSAPI comment procedure into this file.

## 5. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/requirement-domain-sshd.md` | GSSAPI comment and the pipe |
| `docs/requirements/requirement-shell-busybox-cli-coding.md` | Applet call when `tar` is BusyBox |
| `docs/requirements/requirement-shell-windows-git-bash-cli-coding.md` | MSYS2 exception |
| `docs/requirements/index.md` | Registry |

## 6. Design-time verification

| TP family / ID | What it shows | Status |
|----------------|---------------|--------|
| **TP-OS-ALP-01** | Alpine keeps the streamed pipe | todo |
| **TP-FIX-*** | Alpine comments an active `GSSAPI*` line | have on the domain file |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

**Last Updated**: 2026-10-14 (1.0.0 Alpine keeps the streamed pipe)  
**Owner**: sshd-cli project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
