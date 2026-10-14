# Review reports index — sshd-cli

| Date | Report | Scope | Verdict | Suite |
|------|--------|-------|---------|-------|
| 2026-10-14 | Menu 5 / 6 / 7 | front **5** sudoers (**51–55**); **6** self-management (**61–67**, TTY **62**); **7** language block **70–89** (assigned **71–83**); front **8** not a row; TP-CLI-14 · TP-CLI-21 · TP-CLI-24 · TP-CFG-17 | Pass | PASS=1100 FAIL=0 SKIP=0 (`tests/run.sh`, product 1.34.0) |
| 2026-10-02 | Language menu 5 | front **5** language; block **50–69** (at most 20); assigned **51–58**; TP-CLI-14 · TP-CLI-24 | Pass | PASS=1065 FAIL=0 SKIP=0 (`tests/run.sh`, product 1.31.0) |
| 2026-09-27 | Cache folder checklist | per-login per-process cache; `requirement-shell-cli-storage` 1.3.0; TP-CLI-06 · 12 · 19 · 20 | Pass | PASS=817 FAIL=22 SKIP=0 (`tests/run.sh`); 22 are pre-existing TP-DL-* |
| 2026-09-12 | TTY download user prompt | `download` user walk vs `ssh`; TP-DL-10..13; INC-20260912-001 | closed | PASS=626 FAIL=0 SKIP=0 (`tests/run.sh`) |
| 2026-09-07 | ssh-config dns-ip commit gate | write/pick fidelity; TP-DNS-13..19 | closed | PASS=218 FAIL=0 SKIP=0 (`tests/run.sh`) |
| 2026-09-06 | ssh-config dns-ip | `dns` Host list / show / field walk / set; TP-DNS-01..12 | superseded | PASS=189 FAIL=0 SKIP=0 (`tests/run.sh`) |
| 2026-09-06 | Human-readability + coverage | REQ §1.1 / README voice; RTM vs tests; Git Bash / Windows cmd; TP-CSUM-01 | closed | PASS=128 FAIL=0 SKIP=0 (`tests/run.sh`) |
| 2026-08-19 | Housekeeping residual re-check | lessons L-* still open watch; class residual ARSA/dest-fence; no product-source change | living | PASS=82 FAIL=0 SKIP=0 (`tests/run.sh`) |
| 2026-08-13 | Bootstrap origin = this product | hop 0; no live parent (selfmanaged / folder-backup not origins) | living | see `tests/run.sh` |

Related products **selfmanaged** and **folder-backup** keep their own reviews. They are **not** this product’s law, origin, or evidence.
