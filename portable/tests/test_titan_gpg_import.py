"""Disposable-GNUPGHOME tests for Titan's noninteractive full-key importer."""
from __future__ import annotations

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
IMPORTER = ROOT / "hosts/titan/gpg-import.sh"
GPG = shutil.which("gpg")
GPGCONF = shutil.which("gpgconf")
CONNECT = shutil.which("gpg-connect-agent")
FALSE = shutil.which("false")
TEST_PASSPHRASE = b"DUMMY-only-gpg-test-passphrase\n"

REAL_IDS = {
    "1504329BCE4AE308C2218F2CD276AC444633E146": "PRIMARY_FPR",
    "13A4FEE773790871433DF46D116C7AE1C597FBDC": "PRIMARY_GRIP",
    "5C628F1B3672EB69C75353184DB986A6D8C648AB": "AUTH_SUBKEY_FPR",
    "BEF3920E6B79FF4A4F817838844F26D1BCAE35C9": "AUTH_SUBKEY_GRIP",
    "AEFF5D4DFF9A6268273A225DDE9C7BD5CD6D499B": "ENCRYPT_SUBKEY_FPR",
    "5B32AFE33A293758C727F532FA9BD2E43A44237E": "ENCRYPT_SUBKEY_GRIP",
}


def parse_public_records(output: str) -> list[dict[str, str]]:
    records: list[dict[str, str]] = []
    current = None
    primary_fpr = ""
    for line in output.splitlines():
        fields = line.split(":")
        tag = fields[0]
        if tag in ("pub", "sec", "sub", "ssb"):
            current = {"tag": tag, "fpr": "", "grip": "", "caps": "", "parent": ""}
            if tag in ("pub", "sec"):
                records.append(current)
                primary_fpr = ""
            else:
                current["parent"] = primary_fpr
                records.append(current)
                current["caps"] = fields[11] if len(fields) > 11 else ""
        elif tag == "fpr" and current is not None and not current["fpr"]:
            current["fpr"] = fields[9]
            if current["tag"] in ("pub", "sec"):
                primary_fpr = fields[9]
        elif tag == "grp" and current is not None:
            current["grip"] = fields[9]
    return records


@unittest.skipUnless(GPG and GPGCONF and CONNECT, "GnuPG tools unavailable")
class TitanGpgImportTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="titan-gpg-import-test-")
        self.root = Path(self.tmp.name)
        self.src = self.root / "source"
        self.dst = self.root / "destination"
        self.wrong = self.root / "wrong-source"
        for home in (self.src, self.dst, self.wrong):
            home.mkdir(mode=0o700)
        if FALSE:
            (self.dst / "gpg-agent.conf").write_text(f"pinentry-program {FALSE}\n")
            (self.dst / "gpg-agent.conf").chmod(0o600)

        self.primary, self.auth, self.encryption = self.make_test_key(self.src)
        self.wrong_primary, self.wrong_auth, self.wrong_encryption = self.make_test_key(self.wrong)
        self.importer = self.root / "gpg-import-under-test"
        source = IMPORTER.read_text(encoding="utf-8")
        for actual, name in REAL_IDS.items():
            self.assertEqual(source.count(actual), 1, f"expected one production constant: {name}")
        replacements = {
            "1504329BCE4AE308C2218F2CD276AC444633E146": self.primary["fpr"],
            "13A4FEE773790871433DF46D116C7AE1C597FBDC": self.primary["grip"],
            "5C628F1B3672EB69C75353184DB986A6D8C648AB": self.auth["fpr"],
            "BEF3920E6B79FF4A4F817838844F26D1BCAE35C9": self.auth["grip"],
            "AEFF5D4DFF9A6268273A225DDE9C7BD5CD6D499B": self.encryption["fpr"],
            "5B32AFE33A293758C727F532FA9BD2E43A44237E": self.encryption["grip"],
        }
        for actual, temporary in replacements.items():
            self.assertEqual(source.count(actual), 1)
            source = source.replace(actual, temporary)
        self.importer.write_text(source, encoding="utf-8")
        self.importer.chmod(0o700)

        self.auth_only = self.root / "protected-auth-only.bin"
        self.export_secret(self.src, "--export-secret-subkeys", self.auth["fpr"] + "!", self.auth_only)
        self.full_key = self.root / "protected-full-key.bin"
        self.export_secret(self.src, "--export-secret-keys", self.primary["fpr"], self.full_key)
        # Seed only the historical auth-subkey state; the production importer
        # must upgrade it rather than refusing an available partial key.
        self.gpg(self.dst, "--batch", "--no-tty", "--pinentry-mode", "error", "--import", str(self.auth_only))

        self.wrong_key = self.root / "wrong-full-key.bin"
        self.export_secret(self.wrong, "--export-secret-keys", self.wrong_primary["fpr"], self.wrong_key)

    def tearDown(self):
        for home in (self.src, self.dst, self.wrong):
            subprocess.run(
                [GPGCONF, "--homedir", str(home), "--kill", "all"],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False, timeout=5,
            )
        self.tmp.cleanup()

    def env(self, home: Path) -> dict[str, str]:
        return {
            "PATH": os.environ.get("PATH", ""),
            "HOME": str(self.root),
            "GNUPGHOME": str(home),
            "LC_ALL": "C",
        }

    def gpg(self, home: Path, *args: str, input: bytes | None = None, check: bool = True):
        return subprocess.run(
            [GPG, "--homedir", str(home), "--no-options", *args],
            input=input, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            env=self.env(home), check=check, timeout=10,
        )

    def make_test_key(self, home: Path):
        self.gpg(
            home, "--batch", "--no-tty", "--pinentry-mode", "loopback",
            "--passphrase-fd", "0", "--quick-generate-key",
            "Disposable GPG test <test@example.invalid>", "ed25519", "cert", "0",
            input=TEST_PASSPHRASE,
        )
        records = parse_public_records(self.gpg(home, "--with-colons", "--with-keygrip", "--list-keys").stdout.decode())
        primary = next(r for r in records if r["tag"] == "pub")
        self.gpg(
            home, "--batch", "--no-tty", "--pinentry-mode", "loopback",
            "--passphrase-fd", "0", "--quick-add-key", primary["fpr"],
            "ed25519", "sign,auth", "0", input=TEST_PASSPHRASE,
        )
        self.gpg(
            home, "--batch", "--no-tty", "--pinentry-mode", "loopback",
            "--passphrase-fd", "0", "--quick-add-key", primary["fpr"],
            "cv25519", "encrypt", "0", input=TEST_PASSPHRASE,
        )
        records = parse_public_records(self.gpg(home, "--with-colons", "--with-keygrip", "--list-keys").stdout.decode())
        primary = next(r for r in records if r["tag"] == "pub")
        auth = next(r for r in records if r["tag"] == "sub" and set(r["caps"].lower()) == {"s", "a"})
        encryption = next(r for r in records if r["tag"] == "sub" and set(r["caps"].lower()) == {"e"})
        return primary, auth, encryption

    def export_secret(self, home: Path, operation: str, selector: str, destination: Path):
        with destination.open("wb") as output:
            result = subprocess.run(
                [GPG, "--homedir", str(home), "--no-options", "--batch", "--no-tty",
                 "--pinentry-mode", "loopback", "--passphrase-fd", "0", operation, selector],
                input=TEST_PASSPHRASE, stdout=output, stderr=subprocess.PIPE,
                env=self.env(home), check=False, timeout=10,
            )
        self.assertEqual(result.returncode, 0, "disposable protected test-key export failed")
        destination.chmod(0o600)

    def run_importer(self, secret: Path):
        return subprocess.run(
            [str(self.importer), str(secret)], cwd=self.root, env=self.env(self.dst),
            stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            text=True, check=False, timeout=10,
        )

    def agent_state(self, grip: str) -> str:
        result = subprocess.run(
            [CONNECT, "--homedir", str(self.dst), f"HAVEKEY {grip}", "/bye"],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
            env=self.env(self.dst), check=False, timeout=5,
        )
        if "ERR 67108881 No secret key" in result.stdout:
            return "absent"
        if result.returncode == 0 and "OK" in result.stdout:
            return "present"
        self.fail(f"unexpected disposable agent response: {result.stdout!r}")

    def test_full_protected_key_upgrades_auth_only_seed_and_is_idempotent(self):
        self.assertEqual(self.agent_state(self.primary["grip"]), "absent")
        self.assertEqual(self.agent_state(self.auth["grip"]), "present")
        self.assertEqual(self.agent_state(self.encryption["grip"]), "absent")

        first = self.run_importer(self.full_key)
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertIn("full GPG key imported", first.stdout)
        self.assertNotIn(TEST_PASSPHRASE.decode().strip(), first.stdout + first.stderr)
        self.assertEqual(self.agent_state(self.primary["grip"]), "present")
        self.assertEqual(self.agent_state(self.auth["grip"]), "present")
        self.assertEqual(self.agent_state(self.encryption["grip"]), "present")

        second = self.run_importer(self.full_key)
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertIn("already provisioned", second.stdout)
        self.assertNotIn(TEST_PASSPHRASE.decode().strip(), second.stdout + second.stderr)

    def test_wrong_full_key_metadata_is_rejected_before_import(self):
        result = self.run_importer(self.wrong_key)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("payload", result.stderr)
        self.assertEqual(self.agent_state(self.primary["grip"]), "absent")
        self.assertEqual(self.agent_state(self.auth["grip"]), "present")
        self.assertEqual(self.agent_state(self.encryption["grip"]), "absent")
        self.assertEqual(self.agent_state(self.wrong_primary["grip"]), "absent")
        public = self.gpg(self.dst, "--with-colons", "--list-keys").stdout.decode()
        self.assertNotIn(self.wrong_primary["fpr"], public)


if __name__ == "__main__":
    unittest.main()
