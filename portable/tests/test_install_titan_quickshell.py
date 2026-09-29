"""Static regression checks for Titan's persisted Quickshell seed."""
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = (ROOT / "portable/bin/install-titan").read_text()


class TitanQuickshellSeedTests(unittest.TestCase):
    def test_installer_seeds_nano_snapshot_not_portable_usb_config(self):
        self.assertIn(
            "primary_source=$flake/portable/config/quickshell/titan-primary/primary",
            SCRIPT,
        )
        self.assertIn("primary_dest=$persist_home/.config/quickshell/primary", SCRIPT)
        self.assertIn('cp -a -- "$primary_source" "$primary_dest"', SCRIPT)
        self.assertNotIn(
            "primary_source=$flake/portable/config/quickshell/primary\n", SCRIPT
        )

    def test_nano_runtime_snapshot_keeps_entrypoints_and_excludes_ancillary_files(self):
        snapshot = ROOT / "portable/config/quickshell/titan-primary/primary"
        self.assertTrue((snapshot / "shell.qml").is_file())
        self.assertTrue((snapshot / "config.qml").is_file())
        self.assertFalse((snapshot / ".env").exists())
        self.assertFalse((snapshot / ".env.example").exists())
        files = [path.relative_to(snapshot).as_posix() for path in snapshot.rglob("*") if path.is_file()]
        self.assertEqual(len(files), 191)
        self.assertFalse(any(path.endswith((".md", ".qml.bak")) for path in files))
        self.assertFalse(any(path.startswith("tests/") for path in files))
        self.assertNotIn(".gitignore", files)
        self.assertNotIn("modules/bar/popouts/patch_scrollview.py", files)
        self.assertNotIn("quickshell-popout.png", files)
        self.assertTrue((ROOT / "portable/config/quickshell/primary/config.qml").is_file())


if __name__ == "__main__":
    unittest.main()
