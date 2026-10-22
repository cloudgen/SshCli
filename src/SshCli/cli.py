#!/usr/bin/env python
# =============================================================================
# SshCli CLI — text menu and typed verbs.
# Law keys: requirement-python-cli-interface, requirement-python-cli-logging,
#           requirement-python-tui, requirement-python-oop,
#           requirement-python-about, requirement-domain-sshd,
#           requirement-python-error-handling, requirement-python-coding-style,
#           requirement-runtime-prerequisites
# Video join, FFmpeg, and file listing are not part of this program.
# CIAO-Lite: Caution • Intentional • Anti-fragile • Over-protect
# def main writes ChronicleLogger(...). This module does not construct it
# at import time and does not re-export it.
# =============================================================================
from __future__ import print_function, unicode_literals

import argparse
import os
import sys

from .about_page import AboutPage
from .check_system import CheckSystem
from .self_management import SelfManage
from .tui import Tui


class Cli:
    """Parser, dispatch, verbs, and the tty gate. One class in this file.

    Identity, verb lists, and suffix sets are attributes of this class.
    Collaborators arrive through the constructor. def main stays beside this class.
    """

    from . import __version__ as VERSION

    APP_NAME = "SshCli"
    CONSOLE_NAME = "sshd-cli"
    PRODUCT_VERBS = (
        "help",
        "version",
        "about",
        "hello",
        "self-install",
        "version-check",
        "self-update",
        "self-uninstall",
        "status",
        "start",
        "stop",
        "restart",
        "port",
        "config",
        "host-keys",
        "auth-keys",
        "dns",
        "ssh",
        "download",
        "upload",
        "fix-config",
        "backup-config",
        "sync-config",
        "sync-from-remote",
        "wake-lock",
        "wake-unlock",
        "install",
        "generate-sudoer-request",
        "submit-sudoer-request",
        "print-sudoers",
        "print-sudoers-install-script",
        "remove-project-sudoers",
        "rc-test",
        "menu",
        "main",
    )
    LIFECYCLE_VERBS = (
        "version",
        "self-install",
        "version-check",
        "self-update",
        "self-uninstall",
    )
    AUTHOR_NAME = "Wilgat Wong"
    AUTHOR_EMAIL = "wilgat.wong@gmail.com"
    HOMEPAGE = "https://github.com/cloudgen/SshCli"
    LAST_UPDATE = "2026-10-22"
    DOWNLOAD_URL = ""
    BASIC_USAGE = "sshd-cli status"

    def __init__(self, logger=None):
        self.logger = logger
        if logger is not None:
            logger.log_message("instantiated", component="Cli")
        self.app_name = Cli.APP_NAME
        self.version = Cli.VERSION
        self.about = AboutPage(
            CheckSystem(
                logger=logger,
                app_name=Cli.APP_NAME,
                version=Cli.VERSION,
                console_name=Cli.CONSOLE_NAME,
            ),
            Cli.APP_NAME,
            Cli.VERSION,
            Cli.AUTHOR_NAME,
            Cli.LAST_UPDATE,
            Cli.HOMEPAGE,
            Cli.DOWNLOAD_URL,
            Cli.BASIC_USAGE,
            Cli.CONSOLE_NAME,
            logger=logger,
        )
        self.self_manage = SelfManage(Cli.APP_NAME, Cli.VERSION, logger=logger)
        self.tui = Tui(self, logger=logger)
        self.domain = None

    @staticmethod
    def stdout_is_tty():
        """General Purpose: Whether the text screen can be drawn on this stdout."""
        try:
            return sys.stdout.isatty()
        except Exception:
            return False

    @staticmethod
    def opens_text_screen(argv):
        """
        General Purpose: Whether this argv draws the text screen.

        The real parser has not run yet. This walk only decides is_quiet.
        Help, version, hello, and the pip verbs do not draw the screen.
        Empty argv and about do, when stdout is a terminal.
        hello prints the welcome line and does not draw the screen.
        """
        if argv is None:
            argv = sys.argv[1:]
        argv = list(argv)
        if "--help" in argv or "-h" in argv or "--version" in argv:
            return False
        if not Cli.stdout_is_tty():
            return False
        verb = None
        saw_force = False
        saw_json = False
        saw_quiet = False
        skip_value = False
        value_flags = {
            "--input-file",
            "--output-file",
            "--root",
            "--file",
            "--case",
            "--purpose",
        }
        for token in argv:
            if skip_value:
                skip_value = False
                continue
            if token in ("--json",):
                saw_json = True
                continue
            if token in ("--quiet",):
                saw_quiet = True
                continue
            if token in ("--debug", "--force"):
                if token == "--force":
                    saw_force = True
                continue
            if token in value_flags:
                skip_value = True
                continue
            if token.startswith("-"):
                return False
            if verb is None:
                verb = token
                continue
            return False
        if saw_json or saw_quiet:
            return False
        if saw_force and verb != "self-uninstall":
            return False
        if verb == "about":
            return True
        if verb in (None, "menu", "main"):
            return True
        return False

    def report_error(self, message, nxt):
        """User-visible failure plus the same fact on the logger when one exists."""
        if self.logger is not None:
            self.logger.log_message(
                "{0} Next: {1}".format(message, nxt),
                level="ERROR",
                component="main",
            )
        print("ERROR: {0}".format(message), file=sys.stderr)
        print("   Next: {0}".format(nxt), file=sys.stderr)
        return 1

    def build_parser(self):
        """
        General Purpose: One optional product verb. No file-operand flags.
        help is also --help. --force belongs only to self-uninstall.
        """
        parser = argparse.ArgumentParser(
            prog=Cli.CONSOLE_NAME,
            formatter_class=argparse.RawDescriptionHelpFormatter,
            description=(
                "{0} — OpenSSH sshd and this login's SSH client, on a text menu.\n"
                "With no arguments on a terminal, opens the text menu.\n"
                "With no arguments and no terminal, prints this help and stops.\n"
                "Menu rows: 1 client-side, 2 server-side, 3 system-log,\n"
                "4 language, 5 sudoers (POSIX Linux), 8 self-management, 9 Exit.\n"
                "system-log, language, self-management, and Exit keep the\n"
                "HelloTui numbers. hello still prints a welcome line and does\n"
                "not draw the menu.\n"
                "version-check runs: python -m pip index versions {0}\n"
                "self-update runs: python -m pip install --upgrade {0}\n"
                "self-install runs: python -m pip install {0}\n"
                "self-uninstall runs: python -m pip uninstall -y {0}\n"
                "and needs --force. Empty arguments do not install or update.\n"
                "Domain verbs include status, start, stop, restart, dns, ssh,\n"
                "download, upload, fix-config, backup-config, and the sudoers\n"
                "draft verbs. --json prints one JSON object and no human line."
                .format(Cli.APP_NAME)
            ),
        )
        parser.add_argument(
            "verb",
            nargs="?",
            default=None,
            metavar="verb",
            help=(
                "Product verb: help, version, about, hello, "
                "self-install, version-check, self-update, or self-uninstall"
            ),
        )
        parser.add_argument(
            "--version",
            action="version",
            version="{0} {1}".format(Cli.APP_NAME, Cli.VERSION),
        )
        parser.add_argument(
            "--force",
            action="store_true",
            help="Confirm self-uninstall. Required on the command line.",
        )
        parser.add_argument("--json", action="store_true", help="Print one JSON object. No human lines.")
        parser.add_argument("--quiet", action="store_true", help="Hide human info lines. Errors still print.")
        parser.add_argument("--debug", action="store_true", help="Debug log lines. A bare --debug on a terminal still opens the menu.")
        parser.add_argument("--input-file", default="", help="fix-config input path.")
        parser.add_argument("--output-file", default="", help="fix-config output path.")
        parser.add_argument("--root", default="", help="rc-test root directory.")
        parser.add_argument("--file", default="", help="rc-test file: bashrc, zshrc, or profile.")
        parser.add_argument("--case", default="", help="rc-test case: create, modify, or noop.")
        parser.add_argument(
            "--purpose",
            nargs="?",
            const="",
            default=None,
            help="Purpose text. An empty purpose stops the program.",
        )
        parser.add_argument("operands", nargs="*", help="Operands for the domain verb.")
        return parser

    def _bind_domain(self, args):
        """Build the domain service for this argv. The silent fix-config pass runs here."""
        from .domain.output import Output
        from .domain.service import Domain

        output = Output(
            json_mode=bool(getattr(args, "json", False)),
            quiet=bool(getattr(args, "quiet", False)),
            debug=bool(getattr(args, "debug", False)),
        )
        self.domain = Domain(
            output,
            home=os.environ.get("HOME", ""),
            app_name=Cli.CONSOLE_NAME,
            version=Cli.VERSION,
        )
        self.domain.auto_fix()

    def _domain_error(self, message):
        print("[ERROR] {0}".format(message), file=sys.stderr)
        return 1

    def _page(self, text):
        print(text)
        return 0

    def _verb_hello(self):
        """Welcome on the terminal. Does not draw the menu."""
        print(self.tui.hello_text())
        return 0

    def _unknown_verb(self, token):
        names = ", ".join(Cli.PRODUCT_VERBS)
        return self.report_error(
            "Unknown verb '{0}'.".format(token),
            "{0} help — verbs: {1}".format(Cli.CONSOLE_NAME, names),
        )

    def _dispatch(self, args):
        """One product verb, the front board, or a fail-closed stop."""
        verb = args.verb
        if args.force and verb != "self-uninstall":
            return self.report_error(
                "--force is only for self-uninstall.",
                "{0} self-uninstall --force".format(Cli.CONSOLE_NAME),
            )
        if getattr(args, "purpose", None) == "":
            return self._domain_error(
                "--purpose needs text. Next: {0} --purpose \"why this run\"".format(Cli.CONSOLE_NAME)
            )
        self._bind_domain(args)
        if verb == "about":
            result = self.tui.about_on_screen()
            if isinstance(result, int):
                return result
            return self._page(result)
        if verb == "hello":
            return self._verb_hello()
        if verb == "version":
            return self._page(self.self_manage.local_version())
        if verb == "self-uninstall":
            if not args.force:
                return self.report_error(
                    "self-uninstall removes this package with pip.",
                    "{0} self-uninstall --force".format(Cli.CONSOLE_NAME),
                )
            return self.self_manage.emit(verb)
        if verb in ("version-check", "self-update", "self-install"):
            return self.self_manage.emit(verb)
        if verb in ("menu", "main"):
            if not self.stdout_is_tty() or args.json or args.quiet:
                return self._domain_error(
                    "menu needs a terminal. Run a named command instead, for example: {0} status".format(
                        Cli.CONSOLE_NAME
                    )
                )
            action = self.tui.open_text_menu()
            if action == "missing":
                return 1
            return 0
        if verb is not None:
            from .domain.service import DOMAIN_VERBS

            if verb in DOMAIN_VERBS:
                operands = list(args.operands)
                if verb == "rc-test":
                    if args.root:
                        operands.extend(["--root", args.root])
                    if args.file:
                        operands.extend(["--file", args.file])
                    if args.case:
                        operands.extend(["--case", args.case])
                return self.domain.run(
                    verb,
                    operands,
                    input_file=args.input_file,
                    output_file=args.output_file,
                )
            return self._unknown_verb(verb)
        if args.json or args.quiet or not self.stdout_is_tty():
            self.build_parser().print_help()
            return 0
        action = self.tui.open_text_menu()
        if action == "missing":
            return 1
        return 0

    def run(self, argv=None):
        """One job. def main already wrote ChronicleLogger(...) and passed it in."""
        if argv is None:
            argv = sys.argv[1:]
        argv = list(argv)
        parser = self.build_parser()
        try:
            args = parser.parse_args(argv)
        except SystemExit as exc:
            code = exc.code
            if code is None or code == 0:
                return 0
            return int(code)
        if args.verb == "help":
            parser.print_help()
            return 0
        return self._dispatch(args)


def main(argv=None, basedir="", logdir=""):
    """This function instantiates ChronicleLogger. The statement below is the construct."""
    if argv is None:
        argv = sys.argv[1:]
    argv = list(argv)
    try:
        from ChronicleLogger import ChronicleLogger
    except ImportError:
        sys.stderr.write(
            'ChronicleLogger is required. Next step: python -m pip install "ChronicleLogger>=1.3.1"\n'
        )
        return 1

    from SshCli import __version__

    screen = Cli.opens_text_screen(argv)
    logger = ChronicleLogger(
        logname=Cli.APP_NAME,
        is_quiet=screen,
        basedir=basedir,
        logdir=logdir,
    )
    appname = logger.logName()
    resolved_base = logger.baseDir()
    logger.logDir()

    if logger.isDebug():
        logger.log_message(
            "{0} v{1} ({2})".format(appname, __version__, __file__),
            component="main",
        )
        logger.log_message(
            "Using {0}".format(ChronicleLogger.class_version()),
            component="main",
        )
        logger.log_message(
            "Base {0}".format(resolved_base),
            level="DEBUG",
            component="main",
        )
        logger.log_message("debug mode", component="main")

    app = Cli(logger)
    return app.run(argv)


if __name__ == "__main__":
    sys.exit(main())
