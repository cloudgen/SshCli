# =============================================================================
# backup-config, sync-config, and sync-from-remote.
# requirement-domain-sshd — Termux, Git Bash, and Windows cmd hide backup and sync.
# =============================================================================
from __future__ import annotations

import os
import shutil
import subprocess

from .host import Host
from .output import Output


class Backup:
    """Copy this login's OpenSSH client config to the project store and back."""

    def __init__(self, host: Host, output: Output, home: str, app_name: str = "sshd-cli") -> None:
        self.host = host
        self.output = output
        self.home = home
        self.app_name = app_name

    def source(self) -> str:
        return os.path.join(self.home, ".ssh", "config")

    def store(self) -> str:
        forced = os.environ.get("SSHD_CLI_BACKUP_DIR", "")
        if forced:
            return os.path.join(forced, "config")
        return os.path.join("/var", self.app_name, "config")

    def _refuse(self) -> int | None:
        if self.host.show_config_backup():
            return None
        return self.output.error(
            "backup-config and sync-config not available for {0}.".format(self.host.nuser_label())
        )

    def backup(self) -> int:
        refused = self._refuse()
        if refused:
            return refused
        source = self.source()
        if not os.path.isfile(source):
            return self.output.error(
                "No {0} to back up. Next: {1} dns add dns <name> ip <addr>".format(source, self.app_name)
            )
        destination = self.store()
        folder = os.path.dirname(destination)
        try:
            os.makedirs(folder, mode=0o755, exist_ok=True)
            shutil.copyfile(source, destination)
            os.chmod(destination, 0o600)
        except OSError as exc:
            return self.output.error(
                "backup-config could not write {0} ({1}). Next: a root login on POSIX Linux.".format(destination, exc)
            )
        if self.output.json_mode:
            return self.output.json_ok("backup-config", "ok", path=destination)
        self.output.ok("Backed up {0} to {1}.".format(source, destination))
        return 0

    def sync(self) -> int:
        refused = self._refuse()
        if refused:
            return refused
        destination = self.source()
        source = self.store()
        if not os.path.isfile(source):
            return self.output.error(
                "No store at {0}. Next: {1} backup-config".format(source, self.app_name)
            )
        folder = os.path.dirname(destination)
        os.makedirs(folder, mode=0o700, exist_ok=True)
        shutil.copyfile(source, destination)
        os.chmod(destination, 0o600)
        if self.output.json_mode:
            return self.output.json_ok("sync-config", "ok", path=destination)
        self.output.ok("Restored {0} from {1}.".format(destination, source))
        return 0

    def sync_from_remote(self, args: list) -> int:
        """Copy the store from another host. Allowed on the normal-user class as menu 18."""
        if not args:
            return self.output.error(
                "sync-from-remote needs a Host. Next: {0} sync-from-remote <host>".format(self.app_name)
            )
        host = args[0]
        binary = os.environ.get("SSHD_CLI_SCP", "") or "scp"
        destination = self.source()
        folder = os.path.dirname(destination)
        os.makedirs(folder, mode=0o700, exist_ok=True)
        remote = "{0}:/var/{1}/config".format(host, self.app_name)
        if os.environ.get("SSHD_CLI_SCP"):
            code = subprocess.call([binary, "-o", "BatchMode=yes", remote, destination])
            if code != 0:
                return self.output.error("sync-from-remote failed for {0}.".format(host))
        else:
            code = subprocess.call([binary, "-o", "BatchMode=yes", "-o", "ConnectTimeout=15", remote, destination])
            if code != 0:
                return self.output.error("sync-from-remote failed for {0}.".format(host))
        try:
            os.chmod(destination, 0o600)
        except OSError:
            pass
        if self.output.json_mode:
            return self.output.json_ok("sync-from-remote", "ok", host=host, path=destination)
        self.output.ok("Synced config from {0} into {1}.".format(host, destination))
        return 0
