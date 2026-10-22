# =============================================================================
# This login's ~/.ssh/config Host list.
# requirement-domain-sshd — dns, ssh Host pick, Termux bundle, Old OpenSSH.
# =============================================================================
from __future__ import annotations

import os
import shlex

from .output import Output

TERMUX_PORT = "8022"
TERMUX_SAI = "15"
TERMUX_SACM = "12"
TERMUX_TCPKA = "yes"
TERMUX_IPQOS = "none"
TERMUX_CIPHERS = "aes128-ctr,aes256-ctr"
TERMUX_MACS = "hmac-sha2-256"
OLD_ALGORITHMS = "+ssh-rsa,ssh-dss"

_FIELDS = (
    "dns",
    "ip",
    "user",
    "port",
    "identity-file",
    "identities-only",
    "termux",
    "old-openssh",
)


def _blank_host(name: str = "") -> dict:
    return {
        "dns": name,
        "ip": "",
        "user": "",
        "port": "",
        "identity-file": "",
        "identities-only": "",
        "sai": "",
        "sacm": "",
        "tcpka": "",
        "ipqos": "",
        "ciphers": "",
        "macs": "",
        "hka": "",
        "paa": "",
        "extras": [],
    }


def _keyword(line: str) -> tuple[str, str]:
    stripped = line.strip()
    if not stripped or stripped.startswith("#"):
        return "", ""
    parts = stripped.split(None, 1)
    key = parts[0].lower()
    value = parts[1].strip() if len(parts) > 1 else ""
    if "=" in parts[0] and len(parts) == 1:
        key, value = parts[0].split("=", 1)
        key = key.lower()
        value = value.strip()
    return key, value


def parse_config(text: str) -> list:
    """Host blocks in file order. A Host with several names becomes one record per name."""
    records = []
    current = None
    for raw in text.splitlines():
        stripped = raw.strip()
        if stripped.lower().startswith("host "):
            if current is not None:
                records.extend(_split_names(current))
            names = stripped.split(None, 1)[1]
            current = _blank_host(names)
            continue
        if stripped.lower().startswith("match "):
            if current is not None:
                records.extend(_split_names(current))
                current = None
            continue
        if current is None:
            continue
        key, value = _keyword(raw)
        if key == "hostname":
            current["ip"] = value
        elif key == "user":
            current["user"] = value
        elif key == "port":
            current["port"] = value
        elif key == "identityfile":
            current["identity-file"] = value
        elif key == "identitiesonly":
            current["identities-only"] = value
        elif key == "serveraliveinterval":
            current["sai"] = value
        elif key == "serveralivecountmax":
            current["sacm"] = value
        elif key == "tcpkeepalive":
            current["tcpka"] = value
        elif key == "ipqos":
            current["ipqos"] = value
        elif key == "ciphers":
            current["ciphers"] = value
        elif key == "macs":
            current["macs"] = value
        elif key == "hostkeyalgorithms":
            current["hka"] = value
        elif key == "pubkeyacceptedalgorithms":
            current["paa"] = value
        elif key == "pubkeyacceptedkeytypes" and not current["paa"]:
            current["paa"] = value
        else:
            current["extras"].append(raw.strip())
    if current is not None:
        records.extend(_split_names(current))
    return records


def _split_names(record: dict) -> list:
    names = record["dns"].split()
    if not names:
        return []
    out = []
    for name in names:
        if name == "*":
            continue
        copy = dict(record)
        copy["dns"] = name
        copy["extras"] = list(record["extras"])
        out.append(copy)
    return out


def render_config(records: list) -> str:
    blocks = []
    for record in records:
        lines = ["Host {0}".format(record["dns"])]
        pairs = (
            ("HostName", record.get("ip", "")),
            ("User", record.get("user", "")),
            ("Port", record.get("port", "")),
            ("IdentityFile", record.get("identity-file", "")),
            ("IdentitiesOnly", record.get("identities-only", "")),
            ("ServerAliveInterval", record.get("sai", "")),
            ("ServerAliveCountMax", record.get("sacm", "")),
            ("TCPKeepAlive", record.get("tcpka", "")),
            ("IPQoS", record.get("ipqos", "")),
            ("Ciphers", record.get("ciphers", "")),
            ("MACs", record.get("macs", "")),
            ("HostKeyAlgorithms", record.get("hka", "")),
            ("PubkeyAcceptedAlgorithms", record.get("paa", "")),
        )
        for key, value in pairs:
            if value:
                lines.append("    {0} {1}".format(key, value))
        for extra in record.get("extras") or []:
            lines.append("    {0}".format(extra))
        blocks.append("\n".join(lines))
    if not blocks:
        return ""
    return "\n\n".join(blocks) + "\n"


def termux_yes(record: dict) -> bool:
    return (
        record.get("port") == TERMUX_PORT
        and record.get("sai") == TERMUX_SAI
        and record.get("sacm") == TERMUX_SACM
        and record.get("tcpka") == TERMUX_TCPKA
        and record.get("ipqos") == TERMUX_IPQOS
        and record.get("ciphers") == TERMUX_CIPHERS
        and record.get("macs") == TERMUX_MACS
    )


def old_yes(record: dict) -> bool:
    return bool(record.get("hka") or record.get("paa"))


def apply_termux(record: dict, yes: bool) -> None:
    if yes:
        record["port"] = TERMUX_PORT
        record["sai"] = TERMUX_SAI
        record["sacm"] = TERMUX_SACM
        record["tcpka"] = TERMUX_TCPKA
        record["ipqos"] = TERMUX_IPQOS
        record["ciphers"] = TERMUX_CIPHERS
        record["macs"] = TERMUX_MACS
        return
    record["sai"] = ""
    record["sacm"] = ""
    record["tcpka"] = ""
    record["ipqos"] = ""
    record["ciphers"] = ""
    record["macs"] = ""


def apply_old(record: dict, yes: bool) -> None:
    if yes:
        record["hka"] = OLD_ALGORITHMS
        record["paa"] = OLD_ALGORITHMS
        return
    record["hka"] = ""
    record["paa"] = ""


def algo_commented(text: str, host: str) -> bool:
    """True when that Host stanza comments HostKeyAlgorithms or PubkeyAccepted*."""
    in_host = False
    for raw in text.splitlines():
        stripped = raw.strip()
        lower = stripped.lower()
        if lower.startswith("host "):
            names = stripped.split()[1:]
            in_host = host in names
            continue
        if lower.startswith("match "):
            in_host = False
            continue
        if not in_host or not stripped.startswith("#"):
            continue
        body = stripped.lstrip("#").strip().lower()
        if body.startswith(("hostkeyalgorithms", "pubkeyacceptedalgorithms", "pubkeyacceptedkeytypes")):
            return True
    return False


class Dns:
    """Read and write this login's Host list."""

    def __init__(self, output: Output, home: str, app_name: str = "sshd-cli") -> None:
        self.output = output
        self.home = home
        self.app_name = app_name

    def path(self) -> str:
        return os.path.join(self.home, ".ssh", "config")

    def load(self) -> list:
        path = self.path()
        if not os.path.isfile(path):
            return []
        with open(path, "r", encoding="utf-8", errors="replace") as handle:
            return parse_config(handle.read())

    def save(self, records: list) -> None:
        path = self.path()
        folder = os.path.dirname(path)
        os.makedirs(folder, mode=0o700, exist_ok=True)
        try:
            os.chmod(folder, 0o700)
        except OSError:
            pass
        text = render_config(records)
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(text)
        try:
            os.chmod(path, 0o600)
        except OSError:
            pass

    def lookup(self, token: str) -> dict | None:
        records = self.load()
        if token.isdigit():
            index = int(token)
            if 1 <= index <= len(records):
                return records[index - 1]
            return None
        for record in records:
            if record["dns"] == token:
                return record
        return None

    def list_text(self) -> str:
        records = self.load()
        if not records:
            return "No Host entries in {0}.".format(self.path())
        lines = []
        for index, record in enumerate(records, start=1):
            lines.append(
                "{0}. {1}  ip={2}  user={3}  port={4}  termux={5}  old-openssh={6}".format(
                    index,
                    record["dns"],
                    record["ip"] or "-",
                    record["user"] or "-",
                    record["port"] or "22",
                    "yes" if termux_yes(record) else "no",
                    "yes" if old_yes(record) else "no",
                )
            )
        return "\n".join(lines)

    def run(self, args: list) -> int:
        """dns list | set | add | delete | unset."""
        if not args or args[0] in ("list", "ls"):
            text = self.list_text()
            if self.output.json_mode:
                records = self.load()
                return self.output.json_ok(
                    "dns",
                    "list",
                    count=str(len(records)),
                    path=self.path(),
                )
            self.output.plain(text)
            return 0
        action = args[0]
        if action == "delete":
            return self._delete(args[1:])
        if action == "unset":
            return self._unset(args[1:])
        if action in ("set", "add"):
            return self._set(action, args[1:])
        return self.output.error(
            "Unknown dns action '{0}'. Next: {1} dns list".format(action, self.app_name)
        )

    def _parse_fields(self, tokens: list) -> tuple[dict, int | None]:
        """Return field updates. A missing value is an error status."""
        updates = {}
        index = 0
        aliases = {
            "--dns": "dns",
            "--ip": "ip",
            "--user": "user",
            "--port": "port",
            "--identity-file": "identity-file",
            "identityfile": "identity-file",
            "--identities-only": "identities-only",
            "identitiesonly": "identities-only",
            "--termux": "termux",
            "--old-openssh": "old-openssh",
            "oldopenssh": "old-openssh",
        }
        while index < len(tokens):
            raw = tokens[index]
            key = aliases.get(raw, raw)
            if key not in _FIELDS:
                self.output.error(
                    "Unknown dns field '{0}'. Use dns, ip, user, port, identity-file, identities-only, termux, or old-openssh.".format(raw)
                )
                return {}, 1
            if index + 1 >= len(tokens):
                self.output.error(
                    "{0} needs a value. Next: {1} dns set <n> {0} <value>".format(key, self.app_name)
                )
                return {}, 1
            updates[key] = tokens[index + 1]
            index += 2
        return updates, None

    def _validate(self, record: dict) -> int | None:
        name = record.get("dns", "")
        if not name or any(char.isspace() for char in name) or name == "*":
            self.output.error(
                "dns name is empty or invalid. Next: {0} dns add dns <name> ip <addr>".format(self.app_name)
            )
            return 1
        port = record.get("port", "")
        if port and (not port.isdigit() or not 1 <= int(port) <= 65535):
            self.output.error(
                "port '{0}' is not a listen port. Next: {1} dns set <n> port 22".format(port, self.app_name)
            )
            return 1
        ident = record.get("identities-only", "")
        if ident and ident.lower() not in ("yes", "no"):
            self.output.error(
                "identities-only needs yes, no, or empty. Next: {0} dns set <n> identities-only yes".format(self.app_name)
            )
            return 1
        return None

    def _apply_updates(self, record: dict, updates: dict) -> int | None:
        for key in ("dns", "ip", "user", "port", "identity-file", "identities-only"):
            if key in updates:
                record[key] = "" if updates[key] in ('""', "''") else updates[key]
        if "termux" in updates:
            answer = updates["termux"].lower()
            if answer not in ("yes", "no", "y", "n"):
                self.output.error("termux needs yes or no. Next: {0} dns add dns <name> termux yes".format(self.app_name))
                return 1
            apply_termux(record, answer in ("yes", "y"))
        if "old-openssh" in updates:
            answer = updates["old-openssh"].lower()
            if answer not in ("yes", "no", "y", "n"):
                self.output.error(
                    "old-openssh needs yes or no. Next: {0} dns add dns <name> old-openssh yes".format(self.app_name)
                )
                return 1
            apply_old(record, answer in ("yes", "y"))
        return self._validate(record)

    def _set(self, action: str, tokens: list) -> int:
        records = self.load()
        if action == "add":
            updates, failed = self._parse_fields(tokens)
            if failed:
                return failed
            record = _blank_host()
            if self._apply_updates(record, updates):
                return 1
            if any(item["dns"] == record["dns"] for item in records):
                return self.output.error(
                    "dns name '{0}' is already a Host entry. Next: {1} dns list".format(record["dns"], self.app_name)
                )
            records.append(record)
        else:
            if not tokens:
                return self.output.error(
                    "dns set needs a Host. Next: {0} dns list, then {0} dns set <n|name> ip <addr>".format(self.app_name)
                )
            selector = tokens[0]
            updates, failed = self._parse_fields(tokens[1:])
            if failed:
                return failed
            found = None
            for index, record in enumerate(records):
                if selector.isdigit() and int(selector) == index + 1:
                    found = record
                elif record["dns"] == selector:
                    found = record
            if found is None:
                return self.output.error(
                    "No Host entry '{0}' in {1}. Next: {2} dns list".format(selector, self.path(), self.app_name)
                )
            if self._apply_updates(found, updates):
                return 1
            if sum(1 for item in records if item["dns"] == found["dns"]) > 1:
                return self.output.error(
                    "dns name '{0}' is already a Host entry. Next: {1} dns list".format(found["dns"], self.app_name)
                )
            record = found
        self.save(records)
        if self.output.json_mode:
            return self.output.json_ok(
                "out_success",
                "Host entry updated." if action == "set" else "Host entry added.",
                dns=record["dns"],
                ip=record["ip"],
                user=record["user"],
                port=record["port"],
            )
        verb = "Updated" if action == "set" else "Added"
        self.output.ok("{0} Host {1} in {2}.".format(verb, record["dns"], self.path()))
        return 0

    def _delete(self, tokens: list) -> int:
        if not tokens:
            return self.output.error("dns delete needs a Host. Next: {0} dns list".format(self.app_name))
        selector = tokens[0]
        records = self.load()
        kept = []
        removed = None
        for index, record in enumerate(records):
            match = (selector.isdigit() and int(selector) == index + 1) or record["dns"] == selector
            if match and removed is None:
                removed = record
                continue
            kept.append(record)
        if removed is None:
            return self.output.error(
                "No Host entry '{0}' in {1}. Next: {2} dns list".format(selector, self.path(), self.app_name)
            )
        self.save(kept)
        if self.output.json_mode:
            return self.output.json_ok("out_success", "Host entry removed.", dns=removed["dns"])
        self.output.ok("Removed Host {0} from {1}.".format(removed["dns"], self.path()))
        return 0

    def _unset(self, tokens: list) -> int:
        """Drop extra settings. dns and ip stay."""
        if len(tokens) < 2:
            return self.output.error(
                "dns unset needs a Host and a field. Next: {0} dns unset <n|name> user".format(self.app_name)
            )
        selector = tokens[0]
        field = tokens[1]
        if field in ("dns", "ip"):
            return self.output.error(
                "dns unset cannot drop {0}. Next: {1} dns delete <n|name>".format(field, self.app_name)
            )
        allowed = {
            "user": "user",
            "port": "port",
            "identity-file": "identity-file",
            "identities-only": "identities-only",
            "termux": "termux",
            "old-openssh": "old-openssh",
        }
        if field not in allowed:
            return self.output.error(
                "dns unset cannot drop '{0}'. Use user, port, identity-file, identities-only, termux, or old-openssh.".format(field)
            )
        records = self.load()
        found = None
        for index, record in enumerate(records):
            if (selector.isdigit() and int(selector) == index + 1) or record["dns"] == selector:
                found = record
                break
        if found is None:
            return self.output.error(
                "No Host entry '{0}' in {1}. Next: {2} dns list".format(selector, self.path(), self.app_name)
            )
        if field == "termux":
            apply_termux(found, False)
        elif field == "old-openssh":
            apply_old(found, False)
        else:
            found[field] = ""
        self.save(records)
        if self.output.json_mode:
            return self.output.json_ok("out_success", "Host extra setting dropped.", dns=found["dns"], field=field)
        self.output.ok("Unset {0} on Host {1}.".format(field, found["dns"]))
        return 0

    def ssh_argv(self, record: dict, user: str, binary: str, batch: bool) -> list:
        """OpenSSH argv. A commented algorithm line adds -o HostKeyAlgorithms=+ssh-rsa."""
        argv = [binary]
        text = ""
        if os.path.isfile(self.path()):
            with open(self.path(), "r", encoding="utf-8", errors="replace") as handle:
                text = handle.read()
        if algo_commented(text, record["dns"]):
            argv.extend(["-o", "HostKeyAlgorithms=+ssh-rsa"])
        if batch:
            argv.extend(["-o", "BatchMode=yes", "-o", "ConnectTimeout=15"])
        if user:
            argv.extend(["-l", user])
        argv.append(record["dns"])
        return argv

    def command_text(self, argv: list) -> str:
        return " ".join(shlex.quote(part) for part in argv)
