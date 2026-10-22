# =============================================================================
# One domain object the CLI and the text menu both call.
# requirement-domain-sshd
# =============================================================================
from __future__ import annotations

import os

from .backup import Backup
from .dns import Dns
from .fixconfig import FixConfig
from .host import Host
from .output import Output
from .rcpath import RcPath
from .server import Server
from .sudoers import Sudoers
from .transfer import Transfer


# Typed names that are domain work. HelloTui lifecycle verbs are not in this set.
DOMAIN_VERBS = (
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


class Domain:
    """OpenSSH client and sshd operations for one process."""

    def __init__(
        self,
        output: Output,
        home: str | None = None,
        app_name: str = "sshd-cli",
        version: str = "",
        environ: dict | None = None,
    ) -> None:
        self.output = output
        self.home = home if home is not None else os.environ.get("HOME", "")
        self.app_name = app_name
        self.version = version
        self.host = Host(environ=environ)
        self.fix = FixConfig(self.host, output, home=self.home)
        self.dns = Dns(output, self.home, app_name=app_name)
        self.transfer = Transfer(self.dns, output, app_name=app_name)
        self.server = Server(self.host, output, app_name=app_name)
        self.sudoers = Sudoers(self.host, output, self.home, app_name=app_name)
        self.backup = Backup(self.host, output, self.home, app_name=app_name)
        self.rc = RcPath(output, self.home, app_name, version)

    def auto_fix(self) -> None:
        self.fix.auto()

    def run(self, verb: str, args: list, input_file: str = "", output_file: str = "") -> int:
        """Run one domain verb. Returns a process status."""
        if verb == "fix-config":
            return self.fix.run(input_file=input_file, output_file=output_file)
        if verb == "dns":
            return self.dns.run(args)
        if verb == "ssh":
            return self.transfer.ssh(args)
        if verb == "download":
            return self.transfer.download(args)
        if verb == "upload":
            return self.transfer.upload(args)
        if verb == "status":
            return self.server.status()
        if verb == "start":
            code = self.server.start()
            if code == 0 and self.host.is_termux():
                self.server.wake(unlock=False)
            return code
        if verb == "stop":
            return self.server.stop()
        if verb == "restart":
            return self.server.restart()
        if verb == "port":
            return self.server.show_port(args)
        if verb == "config":
            return self.server.show_config()
        if verb == "host-keys":
            return self.server.host_keys(args)
        if verb == "auth-keys":
            return self.server.auth_keys()
        if verb == "install":
            code = self.server.install_openssh()
            if code == 0 and self.host.is_termux():
                self.rc.add_bashrc()
                self.rc.ensure_profile()
            return code
        if verb == "wake-lock":
            return self.server.wake(unlock=False)
        if verb == "wake-unlock":
            return self.server.wake(unlock=True)
        if verb == "backup-config":
            return self.backup.backup()
        if verb == "sync-config":
            return self.backup.sync()
        if verb == "sync-from-remote":
            return self.backup.sync_from_remote(args)
        if verb == "generate-sudoer-request":
            return self.sudoers.generate()
        if verb == "submit-sudoer-request":
            return self.sudoers.submit(args)
        if verb == "print-sudoers":
            return self.sudoers.print_fragment()
        if verb == "print-sudoers-install-script":
            return self.sudoers.print_install_script()
        if verb == "remove-project-sudoers":
            return self.sudoers.remove()
        if verb == "rc-test":
            return self.rc.rc_test(args)
        return self.output.error(
            "Unknown verb '{0}'. Next: {1} help".format(verb, self.app_name)
        )

    def menu_text(self, verb: str) -> str:
        """A short result for a menu leaf that does not need extra operands."""
        code = self.run(verb, [])
        if code == 0:
            return "{0} finished.".format(verb)
        return "{0} failed.".format(verb)
