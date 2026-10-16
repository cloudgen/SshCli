**file**: docs/requirements/requirement-shell-windows-cmd-cli-coding.md  
**Status**: Active (Version 1.0.1)  
**Area**: shell  
**Key**: `requirement-shell-windows-cmd-cli-coding`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This file owns Windows cmd CLI coding for sshd-cli: how this login is recognized after Git Bash, Cygwin, and WSL are excluded, and that a Win32 reader keeps the streamed `tar.gz` pipe.

### 1.1 Human-facing

**In one sentence:** On Windows cmd, folder upload and download keep the `tar.gz` pipe. `Windows_NT` alone is not a reason to switch to the Git Bash file transfer.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Someone in Windows cmd changing `./sshd-cli` | `OS=Windows_NT` and `ComSpec` names `cmd.exe` |
| The other role | Git Bash / MSYS2 | `requirement-shell-windows-git-bash-cli-coding` |
| Not this file | Termux `pkg`; the cache path table | `requirement-shell-termux-ish` · `requirement-shell-cli-storage` |

| Includes | Excludes |
|----------|----------|
| `sshd_is_windows_cmd` and the streamed pipe | The MSYS2 gzip-stdin ban |
| The missing-sshd sentence this shell already prints | Running `apt`, `dnf`, or `pkg` |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Upload from Windows cmd | Win32 `tar` may read the pipe | `sshd-cli upload phone ./box` |
| Start with no sshd | The next step says Windows cmd does not provide sshd | `sshd-cli start` |

---

## 2. Core Rules / Requirements (Mandatory)

1. **MUST** detect Windows cmd only after Git Bash, Cygwin (`uname -s` `CYGWIN*`), and WSL are excluded. The predicate is `OS=Windows_NT` or `ComSpec` naming `cmd.exe`. **MUST NOT** treat `Windows_NT` as the MSYS2 ban.  
2. `download` and `upload` **MUST** keep the streamed pipe. They **MUST NOT** use the MSYS2 finished-file transfer. That ban is `requirement-shell-windows-git-bash-cli-coding`.  
3. When sshd is missing, `sshd_openssh_server_hint` **MUST** say Windows cmd does not provide sshd and **MUST** tell the operator to install OpenSSH for Windows. **MUST NOT** name `apt` or `dnf`. **MUST NOT** run a package tool.  
4. This file **MUST NOT** call `sudo`, `apt`, `dnf`, `brew`, or Termux `pkg`.  
5. Hide sentences use the token `windows-cmd`. Menu numbers stay on `requirement-shell-cli-default-interaction`.

### 2.1 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Detect | `sshd_is_windows_cmd` |
| Transfer | streamed pipe. Ship unit already pipes |
| Missing sshd | `Windows cmd does not provide sshd. Install OpenSSH for Windows, then retry ${APP_NAME} start.` |
| Proof | **TP-OS-CMD-01** have. **TP-LC-19** and **TP-CFG-09** already cover hide and `pkg` |

### 2.2 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): Win32 `tar` is not MSYS `tar`. The pipe stays.  
- **CIAO Principle 5 – SSOT** (https://github.com/cloudgen/ciao): The MSYS ban has the Git Bash file. This file does not copy it.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: `Windows_NT` is not the Git Bash reader.  
- **Intentional**: The pipe is the transfer.  
- **Anti-fragile**: A missing sshd names this shell and does not run a package tool.  
- **Over-protect**: Do not apply the finished-file transfer here.

## 4. Protection Rules

**Future AI assistants or maintainers MUST NOT**:

1. Treat `Windows_NT` as the MSYS2 gzip-stdin ban.  
2. Switch this reader to the finished-file transfer.  
3. Tell Windows cmd to run `apt` or `dnf`.

## 5. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/requirement-shell-windows-git-bash-cli-coding.md` | MSYS2 stdin ban |
| `docs/requirements/requirement-domain-sshd.md` | Pipe contract |
| `docs/requirements/index.md` | Registry |

## 6. Design-time verification

| TP family / ID | What it shows | Status |
|----------------|---------------|--------|
| **TP-OS-CMD-01** | Windows cmd keeps the streamed pipe | have |
| **TP-CFG-09** | Hide token `windows-cmd` | have |
| **TP-LC-19** | `install` does not call `pkg` | have |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

**Last Updated**: 2026-10-16 (1.0.1 **TP-OS-CMD-01** have. 1.0.0 Windows cmd keeps the streamed pipe)  
**Owner**: sshd-cli project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
