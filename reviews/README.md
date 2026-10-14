# Reviews — sshd-cli

Public product review surface (peer of `tests/`).

| File | Role |
|------|------|
| `what-to-review.md` | Living review plan / checklist |
| `test-plan.md` | TP-* status map |
| `requirement-test-matrix.md` | Requirement → TP families |
| `lessons.md` | Durable failure modes to re-check |
| `index.md` | Report index |
| `reports/` | Dated review run reports |

**Ship unit:** `src/sshd-cli` / `./sshd-cli` (**VERSION 1.35.0**)  
**Suite:** `./tests/run.sh`  
**Last suite baseline:** see `test-plan.md`

**Review focus:** simplify Termux to install sshd; this-login self-install plus OpenSSH sshd domain.
