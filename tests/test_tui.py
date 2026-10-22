# TP-TUI-09 — path label. Primary law: requirement-python-tui.
# English Path is the default. LANG does not select Traditional Chinese.
# The folder path and the clock are not translated.
# TP-TUI-10 — wide columns. Wide and Fullwidth count as two. Ambiguous stays one.
import os
import tempfile
import unittest

from SshCli.menu_painter import MenuPainter
from SshCli.tui import Tui


class TestPathLabel(unittest.TestCase):
    """TP-TUI-09."""

    def test_tp_tui_09_english_label_until_language_requirement(self):
        """TP-TUI-09: missing language file stays Path. LANG does not select 路徑."""
        self.assertEqual(MenuPainter.PATH_LABEL_EN, "Path")
        self.assertEqual(MenuPainter.PATH_LABEL_ZH_HANT, "路徑")
        folder = tempfile.mkdtemp(prefix="vjclips_", dir="/tmp")
        home = tempfile.mkdtemp(prefix="vjhome_", dir="/tmp")
        previous = os.getcwd()
        saved = {
            name: os.environ.get(name)
            for name in (
                "LANG", "LANGUAGE", "LC_ALL", "LC_MESSAGES", "HOME", "VIDEOJOIN_LANG",
            )
        }
        os.environ["LANG"] = "zh_TW.UTF-8"
        os.environ["LANGUAGE"] = "zh_TW:zh"
        os.environ["LC_ALL"] = "zh_TW.UTF-8"
        os.environ["LC_MESSAGES"] = "zh_TW.UTF-8"
        os.environ["HOME"] = home
        os.environ.pop("VIDEOJOIN_LANG", None)
        os.chdir(folder)
        try:
            painter = MenuPainter(home=home)
            self.assertEqual(painter.path_label(), "Path")
            current = os.path.abspath(folder)
            clock = "14:05:09"
            original = painter.clock_text
            painter.clock_text = lambda: clock
            try:
                logical = "Path: " + current + "  " + clock
                self.assertEqual(painter.path_line(), logical)
                self.assertFalse(logical.startswith("路徑"))
                self.assertNotIn("路徑", logical)
                self.assertIn(current, logical)
                self.assertTrue(logical.endswith(clock))
                narrow = len("Path: ") + 4
                shortened = painter.path_line(narrow)
                self.assertEqual(shortened, "Path: " + current[-4:])
                self.assertNotIn(clock, shortened)
                self.assertFalse(shortened.startswith("路徑"))
            finally:
                painter.clock_text = original

            session = Tui()
            session.painter = MenuPainter(home=home)
            session.painter.clock_text = lambda: clock
            try:
                for line in (
                    session.front_lines()[0],
                    session.self_lines()[0],
                    session.log_lines()[0],
                    session.language_lines()[0],
                ):
                    self.assertEqual(line, "Path: " + current + "  " + clock)
                    self.assertFalse(line.startswith("路徑"))
                    self.assertNotIn("SshCli", line.split("  ")[0])
            finally:
                session.painter.clock_text = original
        finally:
            os.chdir(previous)
            for name, value in saved.items():
                if value is None:
                    os.environ.pop(name, None)
                else:
                    os.environ[name] = value


class TestWideColumns(unittest.TestCase):
    """TP-TUI-10. Wide and Fullwidth count as two columns. Ambiguous stays one."""

    def test_tp_tui_10_wide_columns(self):
        """TP-TUI-10: the colon starts after the display width of a wide short."""
        import unicodedata

        from SshCli.cli import Cli
        from SshCli.menu_model import MenuModel
        from SshCli.menu_painter import MenuPainter

        class ColumnScreen:
            """Records each addstr with its column."""

            def __init__(self, size=(24, 80)):
                self.size = size
                self.calls = []

            def getmaxyx(self):
                return self.size

            def erase(self):
                self.calls = []

            def addstr(self, y, x, text, _attr=0):
                self.calls.append((y, x, text))

            def refresh(self):
                return None

            def curs_set(self, _visibility):
                return None

        def occupy(calls):
            rows = {}
            for y, x, text in calls:
                row = rows.setdefault(y, {})
                col = x
                for char in text:
                    wide = unicodedata.east_asian_width(char) in ("W", "F")
                    width = 2 if wide else 1
                    for offset in range(width):
                        pos = col + offset
                        self.assertNotIn(
                            pos,
                            row,
                            "row {0} column {1} already holds {2!r}".format(
                                y, pos, row.get(pos)
                            ),
                        )
                        row[pos] = char if offset == 0 else ""
                    col += width

        def gap_before(line, clock):
            head = line[: -len(clock)]
            return len(head) - len(head.rstrip(" "))

        home = tempfile.mkdtemp(prefix="vjwide_", dir="/tmp")
        folder = tempfile.mkdtemp(prefix="vjclips_", dir="/tmp")
        previous = os.getcwd()
        saved = {
            name: os.environ.get(name)
            for name in ("HOME", "VIDEOJOIN_LANG", "SSHCLI_LANG", "LANG", "LC_ALL", "SSHD_CLI_HOST")
        }
        os.environ["HOME"] = home
        os.environ.pop("VIDEOJOIN_LANG", None)
        os.environ.pop("SSHCLI_LANG", None)
        os.environ["SSHD_CLI_HOST"] = "posix"
        os.chdir(folder)
        clock = "14:05:09"
        try:
            self.assertEqual(MenuPainter.display_width("╭─╮"), 3)
            self.assertEqual(MenuPainter.display_width("█"), 1)
            self.assertEqual(MenuPainter.display_width("路径"), MenuPainter.display_width("Path"))
            self.assertEqual(MenuPainter.display_width("路徑"), 4)
            self.assertEqual(MenuPainter.display_width("パス"), 4)
            self.assertEqual(MenuPainter.display_width("경로"), 4)

            painter = MenuPainter(home=home)
            painter.clock_text = lambda: clock
            wide = 79
            english = painter.path_line(wide)
            self.assertEqual(MenuPainter.display_width(english), wide)
            self.assertTrue(english.endswith(clock))
            english_gap = gap_before(english, clock)
            for label, first in (
                ("路径", "路"),
                ("路徑", "路"),
                ("パス", "パ"),
                ("경로", "경"),
            ):
                os.environ["VIDEOJOIN_LANG"] = {
                    "路径": "zh-Hans",
                    "路徑": "zh-Hant",
                    "パス": "ja",
                    "경로": "ko",
                }[label]
                labeled = MenuPainter(home=home)
                labeled.clock_text = lambda: clock
                self.assertEqual(labeled.path_label(), label)
                line = labeled.path_line(wide)
                self.assertTrue(line.startswith(label + ": "), line)
                self.assertTrue(line.endswith(clock), line)
                self.assertEqual(MenuPainter.display_width(line), wide)
                self.assertEqual(gap_before(line, clock), english_gap)
                self.assertEqual(labeled.path_line(1), "")
                self.assertEqual(labeled.path_line(2), first)
                self.assertEqual(labeled.path_line(3), first)
                self.assertEqual(labeled.path_line(5), label + ":")

            expected = {
                "zh-Hans": [
                    "1. client-side: this login OpenSSH client (~/.ssh/config, ssh, folders)",
                    "2. server-side: this host OpenSSH sshd (listen, keys, port)",
                    "3. 系统日志   : 查看、清空，以及日志文件夹",
                    "4. 语言       : 此菜单的显示语言",
                    "5. sudoers    : grant and drafts for passwordless sudo",
                    "8. 自我管理   : 版本、关于，以及 pip 生命周期",
                    "9. 离开       : 离开",
                ],
                "zh-Hant": [
                    "1. client-side: this login OpenSSH client (~/.ssh/config, ssh, folders)",
                    "2. server-side: this host OpenSSH sshd (listen, keys, port)",
                    "3. 系統日誌   : 查看、清空，以及日誌資料夾",
                    "4. 語言       : 這個選單的顯示語言",
                    "5. sudoers    : grant and drafts for passwordless sudo",
                    "8. 自我管理   : 版本、關於，以及 pip 生命週期",
                    "9. 離開       : 離開",
                ],
                "ko": [
                    "1. client-side: this login OpenSSH client (~/.ssh/config, ssh, folders)",
                    "2. server-side: this host OpenSSH sshd (listen, keys, port)",
                    "3. 시스템 로그: 보기, 비우기, 로그 폴더",
                    "4. 언어       : 이 메뉴의 표시 언어",
                    "5. sudoers    : grant and drafts for passwordless sudo",
                    "8. 자기관리   : 버전, 정보, pip 수명 주기",
                    "9. 종료       : 종료",
                ],
                "ja": [
                    "1. client-side : this login OpenSSH client (~/.ssh/config, ssh, folders)",
                    "2. server-side : this host OpenSSH sshd (listen, keys, port)",
                    "3. システムログ: 表示、消去、ログフォルダ",
                    "4. 言語        : このメニューの表示言語",
                    "5. sudoers     : grant and drafts for passwordless sudo",
                    "8. 自己管理    : バージョン、概要、pip のライフサイクル",
                    "9. 終了        : 終了",
                ],
            }
            shorts = {
                "zh-Hans": ("语言", "系统日志", "自我管理", "离开"),
                "zh-Hant": ("語言", "系統日誌", "自我管理", "離開"),
                "ko": ("언어", "시스템 로그", "자기관리", "종료"),
                "ja": ("言語", "システムログ", "自己管理", "終了"),
            }
            for code, words in shorts.items():
                os.environ["VIDEOJOIN_LANG"] = code
                board_painter = MenuPainter(home=home)
                board_painter.clock_text = lambda: clock
                self.assertEqual(board_painter.language.code(), code)
                board = board_painter.display_rows("front")
                self.assertEqual(board_painter.format_rows(board), expected[code])
                model = MenuModel(painter=board_painter)
                screen = ColumnScreen()
                board_painter.paint(screen, model, Cli.APP_NAME, Cli.VERSION)
                occupy(screen.calls)
                placeable = screen.getmaxyx()[1] - 1
                path_text = screen.calls[0][2]
                self.assertEqual(screen.calls[0][0], 0)
                self.assertEqual(screen.calls[0][1], 0)
                self.assertTrue(path_text.startswith(board_painter.path_label() + ": "), path_text)
                self.assertTrue(path_text.endswith(clock), path_text)
                self.assertEqual(MenuPainter.display_width(path_text), placeable)
                framed = [text for _y, _x, text in screen.calls if text[:1] == "╭"]
                self.assertEqual(len(framed), 1)
                self.assertEqual(MenuPainter.display_width(framed[0]), placeable)
                for number_field, short, verb_pad, _explain in board_painter.row_parts(board):
                    if short not in words:
                        continue
                    verb_x = MenuPainter.display_width(number_field)
                    matches = [
                        item for item in screen.calls if item[2] == short and item[1] == verb_x
                    ]
                    self.assertEqual(len(matches), 1, short)
                    y, x, text = matches[0]
                    self.assertEqual(text, short)
                    colon_x = x + MenuPainter.display_width(short)
                    colon = [item for item in screen.calls if item[0] == y and item[1] == colon_x]
                    self.assertEqual(colon, [(y, colon_x, "{0}: ".format(verb_pad))], short)
                    self.assertNotEqual(colon_x, x + len(short), short)

            os.environ.pop("VIDEOJOIN_LANG", None)
            english_painter = MenuPainter(home=home)
            english_painter.clock_text = lambda: clock
            self.assertEqual(english_painter.language.code(), "en")
            lang_rows = english_painter.display_rows("lang")
            endonyms = ("简体中文", "繁體中文", "日本語", "한국어")
            joined = "\n".join(english_painter.format_rows(lang_rows))
            for endonym in endonyms:
                self.assertIn(endonym, joined)
            model = MenuModel(painter=english_painter)
            model.layer = "lang"
            screen = ColumnScreen(size=(40, 80))
            english_painter.paint(screen, model, Cli.APP_NAME, Cli.VERSION)
            occupy(screen.calls)
            for number_field, short, verb_pad, _explain in english_painter.row_parts(lang_rows):
                if short not in endonyms:
                    continue
                verb_x = MenuPainter.display_width(number_field)
                matches = [
                    item for item in screen.calls if item[2] == short and item[1] == verb_x
                ]
                self.assertEqual(len(matches), 1, short)
                y, x, text = matches[0]
                colon_x = x + MenuPainter.display_width(short)
                colon = [item for item in screen.calls if item[0] == y and item[1] == colon_x]
                self.assertEqual(colon, [(y, colon_x, "{0}: ".format(verb_pad))], short)
                self.assertNotEqual(colon_x, x + len(short), short)
        finally:
            os.chdir(previous)
            for name, value in saved.items():
                if value is None:
                    os.environ.pop(name, None)
                else:
                    os.environ[name] = value


if __name__ == "__main__":
    unittest.main()
