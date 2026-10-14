**file**: docs/requirements/requirement-shell-cli-default-interaction.md
**Status**: Active (Version 1.18.0)
**Area**: shell
**Key**: `requirement-shell-cli-default-interaction`
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **independent product law** for the sshd-cli **TTY numbered main menu**: front board **1 client-side / 2 server-side / 5 sudoers / 6 self-management / 7 language / 9 Exit**, child numbers that **keep the parent prefix** and **never repeat** a parent integer, plus a language block **70–89** (not more than 20 languages), **0 Back** on every submenu, and each command row printed as **number + bold short description + italic long description**.

A **zero-cli-verb** line (no command after switches; a switch such as `--debug` is still no command) follows `requirement-shell-cli-zero-arguments.md` when the run is **non-interactive**. **Interactive** zero-cli-verb and `menu`/`main` open this tree. When a layer hides rows, each cause prints a **menu-hidden message** before that layer’s numbered items. The choice on every layer is a current-shell `read` (**do not capture `read`**). Domain verbs (`status`, `dns`, `ssh`, …) stay owned by `requirement-domain-sshd.md`. This file owns **the numbered tree**, not those handlers. The board functions are `app_cmd_menu`, `app_cmd_menu_client`, `app_cmd_menu_server`, `app_cmd_menu_self`, and `app_cmd_menu_language` (`app_*`, so another project keeps the same names). Menu copy follows the saved language (`requirement-shell-cli-language`). The Terminology section defines every word this file uses for that tree. The rules in section 2 are the law. §2.11 quotes the live functions from `./sshd-cli`.

### 1.1 Human-facing

**In one sentence:** On a real terminal, `sshd-cli` with no command — a switch such as `--debug` is still no command — or `sshd-cli menu` shows client-side, server-side, language, sudoers, and self-management, each with unique numbers; **0** walks back; **9** leaves.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Picking numbered boards on a keyboard | `sshd-cli` or `sshd-cli --debug`, then `1` then `11` |
| The other role | Scripts and pipes that must not hang | `sshd-cli status` |
| Not this file | What `start` does to sshd; empty-argv install-ensure | Domain + zero-arguments peers |

| Includes | Excludes |
|----------|----------|
| Front **1 / 2 / 5 / 6 / 7 / 9**; language **70–89** (assigned **71–83**); client **11…**; server **21…**; self-management **61…**; dns **111…**; sudoers **51…**; **0** Back | Restarting a submenu at **1**; `help` / `rc-test` as numbered rows; front **8** as a row |
| Bold short + italic long on every command row | Help pages; JSON catalogs |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./sshd-cli` | ship unit | live menu |
| `sshd-cli menu` | command | same tree |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Open the front board | Client, server, sudoers, self-management, language, plus Exit | `sshd-cli` or `sshd-cli --debug` on a terminal |
| Change the menu language | Language board, then one of the thirteen languages | `7` then `71` through `83` |
| Open SSH names | Client board then dns | `1` then `11` (or type `dns`) |
| Leave a side board | Back to the parent list | `0` |
| Finish a command on a side board | Front board again (not that submenu) | `6` then `65`, then 1/2/5/6/7/9 |
| Leave the program | Front Exit | `9` |
| Read why sudoers, backup, or daemon rows are missing | The reason is printed above the numbers on that board | Termux front board; Termux client board; non-root server board |

## 2. Core Rules / Requirements (Mandatory)

**Claimed:** yes. A zero-arguments requirement already exists, so this file owns the numbered tree and does not replace that requirement’s non-interactive path. An **interactive zero-cli-verb** (no verb after switch parse; switches allowed; real terminal and not quiet/json) and `menu`/`main` draw this tree. A **non-interactive** zero-cli-verb (`--quiet`, `--json`, or no TTY, even with other switches and no verb) is CLI self-install (`requirement-shell-cli-self-install`). `menu` off-TTY fails closed (`menu needs a terminal`). Interactive `menu --json` still draws the tree.

### 2.1 Front board

| Number | Short | Long | Runs |
|--------|-------|------|------|
| **1** | client-side | this login OpenSSH client (`~/.ssh/config`, ssh, folders) | Client submenu |
| **2** | server-side | this host OpenSSH sshd (listen, keys, port) | Server submenu |
| **5** | sudoers | grant and drafts for passwordless sudo | Sudoers submenu (POSIX Linux only; hidden on Termux / Git Bash / Windows cmd) |
| **6** | self-management | this CLI install, version, update, uninstall | Self-management submenu |
| **7** | language | display language for this menu | Language submenu (every host; §2.6.1) |
| **9** | Exit | leave the program | Return 0 |

**MUST NOT** list install, version, about, self-update, self-uninstall, help, menu, or `rc-test` on this board.

**Menu-hidden message** for hiding **5** on Termux / Git Bash / Windows cmd belongs on this board, before the numbered items (§2.2.3): `sudoers not available for termux` / `gitbash` / `windows-cmd`. The client-board sentence covers backup-config and sync-config only.

**Layered menu design (CLI main menu hierarchy table).** The tables in §2.1, §2.4–§2.7, and §2.6.1 are the single catalog of every numbered board. The design is a stack of menu layers, not one flat list. Each row records **number**, **parent**, **short description**, **long description**, **what it runs**, and **who sees it**. The short and long text in those tables is the English catalog. When the saved language is one of the twelve codes besides English, the same numbers print that language’s copy (`requirement-shell-cli-language`). Category rows (`client-side`, `server-side`, `language`, `sudoers`, `self-management`) open the child board. A category row is not a live command token. A leaf row runs an operational verb: the short text is that verb, and the long text is the one-line explain. README capture shows **every** layer in this catalog (front, language, client, server, sudoers, self-management, dns actions), as markdown bold and italic, with no raw CSI.

**Shared numbers (well-known menu).** This product keeps the shared card: front **1** client-side, **2** server-side, **6** self-management, **9** Exit, and under **6** the rows **61–67**. **61** `install` is payload or local place. **67** `self-install` places this CLI only. Front **5** sudoers (**51–55**), front **7** language (block **70–89**, assigned **71–83**), client **11–18**, server **21–24**, and dns **111–114** are this product’s extra rows on the same catalog. Shared command words on submenu **6** are `install`, `version`, `about`, `version-check`, `self-update`, `self-uninstall`, and `self-install`. `menu` and `main` open this tree and are not rows. `help` is not a row. Domain words (`dns`, `ssh`, `start`, and the other leaf tokens in §2.4–§2.7) are live commands and are not that shared card. A gap name (a word the law names that the dispatcher does not accept yet) and every test-purpose verb stay off every numbered list.

**Numbered lists of CLI verbs.** Every menu layer is a numbered list. A leaf row is a CLI verb (an operational verb the dispatcher accepts). A category row is not a verb; it opens the next numbered list. `menu` and `main` open the tree and are not rows on any list.

### 2.2 Numbering

These rules are **CLI main menu numbering**, the non-repeating number prefix for this menu. A command number appears once in the whole tree. A child number starts with its parent’s digits as the prefix, except the language block **70–89** under front **7**.

**MUST:**

1. Command numbers are **unique** in the whole tree.  
2. Child command numbers **start with the parent’s digits** (**11…** under **1**, **21…** under **2**, **51…** under **5**, **61…** under **6**, **111…** under **11**). The language board is the exception: front **7** reserves **70** through **89** for language rows and for no other row. Those twenty numbers are the whole language catalog, so this menu offers **not more than 20 languages**. Thirteen are assigned: **71** English, **72** 简体中文, **73** 繁體中文, **74** Español, **75** العربية, **76** Français, **77** Português, **78** Русский, **79** Deutsch, **80** 日本語, **81** 한국어, **82** Nederlands, **83** Ελληνικά. **70** and **84** through **89** are reserved and are not printed. Front **8** is not a row. A pick of an unassigned number in **70–89** is an invalid choice on the language board.  
3. Every submenu and data picker prints **0** Back (return to parent). Empty on a submenu **MUST** mean Back.  
4. Hidden rows keep their number (reserved). A hidden number is an unknown choice: warn and reprint **that** list. **MUST NOT** `out_die`.  
5. Host / folder / extra-setting pickers stay **1…N** plus **0** (item indexes).

**MUST NOT** restart a submenu at **1**. **MUST NOT** use **9** as submenu Exit. **0** is not a command. Front Exit stays **9** while the front board has at most eight command rows. A verb token typed at any numbered prompt still runs that handler.

### 2.2.1 After a finished command

This return is the **command-finished front board**: the default is to go back to the top menu after a command runs.

**MUST:** after a **valid leaf** (numbered command, typed verb, language pick **71** through **83**, or nested action board such as dns / sudoers) finishes, redisplay the **front board** (1 / 2 / 5 / 6 / 7 / 9). **MUST NOT** redisplay the submenu that launched that command. People-facing: after a command finishes, the top numbered list comes back. A language pick redisplays that board in the language just saved.

**MUST NOT** treat this as invalid-choice retry. Unknown / hidden-row numbers still warn and reprint **that** layer. **0** / empty / EOF on a submenu still means Back (parent). Front **9** / empty still leaves. A typed leaf on the front board itself also redisplays the front board (does not exit).

### 2.2.2 Invalid choice

An invalid choice is any input that is not a listed number, not a listed name, and not this layer’s leave or back token. A hidden reserved number is an invalid choice on that layer. Unused integers count.

**MUST:** print a warn that names the token and tells the operator to choose a listed number or command name (`out_warn`), reprint **this** layer, and read again in the current shell.

**MUST NOT** `out_die` for that pick. **MUST NOT** exit non-zero solely for that pick. **MUST NOT** treat the pick as an unknown command-line verb. EOF / a failed `read` leaves this layer without spinning.

### 2.2.3 Menu-hidden message

A **menu-hidden message** is the line that names why rows of **this** menu layer are omitted. Each distinct cause prints its own message before the numbered items of the layer those rows belong to.

**MUST:**

1. Print the message on the same layer as the omitted rows, after that layer’s header and before the first numbered item.  
2. Use one message when one cause omits several rows on that same layer.  
3. Use a separate message for a different cause. A message on a child layer does not cover a hidden row on the parent.  
4. Reprint that message every time the layer is drawn, including when invalid-choice retry reprints the layer. The message still comes before the numbers.  
5. Leave the omitted numbers reserved (§2.2). A later pick of a hidden number stays invalid-choice retry (§2.2.2).

**MUST NOT** print the message after the numbered items. **MUST NOT** fold two causes into one sentence. **MUST NOT** use the invalid-choice warn as this message. **MUST NOT** give the message a command number. **MUST NOT** renumber the rows that remain.

A token that stays available by name and is absent as a number by design is not a hide cause. On POSIX Linux, **18** `sync-from-remote` is that kind of typed command, so the client board has no menu-hidden message for **18**.

**Live sentences:**

| Layer | Cause | Message before the numbers | Ship unit |
|-------|--------|----------------------------|-----------|
| Client | Termux / Git Bash / Windows cmd omits **15** backup-config and **16** sync-config | `backup-config and sync-config not available for termux` / `gitbash` / `windows-cmd` | have — **TP-SSHD-04**, **TP-CFG-04**, **TP-CFG-05**, **TP-CFG-09** |
| Server | POSIX Linux and this login is not root: **22–24** omitted | `start/stop/restart sshd features are not available for non-root in <OS-Name>` | have — **TP-SSHD-03** |
| Front | Termux / Git Bash / Windows cmd omits **5** sudoers | `sudoers not available for termux` / `gitbash` / `windows-cmd` | have — **TP-SSHD-04**, **TP-CFG-04**, **TP-CFG-05**, **TP-CFG-09** |

**OS-Name** for the server sentence is `/etc/os-release` `NAME=` with quotes stripped, else `uname -s`, else `Linux`. **MUST NOT** hardcode Ubuntu. **MUST NOT** wrap `sudo` to unhide **22–24**. The functions that print these sentences, and the front board that still omits the **5** reason, are quoted in §2.11.

### 2.2.4 Do not capture `read`

**Do not capture `read`** is the call shape for every choice on this tree: the front board, each submenu, each nested action board, each data picker (Host, folder, extra settings), and a yes/no approval question opened from a valid pick.

**MUST:**

1. Read the board choice with `read` in the **current shell**, into the choice variable. The same shape on every layer, including the reprint after invalid-choice retry.  
2. Call any helper whose body contains `read` in the current shell. That includes `prompt_ask`, `prompt_yes_no`, and a future menu-choice reader.  
3. Take a yes/no from `prompt_yes_no` by its exit status (`if prompt_yes_no; then`). Empty on that question still means no (§2.8).  
4. Leave `$()` for pure-data helpers that never `read` (a user name, a path, a label).

**MUST NOT** wrap `read`, or a function whose body contains `read`, in `$()` or backticks. **MUST NOT** treat a prompt on stderr, or `read` from `/dev/tty` inside the helper, as permission to keep that capture. The assignment inside the child shell does not become the parent’s choice.

**This ship unit:** each menu loop uses `read -r` in the current shell (`app_cmd_menu` and the child boards). `prompt_yes_no` is called in the current shell. `prompt_ask` still prints its answer on stdout and these boards do not call it. New menu and picker choice code stays on the current-shell `read`. **MUST NOT** add `_choice=$(prompt_ask …)`. Those menu functions are quoted in §2.11. `prompt_ask` and `prompt_yes_no` are quoted in `requirement-shell-interactive-vs-noninteractive`. Coding home for the same ban outside this tree: `requirement-shell-script-coding`.

### 2.3 Style

**Default CLI main menu style** (default menu style) applies to every numbered layer.

Every command row **MUST** print **number**, **bold** short description, *italic* long description (`out_menu_choice`). On a TTY the short name is bold (SGR 1) and the long description is italic and light gray (SGR 3;37). The header on every layer **MUST** be the identity token `**sshd-cli**(*VERSION*)`: bold name, italic version, no space between them. A bare `sshd-cli` on that header is not enough. The Exit row is plain `9. Exit` (no gray explain). Off-TTY / JSON: plain text, no CSI. README transcribes markdown bold/italic and shows every layer; **MUST NOT** paste raw CSI.

### 2.4 Client submenu (parent **1**)

| Number | Short | Who |
|--------|-------|-----|
| **11** dns | Host list | Always |
| **12** ssh | OpenSSH client | Always |
| **13** download | remote tar.gz | Always |
| **14** upload | local tar.gz | Always |
| **15** backup-config | | POSIX Linux only |
| **16** sync-config | | POSIX Linux only |
| **18** sync-from-remote | | Termux / Git Bash / Windows cmd numbered; POSIX Linux typed |
| **0** Back | | Always |

**Menu-hidden message** for this cause (§2.2.3), before the numbered items: `backup-config and sync-config not available for termux` / `gitbash` / `windows-cmd`. One cause covers **15** and **16**.

### 2.5 Server submenu (parent **2**)

| Number | Short | Who |
|--------|-------|-----|
| **21** status | Always |
| **22** start | Termux class always; POSIX Linux root only (reserved hidden otherwise) |
| **23** stop | Same as **22** |
| **24** restart | Same as **22** |
| **0** Back | Always |

**Menu-hidden message** for this cause (§2.2.3), before the numbered items: `start/stop/restart sshd features are not available for non-root in <OS-Name>`. **MUST NOT** wrap `sudo` to unhide **22–24**.

### 2.6 Self-management submenu (parent **6**)

| Number | Short | TTY |
|--------|-------|-----|
| **61** | install | Place / ensure |
| **62** | version | Runs **about** (diagnostics). Argv `version` stays a one-liner. **INC-20260914-001**. |
| **63** | about | Same diagnostics as **62** on TTY |
| **64** | version-check | Local vs remote |
| **65** | self-update | Channel replace |
| **66** | self-uninstall | Remove |
| **67** | self-install | Place this CLI only (copy or download) |
| **0** | Back | Return to front |

### 2.6.1 Language submenu (parent **7**)

| Number | Short | Long | Runs |
|--------|-------|------|------|
| **71** | English | use English for this menu | Save `en` and return to the front board |
| **72** | 简体中文 | use Simplified Chinese for this menu | Save `zh-Hans` and return to the front board |
| **73** | 繁體中文 | use Traditional Chinese for this menu | Save `zh-Hant` and return to the front board |
| **74** | Español | use Spanish for this menu | Save `es` and return to the front board |
| **75** | العربية | use Arabic for this menu | Save `ar` and return to the front board |
| **76** | Français | use French for this menu | Save `fr` and return to the front board |
| **77** | Português | use Portuguese for this menu | Save `pt` and return to the front board |
| **78** | Русский | use Russian for this menu | Save `ru` and return to the front board |
| **79** | Deutsch | use German for this menu | Save `de` and return to the front board |
| **80** | 日本語 | use Japanese for this menu | Save `ja` and return to the front board |
| **81** | 한국어 | use Korean for this menu | Save `ko` and return to the front board |
| **82** | Nederlands | use Dutch for this menu | Save `nl` and return to the front board |
| **83** | Ελληνικά | use Greek for this menu | Save `el` and return to the front board |
| **0** | Back | | Return to the front board |

**71** through **83** are valid leaves: the front board redisplays in the chosen language. **0** / empty / EOF is Back and does not change the saved language. The short names stay each language’s own name in every language. Typed tokens for each row are `requirement-shell-cli-language` §2.3. Which strings follow the saved language, and where the code is stored, is that file. The worked samples of the front board in each language, and the opening of human `help` and human `about`, are that file’s §2.4.1. The language-board longs in every language, the choose-prompt, the menu-hidden sentences, and the unknown-choice warns are §2.4.2. The live board is `app_cmd_menu_language`, quoted there. This table is the English catalog. Numbers **70** and **84** through **89** are reserved for later languages and are not rows in this table. The block **70–89** is twenty numbers, so the board never offers more than 20 languages. Front **8** is not a row.

Row **7** is numbered on every host, including Termux, Git Bash, and Windows cmd. It is not a hide cause.

### 2.7 Nested action boards

Dns (under **11**): **111** Edit, **112** Add, **113** Delete, **114** Unset, **0** Back.  
Sudoers (under **5**): **51** generate-sudoer-request, **52** submit-sudoer-request, **53** print-sudoers, **54** print-sudoers-install-script, **55** remove-project-sudoers, **0** Back.

Each of these boards is its own menu layer. Typed verb names still dispatch. An invalid choice warns, reprints **this** layer, and reads again. A finished action on either board is a valid leaf: the front board redisplays. **0** on the dns board returns to the client board (its parent). **0** on the sudoers board returns to the front board (its parent). The choice follows **do not capture `read`** (§2.2.4): a current-shell `read` into the choice variable.

### 2.8 Menu layer

**Layered menu design** is this stack of boards. A **menu layer** is the one numbered list that owns the current `read`. The front board is a layer. Client, server, language, sudoers, self-management, dns actions, and each data picker (Host, folder, extra settings) are layers. Each of those lists is a numbered list of CLI verbs, except a category row, which opens the next layer.

| This layer | Leave / back tokens | Where you land |
|------------|---------------------|----------------|
| Front board | **9**, **99**, **999**, `exit`, empty line, EOF | Leave the program (return 0) |
| Client, server, language, self-management | **0**, `q`, empty line, EOF | Parent (the front board) |
| Sudoers, dns actions | **0**, `q`, `exit`, empty line, EOF | Parent (front board for sudoers; client board for dns) |
| Data picker | **0** plus that picker’s leave token | The board that opened the picker |

The `read` on every row of that table follows **do not capture `read`** (§2.2.4). A wrong pick stays on this layer (§2.2.2). A one-shot yes/no after a valid pick is an approval question. It is not a numbered layer, it has no menu number, and empty means no. Who may run a verb (Type 0, Type 1, Type 2) is three-layer privilege. That classification is not a menu layer.

### 2.9 When the tree is drawn

This tree is the numbered main menu. An **interactive zero-cli-verb** draws it: no command token after switches are parsed, on a real terminal, and not quiet and not json. `sshd-cli`, `sshd-cli --debug`, and `sshd-cli --force` with no command are that line when the terminal is real and quiet/json are off. `menu` / `main` draw the same tree. Interactive `menu --json` still draws it. A switch is not a command. Off a terminal, under quiet, or under `--json`, a zero-cli-verb line is **non-interactive** and does not draw this tree. That path is Type O empty argv (CLI self-install), owned by `requirement-shell-cli-zero-arguments` and `requirement-shell-cli-self-install`. This file does not replace that path. `menu` / `main` off a terminal fails closed with a named-command hint and does not wait. That split is interactive vs noninteractive. Type O is the letter **O**. Privilege Type 0 is the digit **0**.

### 2.10 Implementation Notes (this project)

| Field | Value |
|-------|--------|
| Claimed | yes |
| When drawn | Interactive zero-cli-verb and `menu` / `main` on a terminal |
| Handler | `app_cmd_menu` · `app_cmd_menu_client` · `app_cmd_menu_server` · `app_cmd_menu_self` · `app_cmd_menu_language` (`app_*`; **MUST NOT** use the domain prefix for these boards) |
| Printer | `out_menu_choice` |
| Ship unit | `./sshd-cli` |
| Zero-cli-verb gate | After switches, no verb left. Interactive (a real terminal, not quiet, not json) → this tree (`sshd-cli`, `sshd-cli --debug`, `sshd-cli --force`). Non-interactive → Type O CLI self-install. The no-token line uses the same split before flag parse. **TP-CLI-14** proves the no-token line. **TP-CLI-23** proves `--debug` / `--force` on a terminal, and `--quiet` / `--json` / non-TTY `--debug` with no verb. |
| Menu-hidden message | Client, server, and front **5** sentences above are have. |
| Choice read | Current-shell `read -r` in each menu loop. `prompt_yes_no` is called in the current shell. `prompt_ask` still prints its answer on stdout and is not used for these boards. |
| Functions | §2.11 quotes `sshd_os_name`, `sshd_menu_show_daemon_rows`, `sshd_host_normal_user_only_label`, `app_cmd_menu_client`, `app_cmd_menu_server`, `app_cmd_menu_self`, and `app_cmd_menu` from `./sshd-cli`. `app_lang_load`, `app_lang_save`, `app_menu_text`, and `app_cmd_menu_language` are quoted in `requirement-shell-cli-language` |
| Proof | `tests/test_cli.sh` **TP-CLI-14** · **TP-CLI-21** · **TP-CLI-22** · **TP-CLI-23** · **TP-CLI-24** · **TP-SSHD-03..05** · **TP-SSHD-16**; `tests/test_dns.sh` **TP-DNS-13** · **TP-DNS-20** · **TP-DNS-21** · **TP-DNS-47**; `tests/test_config_backup.sh` **TP-CFG-04** · **TP-CFG-05** · **TP-CFG-09** · **TP-CFG-17**; `tests/test_ssh_download.sh` **TP-UL-18** |
| Map | `reviews/test-plan.md` |

### 2.11 Ship-unit functions

These bodies are the current text of `./sshd-cli` (the same bytes as `src/sshd-cli`). They show the menu-hidden message and the current-shell `read`. Section 2 is the law. A note under a heading records a Gap the function shows. Comment lines inside a fence are copied as the ship unit writes them.

**Front board (`app_cmd_menu`).** On Termux / Git Bash / Windows cmd the function omits row **5** and prints `sudoers not available for termux` / `gitbash` / `windows-cmd` before the numbered items. Row **7** stays numbered on that host. Front **8** is not a row. The same function calls `out_die` when `JSON` is 1, when `QUIET` is 1, or when `TTY` is not 1. §2.9 still says interactive `menu --json` draws the tree. That §2.9 sentence stays the known gap. The sample is the function the ship unit runs. `app_main` calls `app_lang_load` once, after persistence is resolved and before dispatch. This function prints rows through `app_menu_text`.

**Menu copy.** The short and long strings in these fences are calls to `app_menu_text`. The English words in §2.1–§2.6.1 are what that helper prints when `APP_LANG` is `en`. The other languages’ text, the language file, and `app_cmd_menu_language` are quoted in `requirement-shell-cli-language`.

**Client board (`app_cmd_menu_client`).** Choice `11` / `dns` calls `sshd_cmd_dns` and then `return 0`. Back from the dns action board lands on the front board. §2.7 says **0** on the dns board returns to the client board.

**Server helper comment.** The comment on `sshd_menu_show_daemon_rows` says "Numbered menu rows 2/3/4". The live numbers are **22–24**.

**`$()` in the helpers.** `sshd_os_name` and `sshd_menu_show_daemon_rows` use `$()` to read a name or a uid. Those helpers do not `read` a choice (§2.2.4).

#### `sshd_os_name`

```sh
# Host OS display name for operator copy (not a platform class).
# /etc/os-release NAME= first; else uname -s; else Linux.
sshd_os_name() {
    _name=""
    if [ -r /etc/os-release ]; then
        _name=$(grep -E '^NAME=' /etc/os-release 2>/dev/null | head -n 1 || true)
        _name=${_name#NAME=}
        _name=${_name#\"}
        _name=${_name%\"}
        _name=${_name#\'}
        _name=${_name%\'}
    fi
    if [ -z "${_name}" ]; then
        _name=$(uname -s 2>/dev/null || true)
    fi
    if [ -z "${_name}" ]; then
        _name="Linux"
    fi
    printf '%s' "${_name}"
    unset _name
}
```

#### `sshd_menu_show_daemon_rows`

```sh
# Numbered menu rows 2/3/4 (start/stop/restart): this login on a
# command-line-for-normal-user-only host, or a root login on POSIX Linux.
sshd_menu_show_daemon_rows() {
    if sshd_is_normal_user_only_cli; then
        return 0
    fi
    if [ "$(id -u 2>/dev/null || echo 1)" -eq 0 ]; then
        return 0
    fi
    return 1
}
```

#### `sshd_host_normal_user_only_label`

```sh
sshd_host_normal_user_only_label() {
    if sshd_is_termux; then
        printf '%s' "termux"
        return 0
    fi
    if sshd_is_git_bash; then
        printf '%s' "gitbash"
        return 0
    fi
    if sshd_is_windows_cmd; then
        printf '%s' "windows-cmd"
        return 0
    fi
    printf '%s' ""
}
```

#### `app_cmd_menu_client`

```sh
# Last updated: 2026-09-28
# ALIGNMENT: requirement-shell-cli-default-interaction
# A valid leaf (or nested action board) returns to the front board. Unknown
# choice retries this layer. 0 / empty / EOF is Back.
app_cmd_menu_client() {
    _show_cfg=1
    if sshd_is_normal_user_only_cli; then
        _show_cfg=0
    fi
    while true; do
        out_info "**${APP_NAME}**(*${VERSION}*) — $(app_menu_text cat_client)"
        if [ "${_show_cfg}" -eq 0 ]; then
            out_info "$(app_menu_text hidden_client "$(sshd_host_normal_user_only_label)")"
        fi
        out_menu_choice "11" "dns" "$(app_menu_text client_11_long)"
        out_menu_choice "12" "ssh" "$(app_menu_text client_12_long)"
        out_menu_choice "13" "download" "$(app_menu_text client_13_long)"
        out_menu_choice "14" "upload" "$(app_menu_text client_14_long)"
        if [ "${_show_cfg}" -eq 1 ]; then
            out_menu_choice "15" "backup-config" "$(app_menu_text client_15_long)"
            out_menu_choice "16" "sync-config" "$(app_menu_text client_16_long)"
            out_plain "$(app_menu_text hint_sync_typed)"
        else
            out_menu_choice "18" "sync-from-remote" "$(app_menu_text client_18_long)"
        fi
        out_plain "$(app_menu_text line_back)"
        out_msg_n "$(app_menu_text line_prompt)"
        _choice=""
        if ! read -r _choice; then
            unset _choice _show_cfg
            return 0
        fi
        case "${_choice}" in
            11|dns)
                sshd_cmd_dns
                unset _choice _show_cfg
                return 0
                ;;
            12|ssh)
                sshd_cmd_ssh
                unset _choice _show_cfg
                return 0
                ;;
            13|download)
                sshd_cmd_download
                unset _choice _show_cfg
                return 0
                ;;
            14|upload)
                sshd_cmd_upload
                unset _choice _show_cfg
                return 0
                ;;
            15)
                if [ "${_show_cfg}" -eq 1 ]; then
                    sshd_cmd_backup_config
                    unset _choice _show_cfg
                    return 0
                fi
                out_warn "$(app_menu_text unknown_menu "${_choice}")"
                continue
                ;;
            16)
                if [ "${_show_cfg}" -eq 1 ]; then
                    sshd_cmd_sync_config
                    unset _choice _show_cfg
                    return 0
                fi
                out_warn "$(app_menu_text unknown_menu "${_choice}")"
                continue
                ;;
            18)
                if [ "${_show_cfg}" -eq 0 ]; then
                    sshd_cmd_sync_from_remote
                    unset _choice _show_cfg
                    return 0
                fi
                out_warn "$(app_menu_text unknown_menu "${_choice}")"
                continue
                ;;
            0|q|"")
                unset _choice _show_cfg
                return 0
                ;;
            *)
                if sshd_menu_typed_leaf; then
                    unset _choice _show_cfg
                    return 0
                fi
                out_warn "$(app_menu_text unknown_menu "${_choice}")"
                continue
                ;;
        esac
    done
}
```

#### `app_cmd_menu_server`

```sh
# Last updated: 2026-09-28
# ALIGNMENT: requirement-shell-cli-default-interaction
# A valid leaf returns to the front board. Unknown choice retries this layer.
# 0 / empty / EOF is Back.
app_cmd_menu_server() {
    _show_daemon=0
    if sshd_menu_show_daemon_rows; then
        _show_daemon=1
    fi
    while true; do
        out_info "**${APP_NAME}**(*${VERSION}*) — $(app_menu_text cat_server)"
        if [ "${_show_daemon}" -eq 0 ]; then
            out_info "$(app_menu_text hidden_server "$(sshd_os_name)")"
        fi
        out_menu_choice "21" "status" "$(app_menu_text server_21_long)"
        if [ "${_show_daemon}" -eq 1 ]; then
            out_menu_choice "22" "start" "$(app_menu_text server_22_long)"
            out_menu_choice "23" "stop" "$(app_menu_text server_23_long)"
            out_menu_choice "24" "restart" "$(app_menu_text server_24_long)"
        fi
        out_plain "$(app_menu_text line_back)"
        out_msg_n "$(app_menu_text line_prompt)"
        _choice=""
        if ! read -r _choice; then
            unset _choice _show_daemon
            return 0
        fi
        case "${_choice}" in
            21|status)
                sshd_cmd_status
                unset _choice _show_daemon
                return 0
                ;;
            22)
                if [ "${_show_daemon}" -eq 1 ]; then
                    sshd_cmd_start
                    unset _choice _show_daemon
                    return 0
                fi
                out_warn "$(app_menu_text unknown_menu "${_choice}")"
                continue
                ;;
            23)
                if [ "${_show_daemon}" -eq 1 ]; then
                    sshd_cmd_stop
                    unset _choice _show_daemon
                    return 0
                fi
                out_warn "$(app_menu_text unknown_menu "${_choice}")"
                continue
                ;;
            24)
                if [ "${_show_daemon}" -eq 1 ]; then
                    sshd_cmd_restart
                    unset _choice _show_daemon
                    return 0
                fi
                out_warn "$(app_menu_text unknown_menu "${_choice}")"
                continue
                ;;
            0|q|"")
                unset _choice _show_daemon
                return 0
                ;;
            *)
                if sshd_menu_typed_leaf; then
                    unset _choice _show_daemon
                    return 0
                fi
                out_warn "$(app_menu_text unknown_menu "${_choice}")"
                continue
                ;;
        esac
    done
}
```

#### `app_cmd_menu_self`

```sh
# Last updated: 2026-10-14
# ALIGNMENT: requirement-shell-cli-default-interaction
# A valid leaf returns to the front board. Unknown choice retries this layer.
# 0 / empty / EOF is Back. Children are 61-67 under front 6.
app_cmd_menu_self() {
    while true; do
        out_info "**${APP_NAME}**(*${VERSION}*) — $(app_menu_text cat_self)"
        out_menu_choice "61" "install" "$(app_menu_text self_61_long)"
        out_menu_choice "62" "version" "$(app_menu_text self_62_long)"
        out_menu_choice "63" "about" "$(app_menu_text self_63_long)"
        out_menu_choice "64" "version-check" "$(app_menu_text self_64_long)"
        out_menu_choice "65" "self-update" "$(app_menu_text self_65_long)"
        out_menu_choice "66" "self-uninstall" "$(app_menu_text self_66_long)"
        out_menu_choice "67" "self-install" "$(app_menu_text self_67_long)"
        out_plain "$(app_menu_text line_back)"
        out_msg_n "$(app_menu_text line_prompt)"
        _choice=""
        if ! read -r _choice; then
            unset _choice
            return 0
        fi
        case "${_choice}" in
            61|install)
                inst_perform_install
                unset _choice
                return 0
                ;;
            62|version)
                app_about
                unset _choice
                return 0
                ;;
            63|about)
                app_about
                unset _choice
                return 0
                ;;
            64|version-check)
                ver_check
                unset _choice
                return 0
                ;;
            65|self-update)
                inst_self_update
                unset _choice
                return 0
                ;;
            66|self-uninstall)
                inst_self_uninstall
                unset _choice
                return 0
                ;;
            67|self-install)
                inst_self_install
                unset _choice
                return 0
                ;;
            0|q|"")
                unset _choice
                return 0
                ;;
            *)
                if sshd_menu_typed_leaf; then
                    unset _choice
                    return 0
                fi
                out_warn "$(app_menu_text unknown_menu "${_choice}")"
                continue
                ;;
        esac
    done
}
```

#### `app_cmd_menu`

```sh
# Last updated: 2026-10-14
# ALIGNMENT: requirement-shell-cli-default-interaction · requirement-shell-cli-language.md · requirement-shell-cli-zero-arguments
# Front board loops until Exit. Category rows open a submenu.
# POSIX Linux row 5 opens sudoers (51-55). Termux, Git Bash, and Windows cmd
# omit row 5 and print why before the numbers. Row 5 stays reserved when hidden.
# Row 6 opens self-management (61-67). Row 7 opens language.
# Rows 70-89 are reserved for at most 20 languages.
# Assigned: 71 English, 72 Simplified Chinese, 73 Traditional Chinese,
# 74 Spanish, 75 Arabic, 76 French, 77 Portuguese, 78 Russian, 79 German,
# 80 Japanese, 81 Korean, 82 Dutch, 83 Greek. 70 and 84-89 stay unprinted.
# A finished leaf redisplays this board. Unknown choice retries this layer.
# Front 8 is not a row.
app_cmd_menu() {
    if [ "${JSON}" -eq 1 ] || [ "${QUIET}" -eq 1 ] || [ "${TTY}" -ne 1 ]; then
        out_die "menu needs a terminal. Run a named command instead, for example: ${APP_NAME} status"
    fi
    _show_sudoers=1
    if sshd_is_normal_user_only_cli; then
        _show_sudoers=0
    fi
    while true; do
        out_info "**${APP_NAME}**(*${VERSION}*)"
        if [ "${_show_sudoers}" -eq 0 ]; then
            out_info "$(app_menu_text hidden_front "$(sshd_host_normal_user_only_label)")"
        fi
        out_menu_choice "1" "$(app_menu_text cat_client)" "$(app_menu_text front_client_long)"
        out_menu_choice "2" "$(app_menu_text cat_server)" "$(app_menu_text front_server_long)"
        if [ "${_show_sudoers}" -eq 1 ]; then
            out_menu_choice "5" "sudoers" "$(app_menu_text front_sudoers_long)"
        fi
        out_menu_choice "6" "$(app_menu_text cat_self)" "$(app_menu_text front_self_long)"
        out_menu_choice "7" "$(app_menu_text cat_language)" "$(app_menu_text front_language_long)"
        out_plain "$(app_menu_text line_exit)"
        out_msg_n "$(app_menu_text line_prompt)"
        _choice=""
        if ! read -r _choice; then
            unset _choice _show_sudoers
            return 0
        fi
        case "${_choice}" in
            1|client-side|用戶端|客户端|cliente|client|Client|クライアント|클라이언트|عميل|клиент|πελάτης) app_cmd_menu_client; continue ;;
            2|server-side|伺服器端|服务器端|servidor|serveur|Server|server|サーバー|서버|خادم|сервер|διακομιστής) app_cmd_menu_server; continue ;;
            5)
                if [ "${_show_sudoers}" -eq 1 ]; then
                    sshd_cmd_sudoers_menu
                    continue
                fi
                out_warn "$(app_menu_text unknown_menu "${_choice}")"
                continue
                ;;
            6|self-management|自我管理|autogestión|autogestão|autogestion|Selbstverwaltung|selbstverwaltung|自己管理|자기관리|إدارة-ذاتية|самоуправление|zelfbeheer|αυτοδιαχείριση) app_cmd_menu_self; continue ;;
            7|language|語言|语言|idioma|langue|Sprache|sprache|言語|언어|لغة|язык|taal|γλώσσα) app_cmd_menu_language; continue ;;
            9|99|999|exit|"")
                unset _choice _show_sudoers
                return 0
                ;;
            *)
                if sshd_menu_typed_leaf; then
                    continue
                fi
                out_warn "$(app_menu_text unknown_menu "${_choice}")"
                continue
                ;;
        esac
    done
}
```

### 2.x Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): one owner for the numbered tree so domain law does not keep a second integer map.  
- **CIAO Principle 5 – SSOT of output**: `out_menu_choice` is the row printer.  
- **CIAO Principle 16 – Interactive**: no hang off-TTY; invalid choice retries this layer.

## Under command line for normal user only

Who may run a verb is **three-layer privilege** (Type 0 normal user, Type 1 admin, Type 2 dedicated system user). It does not change menu numbers.

When Termux, Git Bash, or Windows cmd is detected: Type 1/2 unused; no in-tool sudo. **This requirement:** front **5** sudoers stays hidden; client **15–16** stay hidden; server **22–24** stay visible for this login; self-management **61–67** stay Type 0. Each of those hides is its own menu-hidden message, printed before that layer’s numbers (§2.2.3). The client sentence and the front-board sentence for **5** are have. Git Bash and Windows cmd do not invoke Termux `pkg`.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: unique numbers so a typed integer cannot mean two boards.  
- **Intentional**: independent file; domain points here.  
- **Anti-fragile**: reserved hidden numbers; each hide cause announced before that layer’s numbers; retry on this layer.  
- **Over-protect**: **0** Back on every submenu; do not capture `read`.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

- Restart a submenu at **1** or reuse **1 / 2 / 5 / 6 / 7** on a child list.  
- Put install / version / about on the **front** board.  
- Treat TTY **62 version** as done when it only reprints the board header; TTY **62** and typed `version` on a numbered board **MUST** run `about`. Argv `version` stays thin.  
- Own this tree only inside `requirement-domain-sshd.md`.  
- `out_die` on an unknown TTY menu number.  
- `$()` or backticks around the menu `read`, or around `prompt_ask`, `prompt_yes_no`, or any helper whose body contains `read`. A prompt on stderr, or `read` from `/dev/tty`, does not allow that capture.  
- Print short unstyled or long unstyled on a TTY.  
- After a valid leaf command, stay on the submenu that launched it — **MUST** redisplay the **front board**.
- Treat **0** on the dns board as a jump to the front board. **0** returns to the client board.
- Replace the Terminology section with file paths. The glossary names the word and gives the definition.
- Drop a design piece from §2: the catalog, the shared numbers, the integer grammar, the look, the menu layer, the menu-hidden message, do not capture `read`, invalid-choice retry, the command-finished front board, when the tree is drawn, or who-may-run.
- Print a hide reason after the numbered items, or let one layer’s message cover a hidden row on another layer.
- Invent a front-board sudoers sentence the ship unit does not print. The live sentence is `sudoers not available for termux` / `gitbash` / `windows-cmd`.
- Replace the §2.11 fences with a shortened or invented menu. Those fences stay the current `./sshd-cli` functions.
- Name these boards with the domain prefix. The handlers are `app_cmd_menu`, `app_cmd_menu_client`, `app_cmd_menu_server`, `app_cmd_menu_self`, and `app_cmd_menu_language`.
- Treat a switch (`--debug`, `--quiet`, `--json`, `--force`) as a command verb.
- Send an interactive zero-cli-verb to help or to install-ensure.
- Draw this tree for a non-interactive zero-cli-verb (no TTY, quiet, or `--json` with no command).

## 5. Definition of done

This requirement is satisfied when all of the following hold:

1. Interactive zero-cli-verb on a terminal (`sshd-cli`, `sshd-cli --debug`, `sshd-cli --force`, quiet and json off) draws front **1 / 2 / 5 / 6 / 7 / 9** and does not place the binary.  
2. `menu` / `main` on a terminal draw the same tree. `menu` / `main` off a terminal fails closed and does not wait.  
3. A non-interactive zero-cli-verb does not draw this tree. That path stays on `requirement-shell-cli-zero-arguments` and `requirement-shell-cli-self-install`.  
4. Child numbers keep the parent prefix. **0** on a submenu returns to the parent. Front **9** leaves.  
5. An invalid choice warns, names the token, and reprints that layer.  
6. After a valid leaf, the front board is shown again.  
7. TTY **62** and a typed `version` on a numbered board run `about`.  
8. The proof rows below are **have**.  
9. Each distinct hide cause prints its own menu-hidden message before that layer’s numbered items. The client, server, and front **5** sentences in §2.2.3 are have.  
10. Every menu layer, data picker, and yes/no from this tree reads in the current shell. `$()` and backticks are absent around any helper whose body contains `read`.  
11. Changes cite `requirement-shell-cli-default-interaction`.
12. §2.11 quotes the current `./sshd-cli` functions named there.

### Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CLI-14** interactive empty argv → front 1/2/5/6/7/9 | `tests/test_cli.sh` | have |
| **TP-CLI-24** menu **7** / block **70–89** (assigned **71–83**); file `language`; `SSHD_CLI_LANG`; human help and about | `tests/test_cli.sh` | have |
| **TP-CLI-21** TTY **62** / typed `version` run about | `tests/test_cli.sh` | have |
| **TP-CLI-22** finished leaf redisplays the front board | `tests/test_cli.sh` | have |
| **TP-CLI-23** TTY `--debug` / `--force` menu; `--quiet` / `--json` / non-TTY `--debug` do not draw the tree | `tests/test_cli.sh` | have |
| **TP-SSHD-03..05** · **TP-SSHD-16** server rows and invalid-choice retry | `tests/test_cli.sh` | have |
| **TP-SSHD-03** server menu-hidden message before the server numbers | `tests/test_cli.sh` | have |
| **TP-SSHD-04** · **TP-CFG-04** · **TP-CFG-05** · **TP-CFG-09** client menu-hidden message before the client numbers | `tests/test_cli.sh` · `tests/test_config_backup.sh` | have |
| **TP-SSHD-04** · **TP-CFG-04** · **TP-CFG-05** · **TP-CFG-09** front **5** menu-hidden message before the front numbers | `tests/test_cli.sh` · `tests/test_config_backup.sh` | have |
| **TP-DNS-13** · **TP-DNS-20** · **TP-DNS-21** · **TP-DNS-47** dns board | `tests/test_dns.sh` | have |
| **TP-CFG-17** sudoers **51–55** | `tests/test_config_backup.sh` | have |
| **TP-UL-18** upload row on the client board | `tests/test_ssh_download.sh` | have |

**Map:** `reviews/test-plan.md`

## 6. Related artifacts

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-shell-cli-zero-arguments.md` | Zero-cli-verb shape; non-interactive Type O owner |
| `docs/requirements/requirement-shell-cli-interface.md` | Dual mention `menu`/`main` |
| `docs/requirements/requirement-shell-cli-language.md` | Menu language codes, file, and `app_menu_text` |
| `docs/requirements/requirement-domain-sshd.md` | Domain handlers; points here for numbers |
| `docs/requirements/requirement-shell-interactive-vs-noninteractive.md` | No hang; retry |
| `docs/requirements/requirement-shell-script-coding.md` | Coding home for do not capture `read` outside this tree |
| `docs/requirements/requirement-shell-self-management.md` | install / self-update handlers |
| `./sshd-cli` | Implementation |
| `tests/test_cli.sh`, `tests/test_dns.sh`, `tests/test_config_backup.sh`, `tests/test_ssh_download.sh` | Regression coverage |

## 7. Revision history

| Date | Change | Author / agent |
|------|--------|----------------|
| 2026-09-14 | v1.0.0: independent numbered TTY menu; front **1 / 2 / 8 / 9** | Grok (Release 1.20.0) |
| 2026-09-14 | v1.0.1: TTY **82** runs about | Grok (Release 1.21.0) |
| 2026-09-27 | v1.2.0: sudoers is front **7** (children **71–75**) | Grok (Release 1.26.0) |
| 2026-09-28 | v1.5.0: interactive zero-cli-verb draws this tree; terminology lives in this file | Grok (Release 1.28.0) |
| 2026-09-28 | v1.6.0: same section shape as the other product requirements (definition of done, related artifacts, revision history). The numbered tree stays the law in this file. | Grok (owner request) |
| 2026-09-28 | v1.7.0: each hide cause prints its own menu-hidden message before that layer’s numbered items. Client and server sentences are have. Front **7** on Termux / Git Bash / Windows cmd is Gap. | Grok (owner request) |
| 2026-09-28 | v1.8.0: do not capture `read` is a core rule for every layer, picker, and yes/no on this tree. The choice is a current-shell `read`. | Grok (owner request) |
| 2026-09-28 | v1.9.0: §2.11 quotes the live `./sshd-cli` functions for the menu-hidden message and the current-shell `read`. | Grok (owner request) |
| 2026-09-28 | v1.10.0: menu handlers are `app_cmd_menu`, `app_cmd_menu_client`, `app_cmd_menu_server`, and `app_cmd_menu_self` (`app_*` CLI surface). | Grok (owner request) |
| 2026-09-28 | v1.11.0: front **6** language, children **61** English and **62** Traditional Chinese. Menu copy follows `requirement-shell-cli-language`. | Grok (owner request) |
| 2026-09-28 | v1.12.0: language children **63** Spanish, **64** French, **65** German, **66** Simplified Chinese. | Grok (owner request) |
| 2026-09-28 | v1.13.0: language children **67** Japanese and **68** Korean. `app_lang_load` runs in `app_main`, not in this front function. | Grok (owner request) |
| 2026-09-28 | v1.14.0: the English catalog in §2.6.1 stays here. Worked samples and translation tables live in `requirement-shell-cli-language` §2.4.1 and §2.4.2. | Grok (owner request) |
| 2026-10-02 | v1.15.0: front **5** language. Language rows are reserved **50–69** (not more than 20 languages). Assigned **51** English through **58** Korean. Front **6** is not a row. | Grok (owner request) |
| 2026-10-02 | v1.16.0: language rows **51** English, **52** Simplified Chinese, **53** Traditional Chinese, then native-speaker count through **63** Greek (`ar`, `pt`, `ru`, `nl`, `el`). **50** and **64–69** stay unprinted. Front **6** is not a row. | Grok (owner request) |
| 2026-10-14 | v1.18.0: front **5** sudoers (**51–55**), front **6** self-management (**61–67**), front **7** language (block **70–89**, assigned **71–83**). Front **8** is not a row. | Grok (owner request) |
| 2026-10-10 | v1.17.0: front **7** on Termux / Git Bash / Windows cmd prints `sudoers not available for termux` / `gitbash` / `windows-cmd` before the numbers. | Grok (owner request) |

## 8. Terminology

Words this requirement uses. Each row is the term and the definition this file means by it. No glossary file paths.

| Term | Definition |
|------|------------|
| **Zero-cli-verb** | No command token after switches are read. Switches (`--debug`, `--quiet`, `--json`, `--force`, and the other global flags) are allowed and are not a command. Interactive (a real terminal, not quiet, not json) routes to this main menu. Non-interactive (no terminal, quiet, or json) is Type O CLI self-install, owned by the zero-arguments requirement. A named command such as `menu` or `status` is not this shape. |
| **CLI default interaction** | The numbered list of CLI verbs this product claims on a real terminal. An interactive zero-cli-verb, and `menu` / `main`, draw it. Off a terminal the same verb fails closed. It is the behavior, not the ink and not the integer grammar. |
| **CLI main menu hierarchy table** | The layered menu design: the single catalog of every numbered board. Each row records number, parent, short description, long description, what it runs, and who sees it. The tables in §2.1, §2.4–§2.7, and §2.6.1 are that catalog. The words in those tables are the English catalog. |
| **CLI main menu numbering** | The non-repeating number prefix. Each command number is unique in the whole tree. A child number starts with its parent’s digits. Language rows are the exception: front **7** reserves **70–89** (not more than 20 languages). **0** on a submenu goes back to the parent. **9** on the front board leaves. A hidden row keeps its number. Host, folder, and extra-setting pickers stay item indexes **1…N** plus **0**. |
| **Default CLI main menu style** | The default menu style. How every numbered layer is drawn: identity token on the header, then number, bold short name, italic light-gray long description. Off a terminal the same row is plain text. This term is the ink, not which rows exist. |
| **App-name-version-display** | The header identity token: bold program name, italic version, no space, written `**sshd-cli**(*VERSION*)`. It is not a path, not a `Next:` command line, and not the JSON `app` / `version` keys. |
| **Menu layer** | The one numbered list that owns the current `read`. The front board is one layer. Each submenu and each data picker is another. Exit or back leaves only that layer. |
| **Menu-hidden message** | The line that names why rows of this menu layer are omitted. Each distinct cause prints its own message before the numbered items of that layer. One cause that omits several rows on the same layer uses one message. The message is not a numbered row. A later pick of a hidden number is still invalid-choice retry. On this product the front **5** Termux-class sentence, the client Termux-class sentence, and the POSIX non-root server sentence are have. |
| **Front board** | The top menu layer: **1** client-side, **2** server-side, **5** sudoers, **6** self-management, **7** language, **9** Exit. Language children use the block **70–89**. Front **8** is not a row. **0** is not on this layer. |
| **Menu language** | The saved choice for the words on these numbered boards and for human help and about. `en` is English and the default. `zh-Hans` is Simplified Chinese. `zh-Hant` is Traditional Chinese. `es` is Spanish. `ar` is Arabic. `fr` is French. `pt` is Portuguese. `ru` is Russian. `de` is German. `ja` is Japanese. `ko` is Korean. `nl` is Dutch. `el` is Greek. The numbers stay the same. Leaf shorts stay the English verb. Category shorts, long text, Back, Exit, the choose-prompt, the unknown-choice warn, and the menu-hidden sentences follow that choice. |
| **Well-known menu** | The shared numbers this product keeps: front **1 / 2 / 6 / 9** and self-management **61–67**. Front **5** sudoers (**51–55**), front **7** (language block **70–89**), and the domain children are this product’s rows on the hierarchy table, not part of the shared card. |
| **Well-known CLI verb** | A shared command word (`install`, `version`, `about`, `version-check`, `self-update`, `self-uninstall`, `self-install`, `menu`, `main`, `help`). Each is either an operational verb or a test-purpose verb. Domain words such as `dns` and `start` are live commands and are not this shared card. |
| **CLI routed-verb** | A command token the dispatcher accepts and hands to a handler. Inventory is the dispatcher, not the help text. |
| **CLI routed-verb table** | The kept report of those live tokens. A leaf row’s short description is the token. The long description is the one-line explain. Category rows are on the hierarchy table and are not rows of this report. |
| **CLI gap name** | A command word registered law already names while the dispatcher still rejects it. It fails closed as unknown. It is not a numbered row, and help does not list it. |
| **Operational verb** | A live command that does product work (install, status, dns, ssh, and the other leaves). It is not a test-purpose verb. |
| **Test-purpose verb** | A live command whose only job is a unit test against a local test folder (`rc-test`). It stays off every numbered list. |
| **Invalid-choice retry** | A pick that is not listed and is not this layer’s leave or back token. The program warns, names the token, reprints this layer, and reads again. It does not exit and does not treat the pick as an unknown command-line verb. |
| **Command-finished front board** | The default back to the top menu after a command runs. After a valid leaf finishes, the front board is shown again. **0** Back still returns to the parent layer. A bad pick still reprints the current layer. |
| **Three-layer privilege** | Who may run a verb: Type 0 normal user, Type 1 admin, or Type 2 dedicated system user. A menu layer is a numbered list, not one of these privilege types. |
| **Approval question** | A one-shot yes or no after a valid pick. Yes accepts. No rejects. Empty means no. It is not a numbered menu layer. |
| **Do not capture `read`** | The rule that a `read`, and any helper whose body contains `read`, runs in the current shell. `$()` and backticks are forbidden around it: the typed line stays in the child shell. A prompt on stderr, or `read` from `/dev/tty`, does not allow that capture. Pure-data helpers that never `read` may still use `$()`. On this tree the board choice is `read` into the choice variable. A yes/no uses `prompt_yes_no` by its exit status. |
| **Command-substitution subshell** | `$()` or backticks start a child shell. A `read` in that child does not set the parent’s choice variable. That is why the menu choice stays in the current shell. |
| **Prompt-ask-value** | The portable channel for a value prompt: the text lands in `PROMPT_ASK_VALUE` in the current shell. This product’s `prompt_ask` still prints the answer on stdout, and these menu boards do not call it. The board choice stays a current-shell `read`. The ban on `$()` is the same either way. |
| **Interactive vs noninteractive** | Interactive means a person at a terminal, and not quiet, and not json. Non-interactive means a pipe, a script, quiet, or json, with nobody to answer. The numbered tree is drawn only for an interactive zero-cli-verb (and for `menu` / `main` on a terminal). Non-interactive mode must not wait on a board. |
| **Type O empty argv** | The non-interactive zero-cli-verb path: no command token means place/ensure this CLI. Switches with no command are still that path when the run is non-interactive (`--quiet`, `--json`, or no terminal). The letter **O** is this path. The digit **0** is privilege Type 0. An interactive zero-cli-verb is the main menu, not this path. |
| **Operator-readable error** | A line a person at the prompt can act on: what happened, in plain words, and what to do next. The invalid-choice warn is this kind of line. It names the token and tells the operator to choose a listed number or command name. |

**Last Updated**: 2026-10-14 (1.18.0 front **5** sudoers **51–55**, front **6** self-management **61–67**, front **7** language block **70–89** assigned **71–83**. Front **8** is not a row. 1.17.0 front **7** prints `sudoers not available for termux` / `gitbash` / `windows-cmd`. 1.16.0 language rows **51–63**, **50** and **64–69** unprinted. 1.15.0 front **5** language reserves **50–69** for at most 20 languages, assigned **51–58**. 1.14.0 samples and translation tables live on the language requirement. 1.13.0 language **67** / **68**)  
**Owner**: sshd-cli project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
