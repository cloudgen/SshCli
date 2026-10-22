# Domain features of the Python sshd-cli menu.
# Host names and addresses in this file are minted. They are not this login.
import io
import json
import os
import stat
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout

from SshCli.cli import Cli
from SshCli.domain.dns import Dns, algo_commented, parse_config
from SshCli.domain.fixconfig import render
from SshCli.domain.host import Host
from SshCli.domain.output import Output
from SshCli.domain.service import Domain
from SshCli.domain.transfer import text_is_msys
from SshCli.menu_model import MenuModel
from SshCli.menu_painter import MenuPainter
from SshCli.menu_session import MenuSession


class Env:
    """Set process environment for one test and put the old values back."""

    def __init__(self, **values):
        self.values = values
        self.saved = {}

    def __enter__(self):
        for name, value in self.values.items():
            self.saved[name] = os.environ.get(name)
            if value is None:
                os.environ.pop(name, None)
            else:
                os.environ[name] = value
        return self

    def __exit__(self, *_exc):
        for name, value in self.saved.items():
            if value is None:
                os.environ.pop(name, None)
            else:
                os.environ[name] = value
        return False


def _domain(home, json_mode=False):
    return Domain(Output(json_mode=json_mode), home=home, app_name="sshd-cli", version="2.0.0")


class TestDomainMenu(unittest.TestCase):
    """Menu numbers, hide sentences, and the boards HelloTui still owns."""

    def _painter(self, home):
        return MenuPainter(home=home)

    def test_posix_root_shows_sudoers_backup_and_daemon_rows(self):
        home = tempfile.mkdtemp(prefix="sshcli_menu_", dir="/tmp")
        with Env(SSHD_CLI_HOST="posix", SSHD_CLI_EUID="0", SSHD_CLI_OS_NAME="Debian"):
            painter = self._painter(home)
            front = [row[0] for row in painter.display_rows("front")]
            self.assertEqual(front, [1, 2, 3, 4, 5, 8, 9])
            client = [row[0] for row in painter.display_rows("client")]
            self.assertEqual(client, [11, 12, 13, 14, 15, 16, 0])
            server = [row[0] for row in painter.display_rows("server")]
            self.assertEqual(server, [21, 22, 23, 24, 0])
            session = MenuSession("SshCli", "2.0.0", on_version=lambda: "", on_about=lambda: "", painter=painter)
            session._refresh_info()
            self.assertEqual(session.model.info, "")

    def test_posix_non_root_hides_daemon_rows_with_the_shell_sentence(self):
        home = tempfile.mkdtemp(prefix="sshcli_menu_", dir="/tmp")
        with Env(SSHD_CLI_HOST="posix", SSHD_CLI_EUID="1000", SSHD_CLI_OS_NAME="Debian"):
            painter = self._painter(home)
            server = [row[0] for row in painter.display_rows("server")]
            self.assertEqual(server, [21, 0])
            self.assertIn(5, [row[0] for row in painter.display_rows("front")])
            session = MenuSession("SshCli", "2.0.0", on_version=lambda: "", on_about=lambda: "", painter=painter)
            session.model.layer = "server"
            session._refresh_info()
            self.assertEqual(
                session.model.info,
                "[INFO] start/stop/restart sshd features are not available for non-root in Debian",
            )

    def test_normal_user_class_hides_front_and_backup_rows(self):
        home = tempfile.mkdtemp(prefix="sshcli_menu_", dir="/tmp")
        for label in ("termux", "gitbash", "windows-cmd"):
            with Env(SSHD_CLI_HOST=label, SSHD_CLI_EUID="1000"):
                painter = self._painter(home)
                numbers = [row[0] for row in painter.display_rows("front")]
                self.assertNotIn(5, numbers, label)
                self.assertEqual(numbers, [1, 2, 3, 4, 8, 9], label)
                client = [row[3] for row in painter.display_rows("client")]
                self.assertIn("sync-from-remote", client, label)
                self.assertNotIn("backup-config", client, label)
                server = [row[0] for row in painter.display_rows("server")]
                self.assertEqual(server, [21, 22, 23, 24, 0], label)
                session = MenuSession("SshCli", "2.0.0", on_version=lambda: "", on_about=lambda: "", painter=painter)
                session._refresh_info()
                self.assertEqual(session.model.info, "[INFO] sudoers not available for {0}".format(label))
                session.model.layer = "client"
                session._refresh_info()
                self.assertEqual(
                    session.model.info,
                    "[INFO] backup-config and sync-config not available for {0}".format(label),
                )

    def test_hellotui_child_boards_keep_their_numbers(self):
        home = tempfile.mkdtemp(prefix="sshcli_menu_", dir="/tmp")
        with Env(SSHD_CLI_HOST="posix", VIDEOJOIN_LANG=None, SSHCLI_LANG=None):
            painter = self._painter(home)
            self.assertEqual([row[0] for row in painter.display_rows("self")], [82, 83, 84, 85, 86, 87, 0])
            self.assertEqual([row[0] for row in painter.display_rows("log")], [31, 32, 33, 0])
            lang = [row[0] for row in painter.display_rows("lang")]
            self.assertEqual(lang[:13], list(range(41, 54)))
            self.assertEqual([row[0] for row in painter.display_rows("sudoers")], [51, 52, 53, 54, 55, 0])
            self.assertEqual([row[0] for row in painter.display_rows("dns")], [111, 112, 113, 114, 0])
            model = MenuModel(painter=painter)
            model.buffer = "99"
            model.cursor = 2
            model.focus = "input"
            model.apply_key(10)
            self.assertIn("not on this list", model.error)
            model.buffer = "1"
            model.cursor = 1
            self.assertIsNone(model.apply_key(10))
            self.assertEqual(model.layer, "client")


class TestFixAndDns(unittest.TestCase):
    def test_fix_config_comments_only_the_unsupported_active_keywords(self):
        text = "Host lab-a\n    HostName 203.0.113.10\n    GSSAPIAuthentication yes\n    # GSSAPIDelegateCredentials yes\n"
        alpine = render(text, "alpine")
        self.assertIn("    # GSSAPIAuthentication yes", alpine)
        self.assertIn("    # GSSAPIDelegateCredentials yes", alpine)
        self.assertEqual(alpine.count("# GSSAPIDelegateCredentials"), 1)
        self.assertIn("    HostName 203.0.113.10", alpine)
        self.assertTrue(alpine.endswith("\n"))
        termux = render(
            "Host lab-a\n    HostKeyAlgorithms +ssh-rsa\n    PubkeyAcceptedAlgorithms +ssh-rsa\n    GSSAPIAuthentication yes\n",
            "termux",
        )
        self.assertIn("# HostKeyAlgorithms +ssh-rsa", termux)
        self.assertIn("# PubkeyAcceptedAlgorithms +ssh-rsa", termux)
        self.assertIn("    GSSAPIAuthentication yes", termux)
        self.assertEqual(render(text, "posix"), text)

    def test_auto_fix_rewrites_only_when_the_text_changes(self):
        home = tempfile.mkdtemp(prefix="sshcli_fix_", dir="/tmp")
        folder = os.path.join(home, ".ssh")
        os.makedirs(folder, mode=0o700)
        path = os.path.join(folder, "config")
        with open(path, "w", encoding="utf-8") as handle:
            handle.write("Host lab-a\n    GSSAPIAuthentication yes\n")
        os.chmod(path, 0o600)
        with Env(SSHD_CLI_OS="alpine", SSHD_CLI_HOST="posix"):
            app = _domain(home)
            app.auto_fix()
        with open(path, "r", encoding="utf-8") as handle:
            rewritten = handle.read()
        self.assertIn("# GSSAPIAuthentication yes", rewritten)
        backup = path + ".fix-config.bak"
        self.assertTrue(os.path.isfile(backup))
        self.assertEqual(stat.S_IMODE(os.stat(backup).st_mode), 0o600)
        stamp = os.stat(path).st_mtime_ns
        with Env(SSHD_CLI_OS="alpine", SSHD_CLI_HOST="posix"):
            _domain(home).auto_fix()
        self.assertEqual(os.stat(path).st_mtime_ns, stamp)

    def test_dns_add_unset_delete_and_ssh_argv(self):
        home = tempfile.mkdtemp(prefix="sshcli_dns_", dir="/tmp")
        dns = Dns(Output(), home, app_name="sshd-cli")
        code = dns.run(["add", "dns", "lab-a", "ip", "203.0.113.10", "user", "alice", "termux", "yes", "old-openssh", "yes"])
        self.assertEqual(code, 0)
        self.assertEqual(stat.S_IMODE(os.stat(dns.path()).st_mode), 0o600)
        listed = dns.list_text()
        self.assertIn("lab-a", listed)
        self.assertIn("termux=yes", listed)
        self.assertIn("old-openssh=yes", listed)
        self.assertEqual(dns.run(["unset", "lab-a", "dns"]), 1)
        self.assertEqual(dns.run(["unset", "lab-a", "ip"]), 1)
        self.assertEqual(dns.run(["unset", "lab-a", "user"]), 0)
        self.assertEqual(dns.lookup("lab-a")["user"], "")
        self.assertEqual(dns.lookup("lab-a")["ip"], "203.0.113.10")
        with open(dns.path(), "r", encoding="utf-8") as handle:
            text = handle.read()
        text = text.replace("HostKeyAlgorithms +ssh-rsa,ssh-dss", "# HostKeyAlgorithms +ssh-rsa,ssh-dss")
        with open(dns.path(), "w", encoding="utf-8") as handle:
            handle.write(text)
        self.assertTrue(algo_commented(text, "lab-a"))
        argv = dns.ssh_argv(dns.lookup("1"), "", "/usr/bin/ssh", batch=True)
        self.assertIn("HostKeyAlgorithms=+ssh-rsa", argv)
        self.assertNotIn("GSSAPIAuthentication", " ".join(argv))
        records = parse_config("Host * skip-me\n    HostName 203.0.113.20\nHost lab-b other\n    HostName 203.0.113.21\n")
        self.assertEqual([item["dns"] for item in records], ["skip-me", "lab-b", "other"])
        self.assertNotIn("*", [item["dns"] for item in records])
        self.assertEqual(dns.run(["delete", "lab-a"]), 0)
        self.assertIsNone(dns.lookup("lab-a"))


class TestTransferSudoersServer(unittest.TestCase):
    def test_transfer_plans_file_or_pipe_and_does_not_treat_windows_nt_as_msys(self):
        self.assertFalse(text_is_msys("__SSHD_CLI_UNAME__Linux\n__SSHD_CLI_OSTYPE__linux-gnu\nOS=Windows_NT\n"))
        self.assertTrue(text_is_msys("__SSHD_CLI_UNAME__MINGW64_NT\n__SSHD_CLI_OSTYPE__msys\n"))
        self.assertFalse(text_is_msys(""))
        home = tempfile.mkdtemp(prefix="sshcli_xfer_", dir="/tmp")
        with Env(SSHD_CLI_HOST="posix", SSHD_CLI_SSH="/bin/true", SSHD_CLI_READER="msys"):
            app = _domain(home)
            app.dns.run(["add", "dns", "lab-a", "ip", "203.0.113.10"])
            out = io.StringIO()
            with redirect_stdout(out):
                code = app.transfer.download(["lab-a", "inbox"])
            self.assertEqual(code, 0)
            self.assertIn("planned (file)", out.getvalue())
        local = os.path.join(home, "outbox")
        os.makedirs(local)
        with Env(SSHD_CLI_HOST="posix", SSHD_CLI_SSH="/bin/true", SSHD_CLI_READER="pipe"):
            app = _domain(home)
            out = io.StringIO()
            with redirect_stdout(out):
                code = app.transfer.upload(["lab-a", local])
            self.assertEqual(code, 0)
            self.assertIn("planned (pipe)", out.getvalue())
        err = io.StringIO()
        with redirect_stderr(err):
            self.assertEqual(_domain(home).transfer.download(["lab-a", "-hidden"]), 1)
        self.assertIn("[ERROR]", err.getvalue())

    def test_sudoers_grant_is_backup_config_only(self):
        home = tempfile.mkdtemp(prefix="sshcli_sudo_", dir="/tmp")
        with Env(SSHD_CLI_HOST="posix", SSHD_CLI_USER="ada", GLOBAL_BIN="/usr/local/bin"):
            app = _domain(home)
            self.assertEqual(app.sudoers.generate(), 0)
            path = app.sudoers.request_path()
            self.assertEqual(stat.S_IMODE(os.stat(path).st_mode), 0o600)
            with open(path, "r", encoding="utf-8") as handle:
                payload = json.loads(handle.read())
            self.assertEqual(payload["schema_version"], 1)
            self.assertEqual(payload["username"], "ada")
            self.assertEqual(payload["commands"][0]["args"], ["backup-config"])
            self.assertEqual(payload["commands"][0]["tags"], ["NOPASSWD"])
            fragment = app.sudoers.fragment()
            self.assertIn("ada ALL=(root) NOPASSWD: /usr/local/bin/sshd-cli backup-config", fragment)
            self.assertIn("Does NOT allowlist mkdir/cp/chmod/chown", fragment)
            self.assertEqual(app.sudoers.submit([]), 0)
            self.assertFalse(os.path.exists("/etc/sudoers.d/sshd-cli-from-test"))
            with open(path, "a", encoding="utf-8") as handle:
                handle.write("/bin/mkdir\n")
            err = io.StringIO()
            with redirect_stderr(err):
                self.assertEqual(app.sudoers.submit([]), 1)
            self.assertIn("OS-tool commands", err.getvalue())
            self.assertIn("backup-config only", err.getvalue())
        with Env(SSHD_CLI_HOST="termux", SSHD_CLI_USER="ada"):
            err = io.StringIO()
            with redirect_stderr(err):
                self.assertEqual(_domain(home).sudoers.generate(), 1)
            self.assertIn("sudoers not available for termux", err.getvalue())

    def test_server_refuses_non_root_and_does_not_wrap_package_tools(self):
        home = tempfile.mkdtemp(prefix="sshcli_srv_", dir="/tmp")
        with Env(
            SSHD_CLI_HOST="posix",
            SSHD_CLI_EUID="1000",
            SSHD_CLI_OS_NAME="Debian",
            SSHD_CLI_PID="0",
            SSHD_CLI_SSHD="/bin/true",
        ):
            app = _domain(home)
            err = io.StringIO()
            with redirect_stderr(err):
                self.assertEqual(app.server.start(), 1)
            self.assertIn("does not wrap sudo", err.getvalue())
            err = io.StringIO()
            with redirect_stderr(err):
                self.assertEqual(app.server.install_openssh(), 1)
            self.assertIn("Termux", err.getvalue())
            err = io.StringIO()
            with redirect_stderr(err):
                self.assertEqual(app.server.show_port(["22"]), 1)
            out = io.StringIO()
            err = io.StringIO()
            with redirect_stdout(out), redirect_stderr(err):
                self.assertEqual(app.server.status(), 0)
            self.assertIn("sshd is not running", err.getvalue())
        with Env(SSHD_CLI_HOST="termux", SSHD_CLI_SSHD="/bin/true", SSHD_CLI_WAKE="/bin/true", SSHD_CLI_PID="0"):
            app = _domain(home)
            out = io.StringIO()
            with redirect_stdout(out):
                self.assertEqual(app.run("start", []), 0)
            self.assertIn("sshd started", out.getvalue())
            self.assertIn("termux-wake-lock complete", out.getvalue())

    def test_backup_and_rc_test(self):
        home = tempfile.mkdtemp(prefix="sshcli_bak_", dir="/tmp")
        store = tempfile.mkdtemp(prefix="sshcli_store_", dir="/tmp")
        with Env(SSHD_CLI_HOST="termux", SSHD_CLI_BACKUP_DIR=store):
            err = io.StringIO()
            with redirect_stderr(err):
                self.assertEqual(_domain(home).backup.backup(), 1)
            self.assertIn("backup-config and sync-config not available for termux", err.getvalue())
        config = os.path.join(home, ".ssh")
        os.makedirs(config, mode=0o700)
        with open(os.path.join(config, "config"), "w", encoding="utf-8") as handle:
            handle.write("Host lab-a\n    HostName 203.0.113.10\n")
        with Env(SSHD_CLI_HOST="posix", SSHD_CLI_BACKUP_DIR=store):
            app = _domain(home)
            self.assertEqual(app.backup.backup(), 0)
            self.assertTrue(os.path.isfile(os.path.join(store, "config")))
            root = tempfile.mkdtemp(prefix="sshcli_rc_", dir="/tmp")
            self.assertEqual(app.rc.rc_test(["--root", root, "--file", "zshrc", "--case", "create"]), 0)
            self.assertFalse(os.path.exists(os.path.join(root, ".zshrc")))
            self.assertEqual(app.rc.rc_test(["--root", root, "--file", "bashrc", "--case", "create"]), 0)
            bashrc = os.path.join(root, ".bashrc")
            with open(bashrc, "r", encoding="utf-8") as handle:
                body = handle.read()
            self.assertIn('export PATH="', body)
            self.assertEqual(app.rc.rc_test(["--root", root, "--file", "bashrc", "--case", "modify"]), 0)
            with open(bashrc, "r", encoding="utf-8") as handle:
                modified = handle.read()
            self.assertIn("# dongle-keep-rc-test", modified)
            self.assertEqual(modified.count('export PATH="'), 1)
            seeded = tempfile.mkdtemp(prefix="sshcli_rc_noop_", dir="/tmp")
            existing = os.path.join(seeded, ".bashrc")
            line = 'export PATH="{0}:$PATH"'.format(os.path.join(home, ".local", "bin"))
            with open(existing, "w", encoding="utf-8") as handle:
                handle.write("# keep\n{0}\n".format(line))
            with Env(USER_BIN=os.path.join(home, ".local", "bin")):
                self.assertEqual(app.rc.rc_test(["--root", seeded, "--file", "bashrc", "--case", "noop"]), 0)
            with open(existing, "r", encoding="utf-8") as handle:
                kept = handle.read()
            self.assertIn("# keep", kept)
            self.assertEqual(kept.count(line), 1)


class TestCliGates(unittest.TestCase):
    def test_empty_json_quiet_and_hello_do_not_open_the_menu(self):
        previous = Cli.stdout_is_tty
        Cli.stdout_is_tty = staticmethod(lambda: True)
        try:
            self.assertTrue(Cli.opens_text_screen([]))
            self.assertTrue(Cli.opens_text_screen(["menu"]))
            self.assertTrue(Cli.opens_text_screen(["--debug"]))
            self.assertFalse(Cli.opens_text_screen(["--json"]))
            self.assertFalse(Cli.opens_text_screen(["--quiet"]))
            self.assertFalse(Cli.opens_text_screen(["hello"]))
            self.assertFalse(Cli.opens_text_screen(["status"]))
        finally:
            Cli.stdout_is_tty = previous
        home = tempfile.mkdtemp(prefix="sshcli_cli_", dir="/tmp")
        with Env(HOME=home, SSHD_CLI_HOST="posix", SSHD_CLI_OS="posix"):
            app = Cli()
            Cli.stdout_is_tty = staticmethod(lambda: False)
            try:
                out = io.StringIO()
                with redirect_stdout(out):
                    self.assertEqual(app.run([]), 0)
                self.assertIn("sshd-cli", out.getvalue())
                self.assertIn("client-side", out.getvalue())
                out = io.StringIO()
                with redirect_stdout(out):
                    self.assertEqual(app.run(["--json"]), 0)
                self.assertIn("usage", out.getvalue().lower())
            finally:
                Cli.stdout_is_tty = previous
            err = io.StringIO()
            with redirect_stderr(err):
                self.assertEqual(app.run(["--purpose"]), 1)
            self.assertIn("[ERROR]", err.getvalue())
            err = io.StringIO()
            with redirect_stderr(err):
                self.assertEqual(app.run(["no-such-verb"]), 1)
            self.assertIn("ERROR: Unknown verb 'no-such-verb'.", err.getvalue())
            err = io.StringIO()
            with redirect_stderr(err), redirect_stdout(io.StringIO()):
                self.assertEqual(app.run(["--json", "dns", "delete", "missing-host"]), 1)
            payload = json.loads(err.getvalue().strip().splitlines()[-1])
            self.assertEqual(payload["type"], "out_error")
            self.assertEqual(payload["code"], "unknown")
            self.assertNotIn("[ERROR]", err.getvalue())


if __name__ == "__main__":
    unittest.main()
