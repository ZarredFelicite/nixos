"""Mock-only tests for install-titan's read-only post-install ESP verifier."""
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = (ROOT / "portable/bin/install-titan").read_text()
START = 'python3 - "$1" "$2" <<\'PY\'\n'
END = "\nPY\n}"
VERIFIER = SCRIPT.split(START, 1)[1].split(END, 1)[0]
SYSTEM = "/nix/store/" + "a" * 32 + "-nixos-system-titan-test"


class TitanBootVerifierTests(unittest.TestCase):
    def test_persist_var_parents_are_guarded_before_wifi_provisioning(self):
        helper = SCRIPT.split("ensure_persist_var() {\n", 1)[1].split("\n}\n\nensure_user_persistence_home()", 1)[0]
        self.assertIn('[[ ! -L $directory && ( ! -e $directory || -d $directory ) ]]', helper)
        self.assertIn('install -d -o 0 -g 0 -m 0755', helper)
        self.assertIn('$(stat -c %u:%g -- "$directory") == 0:0', helper)
        self.assertIn('(8#$mode & 0022) == 0', helper)
        self.assertNotIn("sbctl", helper)
        self.assertLess(SCRIPT.index("ensure_persist_var\n"), SCRIPT.index('provision-titan-wifi'))

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.boot = Path(self.temp.name) / "boot"
        for directory in ("EFI/BOOT", "EFI/systemd", "EFI/nixos", "loader/entries"):
            (self.boot / directory).mkdir(parents=True, exist_ok=True)
        loader = b"mock systemd-boot EFI binary"
        (self.boot / "EFI/BOOT/BOOTX64.EFI").write_bytes(loader)
        (self.boot / "EFI/systemd/systemd-bootx64.efi").write_bytes(loader)
        (self.boot / "EFI/nixos/kernel.efi").write_bytes(b"mock kernel")
        (self.boot / "EFI/nixos/initrd").write_bytes(b"mock initrd")
        (self.boot / "loader/loader.conf").write_text("default titan.conf\ntimeout 3\n")
        self.entry = self.boot / "loader/entries/titan.conf"
        self.entry.write_text(
            "title Titan\nversion 1\nlinux /EFI/nixos/kernel.efi\n"
            "initrd /EFI/nixos/initrd\noptions quiet init=" + SYSTEM + "/init\n"
        )

    def run_verifier(self):
        return subprocess.run(
            ["python3", "-c", VERIFIER, str(self.boot), SYSTEM],
            text=True, capture_output=True, check=False,
        )

    def test_accepts_default_type1_entry_for_installed_system(self):
        result = self.run_verifier()
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_rejects_wrong_default_system_init(self):
        self.entry.write_text(self.entry.read_text().replace(SYSTEM, SYSTEM + "-other"))
        self.assertNotEqual(self.run_verifier().returncode, 0)

    def test_rejects_symlinked_kernel(self):
        kernel = self.boot / "EFI/nixos/kernel.efi"
        kernel.unlink()
        kernel.symlink_to(self.boot / "EFI/nixos/initrd")
        self.assertNotEqual(self.run_verifier().returncode, 0)

    def test_rejects_default_entry_that_does_not_exist(self):
        (self.boot / "loader/loader.conf").write_text("default absent.conf\n")
        self.assertNotEqual(self.run_verifier().returncode, 0)


if __name__ == "__main__":
    unittest.main()
