**file**: docs/requirements/requirement-python-tui.md
**Status**: Active (Version 1.0.0)
**Area**: python
**Key**: `requirement-python-tui`
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

The text menu is the front of SshCli. It keeps the HelloTui screen (path line, local clock, display columns, rounded input box, key model, result scroll) and puts the sshd-cli boards on that screen.

### 1.1 Human-facing

**In one sentence:** On a terminal, `sshd-cli` with no arguments opens a numbered menu. The first line is the folder and a clock. You pick a number, or you type a short name.

| Includes | Excludes |
|----------|----------|
| Rows 1, 2, 3, 4, 5, 8, and 9 as specified in `requirement-domain-sshd` §1.0 | Shell rows 6 and 7 |
| HelloTui children 31–33, 41–53, and 82–87 | Replacing the invalid-choice sentence with the old shell sentence |
| Typed `hello` welcome line, including when `hello` is typed on the open menu | Drawing the menu for the typed verb `hello` |

## 2. Core Rules (Mandatory)

1. The path line is `<label>: <directory>` plus the local clock `HH:MM:SS` when both fit. Width is display columns. Wide and Fullwidth count as two. Ambiguous counts as one. The directory and the clock are not translated.
2. The English path label is `Path`. The language requirement selects the label. `LANG` does not.
3. The input box is rounded and sits on the bottom. Arrows and j/k move. Esc leaves a result page or a nested board. On the front board, leaving the last way out exits. An unknown number stays on that board and says the choice is not on the list.
4. The one-second clock wait runs on front, self, log, lang, client, server, sudoers, and dns. It is not Esc.
5. A saved-language notice is painted before an error, and an error is painted before a menu-hidden info line.
6. Row 3 is system-log. Row 4 is language. Row 8 is self-management (version, about, and pip). Row 9 is Exit and returns 0. Pip rows are 84–87 and call `python -m pip`. They do not use sudo.
7. Self-uninstall on the command line needs `--force`. The menu row may run the uninstall without a second flag because the person picked the row.
8. `about` on the menu shows the about page. The about page itself has no `--json`.

## 3. Acceptance

- `tests/test_tui.py` keeps the path label, the clock, and the wide-column colon.
- `tests/test_hello.py` shows typed `hello` prints the welcome line and does not draw the menu, and typing `hello` on the menu shows that line.
- `tests/test_language.py` keeps row 4, codes 41–53, and mode 0600.
- `tests/test_domain.py` checks the front numbers, the hide sentences, and the child numbers.
