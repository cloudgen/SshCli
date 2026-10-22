# hello — terminal welcome and menu row 1.
# The typed verb prints the welcome line and does not draw the menu.
# Menu row 1 shows that same line on the result page.
import io
import os
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout

from SshCli.cli import Cli
from SshCli.menu_model import MenuModel
from SshCli.menu_painter import MenuPainter
from SshCli.menu_session import MenuSession
from SshCli.tui import Tui


class TestHello(unittest.TestCase):
    """Typed hello prints a welcome line. Menu row 1 shows it."""

    def test_cli_hello_prints_welcome_and_skips_the_menu(self):
        app = Cli()
        self.assertIn("hello", Cli.PRODUCT_VERBS)
        self.assertNotIn("join", Cli.PRODUCT_VERBS)
        self.assertNotIn("list-videos", Cli.PRODUCT_VERBS)
        self.assertFalse(Cli.opens_text_screen(["hello"]))
        previous = Cli.stdout_is_tty
        Cli.stdout_is_tty = staticmethod(lambda: True)
        try:
            self.assertTrue(Cli.opens_text_screen([]))
            self.assertFalse(Cli.opens_text_screen(["hello"]))
            self.assertTrue(Cli.opens_text_screen(["about"]))
            self.assertFalse(Cli.opens_text_screen(["join"]))
            self.assertFalse(Cli.opens_text_screen(["list-videos"]))
        finally:
            Cli.stdout_is_tty = previous
        home = tempfile.mkdtemp(prefix="vjhello_cli_", dir="/tmp")
        saved_home = os.environ.get("HOME")
        os.environ["HOME"] = home
        buf = io.StringIO()
        try:
            with redirect_stdout(buf):
                code = app.run(["hello"])
        finally:
            if saved_home is None:
                os.environ.pop("HOME", None)
            else:
                os.environ["HOME"] = saved_home
        self.assertEqual(code, 0)
        welcome = "Welcome to {0} {1}.\n".format(Cli.APP_NAME, Cli.VERSION)
        self.assertEqual(buf.getvalue(), welcome)

    def test_removed_video_verbs_are_unknown(self):
        app = Cli()
        home = tempfile.mkdtemp(prefix="vjhello_unk_", dir="/tmp")
        saved_home = os.environ.get("HOME")
        os.environ["HOME"] = home
        try:
            for verb in ("join", "list-videos"):
                err = io.StringIO()
                with redirect_stderr(err):
                    code = app.run([verb])
                self.assertEqual(code, 1, verb)
                self.assertIn("Unknown verb '{0}'".format(verb), err.getvalue())
        finally:
            if saved_home is None:
                os.environ.pop("HOME", None)
            else:
                os.environ["HOME"] = saved_home
        help_buf = io.StringIO()
        with redirect_stdout(help_buf):
            self.assertEqual(app.run(["help"]), 0)
        text = help_buf.getvalue()
        self.assertNotIn("list-videos", text)
        self.assertNotIn("FFmpeg", text)
        self.assertNotIn("ffmpeg", text)
        self.assertNotIn("concatenate", text)

    def test_menu_row_1_shows_the_welcome_line(self):
        home = tempfile.mkdtemp(prefix="vjhello_", dir="/tmp")
        saved = os.environ.get("VIDEOJOIN_LANG")
        os.environ.pop("VIDEOJOIN_LANG", None)
        painter = MenuPainter(home=home)
        try:
            self.assertEqual(painter.language.code(), "en")
            rows = painter.display_rows("front")
        finally:
            if saved is None:
                os.environ.pop("VIDEOJOIN_LANG", None)
            else:
                os.environ["VIDEOJOIN_LANG"] = saved
        self.assertEqual(rows[0][0], 1)
        self.assertEqual(rows[0][3], "client-side")
        self.assertNotIn("hello", [row[3] for row in rows])
        tui = Tui()
        session = MenuSession(
            Cli.APP_NAME,
            Cli.VERSION,
            on_version=lambda: "",
            on_about=lambda: "",
            on_kind=lambda kind: tui.hello_text() if kind == "hello" else None,
            painter=painter,
        )
        session.model = MenuModel(painter=painter)
        self.assertEqual(session.take_action("hello"), "stay")
        self.assertEqual(session.model.phase, "result")
        welcome = "Welcome to {0} {1}.".format(Cli.APP_NAME, Cli.VERSION)
        self.assertEqual(session.model.result_text, welcome)
        self.assertEqual(tui.hello_text(), welcome)


if __name__ == "__main__":
    unittest.main()
