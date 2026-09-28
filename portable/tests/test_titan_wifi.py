"""Isolated tests for USB-to-encrypted-iwd Wi-Fi provisioning; DUMMY PSKs only."""
import importlib.machinery
import importlib.util
import configparser
import io
from pathlib import Path
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from unittest.mock import patch

SCRIPT = Path(__file__).parents[1] / "bin" / "provision-titan-wifi"
loader = importlib.machinery.SourceFileLoader("provision_titan_wifi", str(SCRIPT))
spec = importlib.util.spec_from_loader(loader.name, loader)
wifi = importlib.util.module_from_spec(spec)
loader.exec_module(wifi)
DUMMY = "DUMMY-passphrase-123"
UUID = "test-wifi-uuid"


class WifiProvisionTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.nm = self.root / "nm"
        self.nm.mkdir()
        self.nm.chmod(0o700)
        self.iwd = self.root / "persist" / "var" / "lib" / "iwd"
        self.iwd.mkdir(parents=True)
        self.iwd.chmod(0o700)
        self.keyfile = self.nm / "home.nmconnection"
        self.write_profile()
        self.owner_patch = patch.object(wifi, "root_owned", return_value=True)
        self.owner_patch.start()
        self.owner_stat_patch = patch.object(wifi, "root_owned_stat", return_value=True)
        self.owner_stat_patch.start()
        self.chown_patch = patch.object(wifi.os, "chown")
        self.chown_patch.start()

    def tearDown(self):
        self.chown_patch.stop()
        self.owner_stat_patch.stop()
        self.owner_patch.stop()
        self.tmp.cleanup()

    def write_profile(self, ssid="Lab WiFi", psk=DUMMY, uuid=UUID, mode=0o600, kind="802-11-wireless"):
        self.keyfile.write_text(
            f"[connection]\nuuid={uuid}\ntype={kind}\n"
            f"[wifi]\nssid={ssid}\n[wifi-security]\nkey-mgmt=wpa-psk\npsk={psk}\n"
        )
        self.keyfile.chmod(mode)

    def nmcli(self, active=True):
        records = []
        for path in sorted(self.nm.glob("*.nmconnection")):
            parser = configparser.ConfigParser(interpolation=None)
            with path.open(encoding="utf-8") as f:
                parser.read_file(f)
            records.append(f"{parser.get('connection', 'uuid')}:{parser.get('connection', 'type')}")

        def call(args):
            if args == ["-g", "UUID,TYPE", "connection", "show"]:
                return records
            if args == ["-g", "UUID,TYPE", "connection", "show", "--active"]:
                return [f"{UUID}:{records[0].split(':', 1)[1]}"] if active else []
            raise AssertionError("unexpected nmcli invocation")
        return call

    def run_provision(self, active=True):
        return wifi.provision(self.nm, self.iwd, self.nmcli(active))

    def test_active_profile_copied_atomically_without_output_leak(self):
        stdout, stderr = io.StringIO(), io.StringIO()
        original_nm = wifi.NM_DIR
        try:
            wifi.NM_DIR = self.nm
            wifi.IWD_DIR = self.iwd
            with patch.object(wifi, "run_nmcli", side_effect=self.nmcli()):
                with redirect_stdout(stdout), redirect_stderr(stderr):
                    self.assertEqual(wifi.main(), 0)
        finally:
            wifi.NM_DIR = original_nm
        self.assertNotIn(DUMMY, stdout.getvalue() + stderr.getvalue())
        result = self.iwd / "Lab WiFi.psk"
        self.assertEqual(result.read_text(), "[Settings]\nAutoConnect=true\n\n[Security]\nPassphrase=" + DUMMY + "\n")
        self.assertEqual(result.stat().st_mode & 0o777, 0o600)

    def test_ambiguous_stored_profiles_fail_closed(self):
        other = self.nm / "other.nmconnection"
        other.write_text(self.keyfile.read_text().replace(UUID, "other-uuid"))
        other.chmod(0o600)
        with self.assertRaises(wifi.ProvisionError):
            self.run_provision(active=False)
        self.assertEqual(list(self.iwd.iterdir()), [])

    def test_wrong_or_missing_key_fails_without_writing(self):
        self.write_profile(psk="short")
        with self.assertRaises(wifi.ProvisionError):
            self.run_provision()
        self.assertEqual(list(self.iwd.iterdir()), [])
        self.write_profile(psk="")
        with self.assertRaises(wifi.ProvisionError):
            self.run_provision()

    def test_inactive_ambiguous_or_missing_supported_profile_fails(self):
        self.write_profile(psk="short")
        with self.assertRaises(wifi.ProvisionError):
            self.run_provision(active=False)
        self.assertEqual(list(self.iwd.iterdir()), [])

    def test_missing_iwd_directory_is_created_inside_persistence(self):
        self.iwd.rmdir()
        self.run_provision()
        self.assertTrue((self.iwd / "Lab WiFi.psk").is_file())

    def test_unsafe_keyfile_and_destination_are_rejected(self):
        self.keyfile.chmod(0o644)
        with self.assertRaises(wifi.ProvisionError):
            self.run_provision()
        self.keyfile.chmod(0o600)
        dest = self.iwd / "Lab WiFi.psk"
        dest.symlink_to(self.keyfile)
        with self.assertRaises(wifi.ProvisionError):
            self.run_provision()

    def test_wifi_type_alias_is_supported(self):
        self.write_profile(kind="wifi")
        self.run_provision()
        self.assertTrue((self.iwd / "Lab WiFi.psk").is_file())

    def test_passphrase_escapes_leading_spaces_and_backslashes(self):
        self.write_profile(psk="  DUMMY\\pass-123")
        self.run_provision()
        result = self.iwd / "Lab WiFi.psk"
        self.assertIn(r"Passphrase=\s\sDUMMY\\pass-123" + "\n", result.read_text())

    def test_nonportable_ssid_is_hex_encoded_and_raw_key_uses_psk_field(self):
        self.write_profile(ssid="Café/Net", psk="A" * 64)
        self.run_provision()
        result = self.iwd / ("=" + "Café/Net".encode().hex() + ".psk")
        self.assertIn("PreSharedKey=" + "A" * 64, result.read_text())


if __name__ == "__main__":
    unittest.main()
