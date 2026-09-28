"""Mock-only orchestration tests: never invoke SSH, Nix, or installer helpers."""
import importlib.machinery
import importlib.util
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

SCRIPT = Path(__file__).parents[1] / "bin" / "titan-install-from-web"
loader = importlib.machinery.SourceFileLoader("titan_install_from_web", str(SCRIPT))
spec = importlib.util.spec_from_loader(loader.name, loader)
flow = importlib.util.module_from_spec(spec)
spec.loader.exec_module(flow)
BRANCH = "feat/portable-usb-mvp"


class CoordinatorTests(unittest.TestCase):
    def test_successful_stages_are_ordered_on_expected_branch(self):
        head = "a" * 40
        events = []
        builds = iter(["/nix/store/" + "1" * 32 + "-nixos-system-titan-test",
                       "/nix/store/" + "2" * 32 + "-disko-destroy-format-mount"])

        def build(attr, executable=False):
            events.append("build-system" if "toplevel" in attr else "build-disko")
            return next(builds)

        def importer(mode, *args):
            events.append("import-" + mode)

        def interactive(remote, token, timeout=flow.TIMEOUT):
            self.assertTrue(remote.startswith("/run/wrappers/bin/sudo "))
            events.append("format" if "--format-prebuilt" in remote else "finish")

        with (
            patch.object(flow, "local_snapshot", return_value=(BRANCH, head)),
            patch.object(flow, "remote_preflight", side_effect=[("b" * 40, "/dev/nvme0n1"), (head, "/dev/nvme0n1")]) as remote,
            patch.object(flow, "has_live_tty", return_value=True),
            patch.object(flow, "run", return_value=None),
            patch.object(flow, "sync_checkout", side_effect=lambda *a: events.append("sync")),
            patch.object(flow, "build_output", side_effect=build),
            patch.object(flow, "closure", side_effect=[(2, "c" * 64), (1, "d" * 64)]),
            patch.object(flow, "persistence_metadata", return_value=(b"metadata", "e" * 64)),
            patch.object(flow, "scp"),
            patch.object(flow, "ssh", return_value=None),
            patch.object(flow, "importer", side_effect=importer),
            patch.object(flow, "interactive_ssh", side_effect=interactive),
            patch.object(flow.sys, "argv", [str(SCRIPT)]),
        ):
            self.assertEqual(flow.main(), 0)

        self.assertEqual(events, ["sync", "build-system", "build-disko", "import-usb-store", "format",
                                  "import-ssd-store", "finish"])
        self.assertEqual([call.args[0] for call in remote.call_args_list], [BRANCH, BRANCH])

    def test_local_snapshot_accepts_only_the_actual_expected_branch(self):
        head = "a" * 40
        with patch.object(flow, "run", side_effect=[SimpleNamespace(stdout=BRANCH + "\n"),
                                                     SimpleNamespace(stdout=head + "\n"),
                                                     SimpleNamespace(stdout="")]):
            self.assertEqual(flow.local_snapshot(), (BRANCH, head))
        with patch.object(flow, "run", side_effect=[SimpleNamespace(stdout="feat/portable-usb\n"),
                                                     SimpleNamespace(stdout=head + "\n"),
                                                     SimpleNamespace(stdout="")]):
            with self.assertRaises(flow.FlowError):
                flow.local_snapshot()

    def test_ssh_never_uses_password_auth_and_remote_sudo_is_absolute(self):
        self.assertIn("BatchMode=yes", flow.SSH_OPTIONS)
        self.assertNotIn("BatchMode=no", flow.SSH_OPTIONS)
        fake_proc = SimpleNamespace(stdout=object(), poll=lambda: 0)
        digest = "c" * 64
        streamed = SimpleNamespace(stdout=f"Titan stream OK mode=usb-store paths=1 bytes=5 manifest={digest} sha256={digest}")
        with (
            patch.object(flow.subprocess, "Popen", return_value=fake_proc) as popen,
            patch.object(flow, "wait_ready"),
            patch.object(flow, "run", return_value=streamed),
            patch.object(flow, "wait_import"),
        ):
            flow.importer("usb-store", "/nix/store/" + "1" * 32 + "-disko-destroy-format-mount",
                          1, digest, "a" * 40, "random_token")
        argv = popen.call_args.args[0]
        self.assertIn("BatchMode=yes", argv)
        self.assertTrue(argv[-1].startswith("/run/wrappers/bin/sudo "))

    def test_dirty_web_refuses_before_remote_or_build(self):
        with (
            patch.object(flow, "has_live_tty", return_value=True),
            patch.object(flow, "local_snapshot", side_effect=flow.FlowError("dirty")),
            patch.object(flow, "remote_preflight") as remote,
            patch.object(flow, "build_output") as build,
            patch.object(flow.sys, "argv", [str(SCRIPT)]),
        ):
            self.assertEqual(flow.main(), 1)
        remote.assert_not_called()
        build.assert_not_called()

    def test_requires_live_tty_before_any_preflight(self):
        with (
            patch.object(flow, "has_live_tty", return_value=False),
            patch.object(flow, "local_snapshot") as snapshot,
            patch.object(flow.sys, "argv", [str(SCRIPT)]),
        ):
            self.assertEqual(flow.main(), 2)
        snapshot.assert_not_called()

    def test_usb_branch_mismatch_refuses_before_build(self):
        head = "a" * 40
        with (
            patch.object(flow, "has_live_tty", return_value=True),
            patch.object(flow, "local_snapshot", return_value=(BRANCH, head)),
            patch.object(flow, "remote_preflight", side_effect=flow.FlowError("unexpected branch")),
            patch.object(flow, "build_output") as build,
            patch.object(flow.sys, "argv", [str(SCRIPT)]),
        ):
            self.assertEqual(flow.main(), 1)
        build.assert_not_called()

    def test_bundle_uses_named_branch_ref_and_remote_ff_only_fetch(self):
        head = "a" * 40
        calls = []

        def fake_run(argv, **kwargs):
            calls.append((argv, kwargs))
            return None

        with (
            patch.object(flow, "run", side_effect=fake_run),
            patch.object(flow, "scp") as scp,
            patch.object(flow, "ssh") as ssh,
            patch.object(flow.tempfile, "mkstemp", return_value=(10, "/tmp/mock-titan.bundle")),
            patch.object(flow.os, "close"),
            patch.object(flow.Path, "unlink"),
        ):
            flow.sync_checkout(BRANCH, head, "b" * 40)

        bundle_argv = calls[1][0]
        self.assertEqual(bundle_argv[-1], f"refs/heads/{BRANCH}")
        self.assertEqual(bundle_argv[3:5], ["bundle", "create"])
        scp.assert_called_once()
        remote_script = ssh.call_args.args[0]
        self.assertIn(f'fetch "$b" refs/heads/{BRANCH}', remote_script)
        self.assertIn("merge --ff-only FETCH_HEAD", remote_script)

    def test_first_import_failure_never_formats_or_starts_second_stage(self):
        head = "a" * 40
        with (
            patch.object(flow, "has_live_tty", return_value=True),
            patch.object(flow, "local_snapshot", return_value=(BRANCH, head)),
            patch.object(flow, "remote_preflight", return_value=(head, "/dev/nvme0n1")),
            patch.object(flow, "run", return_value=None),
            patch.object(flow, "build_output", side_effect=["/nix/store/" + "1" * 32 + "-nixos-system-titan-x",
                                                               "/nix/store/" + "2" * 32 + "-disko-destroy-format-mount"]),
            patch.object(flow, "closure", side_effect=[(2, "c" * 64), (1, "d" * 64)]),
            patch.object(flow, "persistence_metadata", return_value=(b"metadata", "e" * 64)),
            patch.object(flow, "scp"),
            patch.object(flow, "ssh", return_value=None),
            patch.object(flow, "importer", side_effect=flow.FlowError("stream mismatch")) as importer,
            patch.object(flow, "interactive_ssh") as interactive,
            patch.object(flow.sys, "argv", [str(SCRIPT)]),
        ):
            self.assertEqual(flow.main(), 1)
        importer.assert_called_once()
        interactive.assert_not_called()


if __name__ == "__main__":
    unittest.main()
