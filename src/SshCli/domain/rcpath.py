# =============================================================================
# Login rc helpers used by Termux install and the rc-test verb.
# requirement-shell-path-and-shell-support behavior, kept for the OpenSSH login.
# A missing .zshrc is not invented.
# =============================================================================
from __future__ import annotations

import os

from .output import Output


class RcPath:
    """Create or note PATH and the profile source block. Never a second export."""

    def __init__(self, output: Output, home: str, app_name: str, version: str) -> None:
        self.output = output
        self.home = home
        self.app_name = app_name
        self.version = version

    def user_bin(self) -> str:
        return os.environ.get("USER_BIN", os.path.join(self.home, ".local", "bin"))

    def path_line(self) -> str:
        return 'export PATH="{0}:$PATH"'.format(self.user_bin())

    def bashrc_path(self) -> str:
        return os.environ.get("BASHRC", os.path.join(self.home, ".bashrc"))

    def profile_path(self) -> str:
        return os.environ.get("PROFILE", os.path.join(self.home, ".profile"))

    def zshrc_path(self) -> str:
        return os.environ.get("ZSHRC", os.path.join(self.home, ".zshrc"))

    def add_bashrc(self) -> int:
        path = self.bashrc_path()
        line = self.path_line()
        created = False
        if not os.path.isfile(path):
            try:
                with open(path, "w", encoding="utf-8") as handle:
                    handle.write("# Interactive rc created by {0} installer ({1})\n".format(self.app_name, self.version))
                os.chmod(path, 0o644)
            except OSError:
                self.output.warn(
                    "Could not create {0}. Next: create that file as this login, then re-run {1} install.".format(
                        path, self.app_name
                    )
                )
                return 1
            created = True
            self.output.plain("→ Created {0}".format(path))
        try:
            with open(path, "r", encoding="utf-8", errors="replace") as handle:
                body = handle.read()
        except OSError:
            return 1
        if line not in body:
            with open(path, "a", encoding="utf-8") as handle:
                handle.write("\n# Added by {0} installer ({1})\n{2}\n".format(self.app_name, self.version, line))
            self.output.plain("→ Added {0} to PATH for bash".format(self.user_bin()))
            return 0
        comment = "# Added by {0} installer ({1})".format(self.app_name, self.version)
        if comment not in body:
            with open(path, "a", encoding="utf-8") as handle:
                handle.write("\n{0}\n".format(comment))
            if not created:
                self.output.plain("→ Noted {0} on existing PATH line".format(self.app_name))
            return 0
        return 0 if created else 1

    def ensure_profile(self) -> int:
        path = self.profile_path()
        if os.path.isfile(path):
            return 1
        body = (
            "# BEGIN {app} profile source-bashrc\n"
            "# Created so a bash login shell sources interactive rc.\n"
            "if [ -n \"${{BASH_VERSION:-}}\" ]; then\n"
            "    if [ -f \"${{HOME}}/.bashrc\" ]; then\n"
            "        . \"${{HOME}}/.bashrc\"\n"
            "    fi\n"
            "fi\n"
            "# END {app} profile source-bashrc\n"
        ).format(app=self.app_name)
        try:
            with open(path, "w", encoding="utf-8") as handle:
                handle.write(body)
            os.chmod(path, 0o644)
        except OSError:
            self.output.warn(
                "Could not create {0}. Next: create that file as this login so SSH login reads ~/.bashrc.".format(path)
            )
            return 1
        self.output.plain("→ Created {0} (login shell sources ~/.bashrc)".format(path))
        return 0

    def add_zshrc(self) -> int:
        """Append PATH only when .zshrc already exists. Do not invent the file."""
        path = self.zshrc_path()
        if not os.path.isfile(path):
            return 1
        line = self.path_line()
        with open(path, "r", encoding="utf-8", errors="replace") as handle:
            body = handle.read()
        if line in body:
            return 0
        with open(path, "a", encoding="utf-8") as handle:
            handle.write("\n# Added by {0} installer ({1})\n{2}\n".format(self.app_name, self.version, line))
        self.output.plain("→ Added {0} to PATH for zsh".format(self.user_bin()))
        return 0

    def rc_test(self, args: list) -> int:
        root = ""
        file_name = "bashrc"
        case = "create"
        index = 0
        while index < len(args):
            token = args[index]
            if token in ("--root", "--file", "--case", "--feature") and index + 1 >= len(args):
                return self.output.error(
                    "Unknown rc-test operand: {0}. Next: {1} rc-test --root <dir> --file bashrc|profile --case create|modify|noop".format(
                        token, self.app_name
                    )
                )
            if token == "--root":
                root = args[index + 1]
                index += 2
                continue
            if token == "--file":
                file_name = args[index + 1]
                index += 2
                continue
            if token == "--case":
                case = args[index + 1]
                index += 2
                continue
            if token == "--feature":
                index += 2
                continue
            return self.output.error(
                "Unknown rc-test operand: {0}. Next: {1} rc-test --root <dir> --file bashrc|profile --case create|modify|noop".format(
                    token, self.app_name
                )
            )
        if file_name not in ("bashrc", "zshrc", "profile"):
            return self.output.error(
                "Unknown rc-test --file {0}. Next: use bashrc, zshrc, or profile.".format(file_name)
            )
        if case not in ("create", "modify", "noop"):
            return self.output.error(
                "Unknown rc-test --case {0}. Next: use create, modify, or noop.".format(case)
            )
        if not root:
            return self.output.error("rc-test needs --root <dir>. Next: {0} rc-test --root <dir> --file bashrc --case create".format(self.app_name))
        os.makedirs(root, exist_ok=True)
        names = {"bashrc": ".bashrc", "zshrc": ".zshrc", "profile": ".profile"}
        dest = os.path.join(root, names[file_name])
        saved = {}
        env_key = {"bashrc": "BASHRC", "zshrc": "ZSHRC", "profile": "PROFILE"}[file_name]
        saved[env_key] = os.environ.get(env_key)
        os.environ[env_key] = dest
        try:
            if case == "create":
                if os.path.isfile(dest):
                    os.remove(dest)
            elif case == "modify":
                with open(dest, "w", encoding="utf-8") as handle:
                    handle.write("# dongle-keep-rc-test\n")
            elif case == "noop" and not os.path.isfile(dest) and file_name != "zshrc":
                if file_name == "profile":
                    with open(dest, "w", encoding="utf-8") as handle:
                        handle.write(self._profile_body())
                else:
                    with open(dest, "w", encoding="utf-8") as handle:
                        handle.write(
                            "# Interactive rc created by {0} installer ({1})\n"
                            "# Added by {0} installer ({1})\n"
                            "{2}\n".format(self.app_name, self.version, self.path_line())
                        )
            if file_name == "bashrc":
                self.add_bashrc()
            elif file_name == "zshrc":
                self.add_zshrc()
            else:
                self.ensure_profile()
        finally:
            if saved[env_key] is None:
                os.environ.pop(env_key, None)
            else:
                os.environ[env_key] = saved[env_key]
        if file_name == "zshrc" and case == "create":
            if os.path.isfile(dest):
                return self.output.error("rc-test create must not invent .zshrc.")
            if self.output.json_mode:
                return self.output.json_ok(
                    "out_success",
                    "rc-test create zshrc skipped (do not invent)",
                    command="rc-test",
                    file="zshrc",
                    case="create",
                    root=root,
                )
            self.output.ok("rc-test create zshrc skipped (do not invent).")
            return 0
        if not os.path.isfile(dest):
            return self.output.error("rc-test {0} did not write {1}.".format(case, dest))
        with open(dest, "r", encoding="utf-8") as handle:
            body = handle.read()
        if case == "modify" and "# dongle-keep-rc-test" not in body:
            return self.output.error("rc-test modify dropped the existing line in {0}.".format(dest))
        if file_name != "zshrc" and case == "noop":
            return 0
        if self.output.json_mode:
            return self.output.json_ok("out_success", "rc-test", command="rc-test", file=file_name, case=case, root=root)
        self.output.ok("rc-test {0} {1} wrote {2}.".format(file_name, case, dest))
        return 0

    def _profile_body(self) -> str:
        return (
            "# BEGIN {app} profile source-bashrc\n"
            "if [ -n \"${{BASH_VERSION:-}}\" ]; then\n"
            "    if [ -f \"${{HOME}}/.bashrc\" ]; then\n"
            "        . \"${{HOME}}/.bashrc\"\n"
            "    fi\n"
            "fi\n"
            "# END {app} profile source-bashrc\n"
        ).format(app=self.app_name)
