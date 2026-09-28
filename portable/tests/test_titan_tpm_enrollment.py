#!/usr/bin/env python3
"""Focused policy tests for Titan's guarded TPM enrollment (no device access)."""
import json
import re
import shutil
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INSTALL = (ROOT / "portable/bin/install-titan").read_text()
HELPER = (ROOT / "portable/bin/titan-enroll-tpm").read_text()


def run_jq(expression: str, data: dict) -> bool:
    result = subprocess.run(
        ["jq", "-e", expression], input=json.dumps(data), text=True,
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False,
    )
    return result.returncode == 0


class TitanTpmPolicy(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not shutil.which("jq"):
            raise unittest.SkipTest("jq unavailable")
        cls.preflight = re.search(
            r"if jq -e '([^']+)' <<< \"\$metadata\"", HELPER, re.S
        ).group(1)
        cls.postflight = re.search(
            r"metadata=\$\(cryptsetup luksDump --dump-json-metadata \"\$part\"\).*?jq -e '\n(.*?)\n' <<< \"\$metadata\"",
            HELPER, re.S,
        ).group(1)
        cls.pcr_row = re.search(
            r"grep -Eiq '([^']+)' <<< \"\$pcr_measurement\"", HELPER
        ).group(1)

    def test_existing_tpm_token_refuses_enrollment(self):
        no_token = {"tokens": {}, "keyslots": {"0": {}}}
        existing = {"tokens": {"0": {"type": "systemd-tpm2"}}, "keyslots": {"0": {}}}
        self.assertTrue(run_jq(self.preflight, no_token))
        self.assertFalse(run_jq(self.preflight, existing))

    def test_only_pcr7_no_pin_new_slot_and_passphrase_slot_pass(self):
        good = {
            "keyslots": {"0": {}, "1": {}},
            "tokens": {"0": {
                "type": "systemd-tpm2", "keyslots": ["1"],
                "tpm2-pcrs": [7], "tpm2-pin": None,
            }},
        }
        self.assertTrue(run_jq(self.postflight, good))
        no_pin_field = json.loads(json.dumps(good))
        del no_pin_field["tokens"]["0"]["tpm2-pin"]
        self.assertTrue(run_jq(self.postflight, no_pin_field))
        string_pcr = json.loads(json.dumps(good))
        string_pcr["tokens"]["0"]["tpm2-pcrs"] = "7"
        self.assertTrue(run_jq(self.postflight, string_pcr))
        bad_slot = json.loads(json.dumps(good))
        bad_slot["tokens"]["0"]["keyslots"] = ["0"]
        self.assertFalse(run_jq(self.postflight, bad_slot))
        bad_pcr = json.loads(json.dumps(good))
        bad_pcr["tokens"]["0"]["tpm2-pcrs"] = "7+11"
        self.assertFalse(run_jq(self.postflight, bad_pcr))
        bad_pin = json.loads(json.dumps(good))
        bad_pin["tokens"]["0"]["tpm2-pin"] = True
        self.assertFalse(run_jq(self.postflight, bad_pin))

    def test_pcr7_table_row_requires_64_hex_digest(self):
        valid = "NR NAME SHA256\n7 secure-boot-policy " + "f" * 64 + "\n"
        pcr11_only = "NR NAME SHA256\n11 kernel-boot " + "a" * 64 + "\n"
        for output, expected in ((valid, True), (pcr11_only, False)):
            result = subprocess.run(
                ["grep", "-Eiq", self.pcr_row], input=output, text=True,
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False,
            )
            self.assertEqual(result.returncode == 0, expected)

    def test_call_is_after_signed_fallback_verification_and_never_wipes(self):
        verify = INSTALL.index('sbverify --cert "$pki_cert" "$mount_root/boot/EFI/BOOT/BOOTX64.EFI"')
        enroll = INSTALL.index('titan-enroll-tpm" /dev/disk/by-id/')
        self.assertLess(verify, enroll)
        self.assertNotIn("--wipe-slot", HELPER)
        self.assertNotIn("timeout ", HELPER)
        self.assertIn("--tpm2-pcrs=7", HELPER)
        self.assertIn("--tpm2-with-pin=no", HELPER)
        self.assertIn("systemd-analyze pcrs 7", HELPER)
        self.assertNotIn("tpm2_pcrread", HELPER)
        self.assertIn('cmp -s -- "$usb_backup" "$ssd_backup"', HELPER)
        self.assertIn("--header-backup-file", HELPER)


if __name__ == "__main__":
    unittest.main()
