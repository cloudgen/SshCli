# =============================================================================
# Sudoers grant for backup-config only.
# requirement-domain-sshd — no mkdir, cp, chmod, or chown on the grant.
# =============================================================================
from __future__ import annotations

import getpass
import json
import os

from .host import Host
from .output import Output


class Sudoers:
    """Write, print, submit, and remove the project sudoers draft."""

    def __init__(self, host: Host, output: Output, home: str, app_name: str = "sshd-cli") -> None:
        self.host = host
        self.output = output
        self.home = home
        self.app_name = app_name

    def login(self) -> str:
        forced = os.environ.get("SSHD_CLI_USER", "")
        if forced:
            return forced
        try:
            return getpass.getuser()
        except OSError:
            return "unknown"

    def global_bin(self) -> str:
        forced = os.environ.get("GLOBAL_BIN", "")
        if forced:
            return forced
        if self.host.is_termux():
            prefix = self.host.environ.get("PREFIX", "/data/data/com.termux/files/usr")
            return os.path.join(prefix, "bin")
        return "/usr/local/bin"

    def command_path(self) -> str:
        return os.path.join(self.global_bin(), self.app_name)

    def request_path(self) -> str:
        folder = os.path.join(self.home, ".config", self.app_name)
        return os.path.join(folder, "sudoer-request-{0}.json".format(self.login()))

    def installed_path(self) -> str:
        return os.path.join("/etc/sudoers.d", self.app_name)

    def fragment(self) -> str:
        user = self.login()
        path = self.command_path()
        installed = self.installed_path()
        purpose = "Allow {0} to run {1} backup-config as root.".format(user, self.app_name)
        return (
            "# Purpose: {purpose}\n"
            "# {app} — {app} backup-config only (review before install)\n"
            "# Target user: {user}\n"
            "# Install: sudo install -m 0440 <this-file> {installed}\n"
            "# Validate: sudo visudo -c -f {installed}\n"
            "# Grant is the project command only. Does NOT allowlist mkdir/cp/chmod/chown.\n"
            "{user} ALL=(root) NOPASSWD: {path} backup-config\n"
        ).format(purpose=purpose, app=self.app_name, user=user, installed=installed, path=path)

    def payload(self, action: str = "add") -> dict:
        if action not in ("add", "update"):
            action = "add"
        user = self.login()
        return {
            "schema_version": 1,
            "purpose": "Allow {0} to run {1} backup-config as root.".format(user, self.app_name),
            "username": user,
            "service": self.app_name,
            "action": action,
            "commands": [
                {
                    "runas": "root",
                    "tags": ["NOPASSWD"],
                    "path": self.command_path(),
                    "args": ["backup-config"],
                }
            ],
        }

    def _refuse_class(self) -> int | None:
        if self.host.show_sudoers():
            return None
        label = self.host.nuser_label()
        return self.output.error(
            "sudoers not available for {0}. Next: {1} help".format(label, self.app_name)
        )

    def generate(self) -> int:
        refused = self._refuse_class()
        if refused:
            return refused
        path = self.request_path()
        folder = os.path.dirname(path)
        os.makedirs(folder, mode=0o700, exist_ok=True)
        text = json.dumps(self.payload(), ensure_ascii=False, separators=(",", ":")) + "\n"
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(text)
        os.chmod(path, 0o600)
        if self.output.json_mode:
            return self.output.json_ok("generate-sudoer-request", "wrote", path=path)
        self.output.ok("Wrote sudoer request {0}.".format(path))
        return 0

    def print_fragment(self) -> int:
        refused = self._refuse_class()
        if refused:
            return refused
        text = self.fragment()
        if self.output.json_mode:
            return self.output.json_ok("print-sudoers", "ok", path=self.command_path())
        self.output.plain(text.rstrip("\n"))
        return 0

    def print_install_script(self) -> int:
        refused = self._refuse_class()
        if refused:
            return refused
        installed = self.installed_path()
        script = (
            "#!/bin/sh\n"
            "install -m 0440 \"$1\" {0}\n"
            "visudo -c -f {0}\n"
        ).format(installed)
        if self.output.json_mode:
            return self.output.json_ok("print-sudoers-install-script", "ok")
        self.output.plain(script.rstrip("\n"))
        return 0

    def submit(self, args: list) -> int:
        refused = self._refuse_class()
        if refused:
            return refused
        path = self.request_path()
        if not os.path.isfile(path):
            return self.output.error(
                "sudoer grant file missing. Next: {0} generate-sudoer-request".format(self.app_name)
            )
        with open(path, "r", encoding="utf-8") as handle:
            body = handle.read()
        for banned in ("/usr/bin/mkdir", "/bin/mkdir", "/usr/bin/cp", "/bin/cp", "/usr/bin/chmod", "/bin/chmod", "/usr/bin/chown", "/bin/chown"):
            if banned in body:
                return self.output.error(
                    "refusing sudoer grant with OS-tool commands (need {0} backup-config only)".format(self.command_path())
                )
        if '"backup-config"' not in body:
            return self.output.error(
                "Sudoer file is incomplete: it does not allow backup-config. Path: {0}".format(path)
            )
        if self.output.json_mode:
            return self.output.json_ok("submit-sudoer-request", "ready", path=path)
        self.output.ok("Sudoer request is ready to review: {0}.".format(path))
        self.output.info("This program does not install the file into /etc. Next: review it, then install it with visudo.")
        return 0

    def remove(self) -> int:
        refused = self._refuse_class()
        if refused:
            return refused
        path = self.request_path()
        if os.path.isfile(path):
            os.remove(path)
        if self.output.json_mode:
            return self.output.json_ok("remove-project-sudoers", "removed", path=path)
        self.output.ok("Removed sudoer draft {0}.".format(path))
        return 0
