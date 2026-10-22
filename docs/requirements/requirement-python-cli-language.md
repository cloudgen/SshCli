**file**: docs/requirements/requirement-python-cli-language.md
**Status**: Active (Version 1.0.0)
**Area**: python
**Key**: `requirement-python-cli-language`
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

The menu language is front row 4. Thirteen codes are stored for the next run. The welcome line stays English.

### 1.1 Human-facing

**In one sentence:** Choose 4, then a language number. The next `sshd-cli` uses that language for the menu. The folder path itself is not translated.

## 2. Core Rules (Mandatory)

1. Codes and numbers: 41 English `en`, 42 Simplified Chinese `zh-Hans`, 43 Traditional Chinese `zh-Hant`, 44 Spanish `es`, 45 Arabic `ar`, 46 French `fr`, 47 Portuguese `pt`, 48 Russian `ru`, 49 German `de`, 50 Japanese `ja`, 51 Korean `ko`, 52 Dutch `nl`, 53 Greek `el`.
2. 40 and 54 through 59 are not printed and do not write the leaf.
3. The leaf is `~/.local/SshCli/language`. The file mode is 0600. The directory mode is 0700. The first line is the code.
4. `LANG` and `LC_ALL` do not select a code.
5. `SSHCLI_LANG` selects a code when it is one of the thirteen and does not write the leaf. `VIDEOJOIN_LANG` does the same when `SSHCLI_LANG` is unset. `SSHCLI_LANG` wins when both are set.
6. A bad first line stays English and is not rewritten.
7. A failed write keeps the previous code and warns in that language.
8. Leaf shorts on system-log, language, self-management, and Exit follow the language. Client and server shorts stay the English tokens until a catalog row exists. Endonyms on the language board are not translated into another language.
9. `language` is not in `PRODUCT_VERBS`.

## 3. Acceptance

- `tests/test_language.py` (TP-LANG-01), including the Traditional Chinese save, the force environment, and the failed write.
