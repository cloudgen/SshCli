# =============================================================================
# Host class for menu hiding and the fix-config OS class.
# requirement-domain-sshd
# Termux, Git Bash, and Windows cmd are a command line for a normal user only.
# =============================================================================
from __future__ import annotations

import os
import platform


class Host:
    """What this login may show on the menu, and which OpenSSH keywords to comment."""

    def __init__(self, environ: dict | None = None, euid: int | None = None) -> None:
        self.environ = os.environ if environ is None else environ
        if euid is None:
            euid = os.geteuid() if hasattr(os, "geteuid") else 0
        self.euid = euid

    def _forced_host(self) -> str:
        return self.environ.get("SSHD_CLI_HOST", "").strip().lower()

    def uname_s(self) -> str:
        forced = self.environ.get("SSHD_CLI_UNAME", "")
        if forced:
            return forced
        try:
            return os.uname().sysname
        except AttributeError:
            return platform.system() or ""

    def is_termux(self) -> bool:
        """True for a Termux login. PREFIX must look like the Termux tree."""
        if self._forced_host() == "termux":
            return True
        if self._forced_host() in ("gitbash", "windows-cmd", "posix"):
            return False
        prefix = self.environ.get("PREFIX", "")
        if prefix and os.path.isdir(os.path.join(prefix, "bin")) and "/com.termux/" in prefix:
            return True
        if self.environ.get("TERMUX_VERSION"):
            return True
        return os.path.isdir("/data/data/com.termux/files/usr")

    def is_git_bash(self) -> bool:
        """MINGW, MSYS, UCRT, or CLANG. CYGWIN is not Git Bash."""
        if self._forced_host() == "gitbash":
            return True
        if self._forced_host() in ("termux", "windows-cmd", "posix"):
            return False
        msystem = self.environ.get("MSYSTEM", "")
        if msystem.startswith(("MINGW", "MSYS", "UCRT", "CLANG")):
            return True
        name = self.uname_s()
        return name.startswith(("MINGW", "MSYS"))

    def is_windows_cmd(self) -> bool:
        """Windows cmd after Git Bash, Cygwin, and WSL are ruled out."""
        if self._forced_host() == "windows-cmd":
            return True
        if self._forced_host() in ("termux", "gitbash", "posix"):
            return False
        if self.is_git_bash():
            return False
        if self.environ.get("WSL_DISTRO_NAME"):
            return False
        if self.uname_s().startswith("CYGWIN"):
            return False
        if self.environ.get("OS") == "Windows_NT":
            return True
        spec = self.environ.get("ComSpec", "") or self.environ.get("COMSPEC", "")
        if spec.lower().endswith("cmd.exe"):
            return True
        if self.uname_s() == "Linux":
            return False
        return False

    def normal_user_only(self) -> bool:
        return self.is_termux() or self.is_git_bash() or self.is_windows_cmd()

    def nuser_label(self) -> str:
        if self.is_termux():
            return "termux"
        if self.is_git_bash():
            return "gitbash"
        if self.is_windows_cmd():
            return "windows-cmd"
        return ""

    def is_root(self) -> bool:
        forced = self.environ.get("SSHD_CLI_EUID", "")
        if forced.isdigit():
            return int(forced) == 0
        return self.euid == 0

    def show_sudoers(self) -> bool:
        return not self.normal_user_only()

    def show_config_backup(self) -> bool:
        """POSIX Linux shows backup-config and sync-config. The other class shows sync-from-remote."""
        return not self.normal_user_only()

    def show_daemon_rows(self) -> bool:
        """Termux, Git Bash, and Windows cmd show start/stop/restart. POSIX Linux shows them for root."""
        if self.normal_user_only():
            return True
        return self.is_root()

    def os_class(self) -> str:
        """alpine, termux, or posix. Used only to comment unsupported client keywords."""
        forced = self.environ.get("SSHD_CLI_OS", "").strip().lower()
        if forced in ("alpine", "termux", "posix"):
            return forced
        if self.is_termux():
            return "termux"
        release = "/etc/os-release"
        try:
            with open(release, "r", encoding="utf-8", errors="replace") as handle:
                text = handle.read().lower()
        except OSError:
            text = ""
        if "alpine" in text:
            return "alpine"
        return "posix"

    def os_name(self) -> str:
        """Display name from os-release NAME, else uname, else Linux."""
        forced = self.environ.get("SSHD_CLI_OS_NAME", "").strip()
        if forced:
            return forced
        try:
            with open("/etc/os-release", "r", encoding="utf-8", errors="replace") as handle:
                for line in handle:
                    if line.startswith("NAME="):
                        value = line.split("=", 1)[1].strip().strip('"').strip("'")
                        if value:
                            return value
                        break
        except OSError:
            pass
        name = self.uname_s()
        return name or "Linux"

    def hidden_front(self, language: str = "en") -> str:
        label = self.nuser_label()
        patterns = {
            "zh-Hant": "sudoers 不適用於 {0}",
            "zh-Hans": "sudoers 不适用于 {0}",
            "es": "sudoers no está disponible para {0}",
            "fr": "sudoers n'est pas disponible pour {0}",
            "de": "sudoers ist nicht verfügbar für {0}",
            "ja": "sudoers は {0} では使えません",
            "ko": "sudoers 는 {0} 에서 사용할 수 없습니다",
            "ar": "sudoers غير متاح لـ {0}",
            "pt": "sudoers não está disponível para {0}",
            "ru": "sudoers недоступен для {0}",
            "nl": "sudoers is niet beschikbaar voor {0}",
            "el": "το sudoers δεν είναι διαθέσιμο για {0}",
            "en": "sudoers not available for {0}",
        }
        return patterns.get(language, patterns["en"]).format(label)

    def hidden_client(self, language: str = "en") -> str:
        label = self.nuser_label()
        patterns = {
            "zh-Hant": "backup-config 與 sync-config 不適用於 {0}",
            "zh-Hans": "backup-config 与 sync-config 不适用于 {0}",
            "es": "backup-config y sync-config no están disponibles para {0}",
            "fr": "backup-config et sync-config ne sont pas disponibles pour {0}",
            "de": "backup-config und sync-config sind nicht verfügbar für {0}",
            "ja": "backup-config と sync-config は {0} では使えません",
            "ko": "backup-config 와 sync-config 는 {0} 에서 사용할 수 없습니다",
            "ar": "backup-config وsync-config غير متاحين لـ {0}",
            "pt": "backup-config e sync-config não estão disponíveis para {0}",
            "ru": "backup-config и sync-config недоступны для {0}",
            "nl": "backup-config en sync-config zijn niet beschikbaar voor {0}",
            "el": "τα backup-config και sync-config δεν είναι διαθέσιμα για {0}",
            "en": "backup-config and sync-config not available for {0}",
        }
        return patterns.get(language, patterns["en"]).format(label)

    def hidden_server(self, language: str = "en") -> str:
        name = self.os_name()
        patterns = {
            "zh-Hant": "非 root 在 {0} 無法使用 start/stop/restart sshd",
            "zh-Hans": "非 root 在 {0} 无法使用 start/stop/restart sshd",
            "es": "las funciones start/stop/restart sshd no están disponibles sin root en {0}",
            "fr": "les fonctions start/stop/restart sshd ne sont pas disponibles hors root sur {0}",
            "de": "start/stop/restart sshd ist ohne root auf {0} nicht verfügbar",
            "ja": "root 以外は {0} で start/stop/restart sshd を使えません",
            "ko": "root가 아니면 {0} 에서 start/stop/restart sshd 를 사용할 수 없습니다",
            "ar": "ميزات start/stop/restart sshd غير متاحة لغير root في {0}",
            "pt": "as funções start/stop/restart sshd não estão disponíveis sem root em {0}",
            "ru": "функции start/stop/restart sshd недоступны без root в {0}",
            "nl": "start/stop/restart sshd is zonder root op {0} niet beschikbaar",
            "el": "οι λειτουργίες start/stop/restart sshd δεν είναι διαθέσιμες χωρίς root στο {0}",
            "en": "start/stop/restart sshd features are not available for non-root in {0}",
        }
        return patterns.get(language, patterns["en"]).format(name)
