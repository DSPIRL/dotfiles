#!/usr/bin/env python3
"""Exercise setup with fake Flatpak deployments; never change live overrides."""
import json
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "dot_local/bin/executable_setup-zen-keepassxc"


@unittest.skipIf(os.geteuid() == 0, "setup must run as a normal desktop user")
class ZenSetupTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="zen setup test ")
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.bin = self.home / "bin"
        self.bin.mkdir()
        self.app = self.home / "app deployment"
        self.runtime = self.home / "runtime deployment"
        proxy = self.app / "active/files/bin/keepassxc-proxy"
        proxy.parent.mkdir(parents=True)
        proxy.write_text("#!/bin/sh\nexit 0\n")
        proxy.chmod(0o700)
        (self.runtime / "active/files").mkdir(parents=True)
        (self.app / "active/metadata").write_text("[Application]\nruntime=org.test.Runtime/x86_64/1\n")
        desktop = self.home / "native.desktop"
        desktop.write_text("[Desktop Entry]\nExec=keepassxc\n")
        # Only substitute the distro-owned launcher path in the fixture copy.
        self.script = self.home / "setup"
        self.script.write_text(SCRIPT.read_text().replace(
            "native_desktop=/usr/share/applications/$keepass.desktop",
            f"native_desktop={json.dumps(str(desktop))}",
        ))
        fake = self.bin / "flatpak"
        fake.write_text('''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
home = Path(os.environ["HOME"])
a = sys.argv[1:]
with (home / "calls").open("a") as out:
    out.write(json.dumps(a) + "\\n")
if a[:2] == ["info", "--show-location"]:
    print(home / ("app deployment" if a[2] == "org.keepassxc.KeePassXC" else "runtime deployment") / "commit")
elif a[:2] == ["info", "--show-runtime"]:
    print("org.test.Runtime/x86_64/1")
elif a[0] == "ps":
    if (home / "running").exists(): print("app.zen_browser.zen")
elif a[0] == "run":
    print("--app-path --usr-path")
elif a[:3] == ["override", "--user", "--show"]:
    print("[Context]\\nfilesystems=xdg-download;")
''')
        fake.chmod(0o700)
        keepass = self.bin / "keepassxc"
        keepass.write_text("#!/bin/sh\nexit 0\n")
        keepass.chmod(0o700)
        runtime = self.home / "run"
        sockpath = runtime / "app/org.keepassxc.KeePassXC/org.keepassxc.KeePassXC.BrowserServer"
        sockpath.parent.mkdir(parents=True)
        self.sock = socket.socket(socket.AF_UNIX)
        self.sock.bind(str(sockpath))
        self.addCleanup(self.sock.close)
        self.env = dict(os.environ, HOME=str(self.home), XDG_RUNTIME_DIR=str(runtime),
                        XDG_DATA_HOME=str(self.home / "data"), PATH=f"{self.bin}:{os.environ['PATH']}")
        self.target = self.home / ".var/app/app.zen_browser.zen"

    def run_setup(self):
        return subprocess.run(["bash", str(self.script)], env=self.env, text=True, capture_output=True)

    def test_configuration_and_backup(self):
        result = self.run_setup()
        self.assertEqual(result.returncode, 0, result.stderr)
        manifest = self.target / ".mozilla/native-messaging-hosts/org.keepassxc.keepassxc_browser.json"
        data = json.loads(manifest.read_text())
        self.assertEqual(data["allowed_extensions"], ["keepassxc-browser@keepassxc.org"])
        self.assertNotIn("allowed_origins", data)
        wrapper = Path(data["path"])
        self.assertEqual(wrapper.stat().st_mode & 0o777, 0o700)
        subprocess.run(["bash", "-n", str(wrapper)], check=True)
        calls = [json.loads(line) for line in (self.home / "calls").read_text().splitlines()]
        grants = next(a for a in calls if "--persist=.mozilla/native-messaging-hosts" in a)
        self.assertIn("--no-talk-name=org.freedesktop.Flatpak", grants)
        self.assertIn(f"--filesystem={self.app}:ro", grants)
        self.assertIn(f"--filesystem={self.runtime}:ro", grants)
        self.assertIn("--filesystem=xdg-run/app/org.keepassxc.KeePassXC:ro", grants)
        command = wrapper.read_text().split("exec /usr/bin/flatpak-spawn", 1)[1]
        self.assertNotIn("--host", command)
        self.assertIn('-- /app/bin/keepassxc-proxy "$@"', command)
        launcher = self.home / "data/applications/org.keepassxc.KeePassXC.desktop"
        self.assertTrue(launcher.is_symlink())
        # Rerun preserves the previous manifest and wrapper in a new backup.
        self.assertEqual(self.run_setup().returncode, 0)
        backups = list((self.target / "config/keepassxc").glob("keepassxc-backup.*"))
        self.assertTrue(any((b / manifest.name).exists() for b in backups))
        # A runtime branch change fails before starting any proxy.
        (self.app / "active/metadata").write_text("runtime=org.test.Runtime/x86_64/2\n")
        result = subprocess.run(["bash", str(wrapper)], env=self.env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("runtime changed", result.stderr)

    def test_missing_socket_is_rejected_before_writes(self):
        (self.home / "run/app/org.keepassxc.KeePassXC/org.keepassxc.KeePassXC.BrowserServer").unlink()
        result = self.run_setup()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("enable Settings > Browser Integration", result.stderr)
        self.assertFalse(self.target.exists())

    def test_running_browser_is_rejected_before_writes(self):
        (self.home / "running").touch()
        result = self.run_setup()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Close Zen completely", result.stderr)
        self.assertFalse(self.target.exists())


if __name__ == "__main__":
    unittest.main()
