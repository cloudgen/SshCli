# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| **1.35.1** (current) | Yes — report security issues against this release |
| **1.35.0** | Yes — report security issues against this release |
| 1.34.0 | Superseded — prefer current when reporting |
| 1.33.0 | Superseded — prefer current when reporting |
| 1.32.0 | Superseded — prefer current when reporting |
| 1.31.0 | Superseded — prefer current when reporting |
| 1.30.0 | Superseded — prefer current when reporting |
| 1.29.0 | Superseded — prefer current when reporting |
| 1.28.0 | Superseded — prefer current when reporting |
| 1.27.0 | Superseded — prefer current when reporting |
| 1.20.0 | Superseded — prefer current when reporting |
| 1.19.1 | Superseded — prefer current when reporting |
| 1.19.0 | Superseded — prefer current when reporting |
| 1.18.0 | Superseded — prefer current when reporting |
| 1.17.0 | Superseded — prefer current when reporting |
| 1.16.0 | Superseded — prefer current when reporting |
| 1.15.0 | Superseded — prefer current when reporting |
| 1.13.2 | Superseded — prefer current when reporting |
| 1.13.0 | Superseded — prefer current when reporting |
| 1.11.0 | Superseded — prefer current when reporting |
| 1.10.0 | Superseded — prefer current when reporting |
| 1.9.1 | Superseded — prefer current when reporting |
| 1.9.0 | Superseded — prefer current when reporting |
| 1.8.0 | Superseded — prefer current when reporting |
| 1.7.0 | Superseded — prefer current when reporting |
| 1.6.0 | Superseded — prefer current when reporting |
| 1.5.1 | Superseded — prefer current when reporting |
| 1.5.0 | Superseded — prefer current when reporting |
| 1.4.2 | Superseded — prefer current when reporting |
| 1.4.1 | Superseded — prefer current when reporting |
| 1.4.0 | Superseded — prefer current when reporting |
| 1.3.1 | Superseded — prefer current when reporting |
| 1.3.0 | Superseded — prefer current when reporting |
| 1.2.0 | Superseded — prefer current when reporting |
| 1.1.0 | Superseded — prefer current when reporting |
| 1.0.0 | Superseded — prefer current when reporting |
| Older / unreleased | No public support matrix — prefer current when reporting |

## Reporting a Vulnerability

Please **do not** open a public issue for security-sensitive reports when a private channel is available.

**Maintainer contact (email):** `cloudgen.wong@gmail.com`

- Source of contact: product **author-email** SSOT in [`LICENSE.md`](./LICENSE.md) (Copyright line).  
- Prefer email for vulnerability details, reproduction steps, and impact.  
- You should receive an acknowledgment when the report is received and actionable.  
- Do not include exploit weaponization guides in public channels.

For non-sensitive questions, product usage, or general bugs that are not security-sensitive, use normal project channels (for example public issues on the project repository when available).

## Security Design Principles (CIAO)

This project follows **[CIAO](https://github.com/cloudgen/ciao)** / **CIAO-Lite** defensive design. Security-relevant intent:

| Letter | Principle | Security application |
|--------|-----------|----------------------|
| **C** | **Caution** | Assume hostile input and misconfiguration. Validate install paths, checksums, sshd config test (`sshd -t`), and privilege boundaries. |
| **I** | **Intentional** | Type 0 self-management vs sshd domain verbs are separate. Channel URL (`SCRIPT_URL`) and checksum modes are documented. No in-tool `sudo`. |
| **A** | **Anti-fragile** | Survive Termux (no systemd) and non-interactive `curl \| sh`. Start is OpenSSH daemonize, not a service manager. Automatic SHA-256 sidecar when available. |
| **O** | **Over-protect** | Integrity verify before install/update; never overwrite existing host private keys; fail closed when Linux system paths are not writable. |

Full principles: [CIAO Defensive Programming](https://github.com/cloudgen/ciao) · agent contract: [CIAO-Lite](https://github.com/cloudgen/ciao-lite).

This section describes **design posture**. It is **not** a claim of third-party certification.

## Install integrity and trust

This product implements **automatic companion-checksum** on online install and self-update. Operator steps live in [`README.md`](./README.md). Trust posture:

| Fact | Honest statement |
|------|------------------|
| **Default path** | Automatic companion `${SCRIPT_URL}.sha256` when `CHECKSUM` is unset — no env pin required for normal install. |
| **Algorithm** | SHA-256 via `sha256sum`. |
| **Transparency** | Human mode shows companion **link**, expected **value**, and verification **result** (match / mismatch / missing). |
| **Mismatch** | Abort — do not install mismatched bytes. |
| **Missing sidecar** | Warning, then continue (not “always verified”). |
| **Optional pin** | Process-env `CHECKSUM` is **secondary** (CI / out-of-band freeze). Same-origin pin is **not** stronger than automatic mode. Not listed in `help` / `about`. |
| **Trust bound** | Same-channel SHA-256 proves **byte consistency**. It is not independent authenticity (signing) by itself. |
| **Forbidden** | Embedding the digest of `./sshd-cli` *inside* `./sshd-cli`. |

## Scope notes

- Preferred language for reports: English.  
- Out of scope: social engineering of third parties, physical attacks, spam.  
- Domain: `auth-keys list` prints **public** key lines by design; never print private keys.  
- Related product docs: [`README.md`](./README.md), [`LICENSE.md`](./LICENSE.md), [`CHANGELOG.md`](./CHANGELOG.md).
