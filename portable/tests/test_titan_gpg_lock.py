"""Isolated pam_gnupg v0.4 handoff/cache test for Titan.

Run with:
  timeout 85s python3 portable/tests/test_titan_gpg_lock.py

The fixture re-execs itself in bubblewrap with /home and /run masked, then
mounts a disposable home over the current non-root user's passwd home. The
synthetic passphrase is generated in memory and sent only via pipes/PAM
conversation. No production keyring or agent socket is visible to the fixture.
"""
from __future__ import annotations

import ctypes
import os
from pathlib import Path
import pwd
import secrets
import shutil
import subprocess
import sys
import tempfile
import unittest

PAM_GNUPG = Path(os.environ.get(
    "TITAN_PAM_GNUPG_MODULE",
    "/nix/store/iwn1gj81ynyf6nk0phjxhc7k6jkdpp5q-pam_gnupg-0.4/lib/security/pam_gnupg.so",
))
PAM_LIB = Path(os.environ.get(
    "TITAN_LIBPAM",
    "/nix/store/1a1bczcc8ihwyma22w71axkgqv70jnly-linux-pam-1.7.1/lib/libpam.so.0",
))
PAM_INCLUDE = Path(os.environ.get(
    "TITAN_PAM_INCLUDE",
    "/nix/store/1a1bczcc8ihwyma22w71axkgqv70jnly-linux-pam-1.7.1/include",
))
PAM_SERVICE = "titan-gpg-lock-fixture"

FIXTURE_PAM_MODULE = r"""
#include <security/pam_modules.h>
#include <security/pam_ext.h>
#include <string.h>

static char fixture_expected[512];

int fixture_set_expected(const char *token) {
    size_t length = strlen(token);
    if (length == 0 || length >= sizeof(fixture_expected)) return -1;
    memcpy(fixture_expected, token, length + 1);
    return 0;
}

PAM_EXTERN int pam_sm_authenticate(pam_handle_t *pamh, int flags,
                                   int argc, const char **argv) {
    const char *mode = argc ? argv[0] : "";
    if (strcmp(mode, "capture") == 0) {
        const char *token = NULL;
        return pam_get_authtok(pamh, PAM_AUTHTOK, &token, "fixture token: ");
    }
    if (strcmp(mode, "validate") == 0) {
        const void *token = NULL;
        if (pam_get_item(pamh, PAM_AUTHTOK, &token) != PAM_SUCCESS || token == NULL ||
            fixture_expected[0] == '\0') {
            return PAM_AUTH_ERR;
        }
        return strcmp((const char *) token, fixture_expected) == 0
            ? PAM_SUCCESS : PAM_AUTH_ERR;
    }
    if (strcmp(mode, "deny") == 0) {
        return PAM_AUTH_ERR;
    }
    return PAM_SERVICE_ERR;
}

PAM_EXTERN int pam_sm_setcred(pam_handle_t *pamh, int flags,
                              int argc, const char **argv) {
    return PAM_SUCCESS;
}
"""


class PamMessage(ctypes.Structure):
    _fields_ = [("msg_style", ctypes.c_int), ("msg", ctypes.c_char_p)]


class PamResponse(ctypes.Structure):
    _fields_ = [("resp", ctypes.c_void_p), ("resp_retcode", ctypes.c_int)]


PamConversation = ctypes.CFUNCTYPE(
    ctypes.c_int,
    ctypes.c_int,
    ctypes.POINTER(ctypes.POINTER(PamMessage)),
    ctypes.POINTER(ctypes.POINTER(PamResponse)),
    ctypes.c_void_p,
)


class PamConv(ctypes.Structure):
    _fields_ = [("conv", PamConversation), ("appdata_ptr", ctypes.c_void_p)]


def _resolve(name: str) -> str:
    path = shutil.which(name)
    if path is None:
        raise RuntimeError(f"required test executable unavailable: {name}")
    return str(Path(path).resolve())


def _outer_sandbox() -> int:
    """Start this test inside a namespace that hides live home and runtime."""
    if os.geteuid() == 0:
        raise RuntimeError("fixture must run as a non-root user")
    account = pwd.getpwuid(os.getuid())
    if os.getuid() != 1000 or account.pw_dir != "/home/zarred":
        raise RuntimeError("fixture requires Titan's non-root UID/home mapping")

    bwrap = shutil.which("bwrap")
    if bwrap is None:
        raise RuntimeError("bubblewrap is required; refusing an unsandboxed fixture")
    python = str(Path(sys.executable).resolve())
    tools = {
        "python": python,
        "gcc": _resolve("gcc"),
        "gpg": _resolve("gpg"),
        "gpgconf": _resolve("gpgconf"),
        "connect": _resolve("gpg-connect-agent"),
    }
    for required in (PAM_GNUPG, PAM_GNUPG.parents[2] / "libexec/pam_gnupg_helper", PAM_LIB,
                     PAM_INCLUDE / "security/pam_modules.h"):
        if not required.exists():
            raise RuntimeError(f"required pinned PAM fixture path unavailable: {required}")

    path_dirs = sorted({str(Path(value).parent) for value in tools.values()})
    path_dirs.append("/nix/store/9pabzaj57aqypqj2rs783yn77ana44h2-coreutils-full-9.8/bin")
    sandbox_path = ":".join(dict.fromkeys(path_dirs))

    with tempfile.TemporaryDirectory(prefix="titan-gpg-lock-test-") as temp:
        root = Path(temp)
        fixture_home = root / "home"
        fixture_home.mkdir(mode=0o700)
        (fixture_home / "tmp").mkdir(mode=0o700)
        runner = fixture_home / "runner.py"
        shutil.copyfile(Path(__file__).resolve(), runner)
        runner.chmod(0o400)

        command = [
            bwrap, "--die-with-parent", "--unshare-pid", "--ro-bind", "/", "/",
            "--tmpfs", "/home", "--dir", "/home/zarred",
            "--bind", str(fixture_home), "/home/zarred",
            "--tmpfs", "/run", "--dir", "/run/user", "--dir", "/run/user/1000",
            "--chmod", "0700", "/run/user/1000",
            "--proc", "/proc", "--dev", "/dev",
            "--chdir", "/home/zarred", "--clearenv",
            "--setenv", "PATH", sandbox_path,
            "--setenv", "HOME", "/home/zarred",
            "--setenv", "XDG_RUNTIME_DIR", "/run/user/1000",
            "--setenv", "TMPDIR", "/home/zarred/tmp",
            "--setenv", "LC_ALL", "C",
            "--setenv", "TITAN_PAM_GNUPG_MODULE", str(PAM_GNUPG),
            "--setenv", "TITAN_LIBPAM", str(PAM_LIB),
            "--setenv", "TITAN_PAM_INCLUDE", str(PAM_INCLUDE),
            "--setenv", "TITAN_TEST_GPG", tools["gpg"],
            "--setenv", "TITAN_TEST_GPGCONF", tools["gpgconf"],
            "--setenv", "TITAN_TEST_CONNECT", tools["connect"],
            "--setenv", "TITAN_TEST_CC", tools["gcc"],
            "--", python, "/home/zarred/runner.py", "--inside-fixture",
        ]
        try:
            result = subprocess.run(
                command, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                stderr=subprocess.PIPE, text=True, check=False, timeout=75,
            )
        except subprocess.TimeoutExpired as exc:
            raise RuntimeError("isolated fixture exceeded 75 seconds; sandbox was terminated") from exc
        # The unittest report contains only test names/statuses; child stderr and
        # all GPG/PAM subprocess diagnostics remain suppressed.
        sys.stdout.write(result.stdout)
        if result.returncode != 0:
            if not result.stdout:
                # Before Python starts, stderr can only be the sandbox launcher.
                sys.stderr.write(result.stderr)
            raise RuntimeError("bubblewrapped PAM/GPG fixture failed; child stderr suppressed")
        return result.returncode


def _inside_fixture() -> int:
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(TitanPamGnupgFixture)
    result = unittest.TextTestRunner(stream=sys.stdout, verbosity=2).run(suite)
    return 0 if result.wasSuccessful() else 1


class TitanPamGnupgFixture(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.gpg = Path(os.environ["TITAN_TEST_GPG"])
        cls.gpgconf = Path(os.environ["TITAN_TEST_GPGCONF"])
        cls.connect = Path(os.environ["TITAN_TEST_CONNECT"])
        cls.cc = Path(os.environ["TITAN_TEST_CC"])
        cls.pam_module = Path(os.environ["TITAN_PAM_GNUPG_MODULE"])
        cls.pam_lib_path = Path(os.environ["TITAN_LIBPAM"])
        cls.home = Path.home()
        cls.gnupg_home = cls.home / "gnupg"
        cls.work = cls.home / "work"
        cls.pam_dir = cls.home / "pam.d"
        cls.module_dir = cls.home / "modules"
        for directory in (cls.gnupg_home, cls.work, cls.pam_dir, cls.module_dir):
            directory.mkdir(mode=0o700)
        os.chmod(cls.gnupg_home, 0o700)
        os.chmod(cls.home, 0o700)
        os.chmod(Path("/run/user/1000"), 0o700)

        # The sandbox must not expose the real user home or user-agent sockets.
        if (cls.home / ".gnupg").exists() or (Path("/run/user/1000/gnupg")).exists():
            raise RuntimeError("sandbox exposed a live home/keyring or runtime GPG path")
        cls.env = {
            "PATH": os.environ["PATH"],
            "HOME": str(cls.home),
            "GNUPGHOME": str(cls.gnupg_home),
            "XDG_RUNTIME_DIR": "/run/user/1000",
            "LC_ALL": "C",
        }

        cls.token = secrets.token_urlsafe(32).encode("ascii")
        cls.wrong_token = secrets.token_urlsafe(32).encode("ascii")
        while cls.wrong_token == cls.token:
            cls.wrong_token = secrets.token_urlsafe(32).encode("ascii")

        config = cls.gnupg_home / "gpg-agent.conf"
        config.write_text("allow-preset-passphrase\nno-allow-external-cache\n", encoding="ascii")
        config.chmod(0o600)
        primary, auth, encryption = cls.make_test_keys()
        cls.grips = (primary["grip"], encryption["grip"], auth["grip"])
        cls.fprs = (primary["fpr"], auth["fpr"], encryption["fpr"])

        # First line selects an isolated GNUPGHOME; helper.c resolves this file
        # beneath the passwd home, which is the fixture bind mount in this namespace.
        (cls.home / ".pam-gnupg").write_text(
            str(cls.gnupg_home) + "\n" + "\n".join(cls.grips) + "\n", encoding="ascii"
        )
        (cls.home / ".pam-gnupg").chmod(0o600)
        cls.compile_auth_module()
        cls.write_pam_service()
        cls.reload_agent()
        cls.data = cls.work / "fixture-data"
        cls.data.write_bytes(b"disposable PAM cache validation\n")
        cls.ciphertext = cls.work / "fixture-ciphertext.gpg"
        cls.gpg_run(
            "--batch", "--yes", "--trust-model", "always", "--recipient",
            cls.fprs[2] + "!", "--output", str(cls.ciphertext), "--encrypt", str(cls.data),
        )

    @classmethod
    def tearDownClass(cls):
        # Both command and environment point only into the bubblewrapped fixture.
        if hasattr(cls, "gnupg_home"):
            subprocess.run(
                [str(cls.gpgconf), "--homedir", str(cls.gnupg_home), "--kill", "gpg-agent"],
                env=getattr(cls, "env", os.environ), stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                check=False, timeout=5,
            )
        cls.token = b""
        cls.wrong_token = b""

    @classmethod
    def gpg_run(cls, *args: str, input: bytes | None = None, check: bool = True):
        result = subprocess.run(
            [str(cls.gpg), "--homedir", str(cls.gnupg_home), "--no-options", *args],
            input=input, env=cls.env, stdin=None if input is not None else subprocess.DEVNULL,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            check=False, timeout=12,
        )
        if check and result.returncode != 0:
            raise RuntimeError("disposable GPG fixture operation failed")
        return result.returncode

    @classmethod
    def make_test_keys(cls):
        passphrase = cls.token + b"\n"
        cls.gpg_run(
            "--batch", "--no-tty", "--pinentry-mode", "loopback", "--passphrase-fd", "0",
            "--quick-generate-key", "Disposable Fixture <fixture@example.invalid>",
            "ed25519", "sign,cert", "0", input=passphrase,
        )
        primary_fpr = cls.secret_records()[0]["fpr"]
        cls.gpg_run(
            "--batch", "--no-tty", "--pinentry-mode", "loopback", "--passphrase-fd", "0",
            "--quick-add-key", primary_fpr, "ed25519", "sign,auth", "0", input=passphrase,
        )
        cls.gpg_run(
            "--batch", "--no-tty", "--pinentry-mode", "loopback", "--passphrase-fd", "0",
            "--quick-add-key", primary_fpr, "cv25519", "encrypt", "0", input=passphrase,
        )
        records = cls.secret_records()
        primary = next(record for record in records if record["tag"] == "sec")
        auth = next(record for record in records if record["tag"] == "ssb" and set(record["caps"].lower()) == {"s", "a"})
        encryption = next(record for record in records if record["tag"] == "ssb" and set(record["caps"].lower()) == {"e"})
        if len({primary["grip"], auth["grip"], encryption["grip"]}) != 3:
            raise RuntimeError("fixture did not create three distinct secret keygrips")
        return primary, auth, encryption

    @classmethod
    def secret_records(cls):
        result = subprocess.run(
            [str(cls.gpg), "--homedir", str(cls.gnupg_home), "--no-options", "--batch",
             "--with-colons", "--with-keygrip", "--list-secret-keys"],
            env=cls.env, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL, check=False, timeout=12,
        )
        if result.returncode != 0:
            raise RuntimeError("could not inspect disposable fixture key metadata")
        records = []
        current = None
        for line in result.stdout.decode("ascii", errors="replace").splitlines():
            fields = line.split(":")
            if fields[0] in ("sec", "ssb"):
                current = {"tag": fields[0], "fpr": "", "grip": "", "caps": fields[11] if len(fields) > 11 else ""}
                records.append(current)
            elif fields[0] == "fpr" and current is not None and not current["fpr"]:
                current["fpr"] = fields[9]
            elif fields[0] == "grp" and current is not None:
                current["grip"] = fields[9]
        if not records or any(not record["fpr"] or not record["grip"] for record in records):
            raise RuntimeError("fixture secret-key metadata was incomplete")
        return records

    @classmethod
    def compile_auth_module(cls):
        source = cls.module_dir / "fixture_pam.c"
        module = cls.module_dir / "fixture_pam.so"
        source.write_text(FIXTURE_PAM_MODULE, encoding="ascii")
        source.chmod(0o600)
        result = subprocess.run(
            [str(cls.cc), "-shared", "-fPIC", "-I", str(PAM_INCLUDE),
             "-Wl,-rpath," + str(cls.pam_lib_path.parent), "-o", str(module),
             str(source), str(cls.pam_lib_path)],
            env=cls.env, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL, check=False, timeout=20,
        )
        if result.returncode != 0:
            raise RuntimeError("could not compile credential-free PAM fixture module")
        module.chmod(0o700)
        cls.fixture_module = module
        cls.validator_module = ctypes.CDLL(str(module))

    @classmethod
    def write_pam_service(cls):
        # Mirrors Titan: optional token capture, optional pam_gnupg, sufficient
        # password validation, then a required deny fallback.
        service = cls.pam_dir / PAM_SERVICE
        service.write_text(
            "\n".join((
                f"auth optional {cls.fixture_module} capture",
                f"auth optional {cls.pam_module}",
                f"auth sufficient {cls.fixture_module} validate",
                f"auth required {cls.fixture_module} deny",
                "",
            )),
            encoding="ascii",
        )
        service.chmod(0o600)

    @classmethod
    def reload_agent(cls):
        result = subprocess.run(
            [str(cls.connect), "--no-autostart", "reloadagent", "/bye"],
            env=cls.env, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL, check=False, timeout=8,
        )
        if result.returncode != 0:
            raise RuntimeError("fixture-only reloadagent command failed")

    @classmethod
    def begin_pam(cls, supplied_token: bytes):
        libpam = ctypes.CDLL(str(cls.pam_lib_path))
        libc = ctypes.CDLL(None)
        libc.calloc.argtypes = [ctypes.c_size_t, ctypes.c_size_t]
        libc.calloc.restype = ctypes.c_void_p
        libc.strdup.argtypes = [ctypes.c_char_p]
        libc.strdup.restype = ctypes.c_void_p

        def conversation(num_msg, messages, responses, appdata):
            array = libc.calloc(num_msg, ctypes.sizeof(PamResponse))
            if not array:
                return 5  # PAM_BUF_ERR
            response_array = ctypes.cast(array, ctypes.POINTER(PamResponse))
            for index in range(num_msg):
                style = messages[index].contents.msg_style
                if style not in (1, 2):  # PAM_PROMPT_ECHO_OFF / PAM_PROMPT_ECHO_ON
                    response_array[index].resp = None
                    response_array[index].resp_retcode = 0
                    continue
                response_array[index].resp = libc.strdup(supplied_token)
                if not response_array[index].resp:
                    return 5
                response_array[index].resp_retcode = 0
            responses[0] = response_array
            return 0

        callback = PamConversation(conversation)
        conv = PamConv(callback, None)
        pamh = ctypes.c_void_p()
        libpam.pam_start_confdir.argtypes = [
            ctypes.c_char_p, ctypes.c_char_p, ctypes.POINTER(PamConv),
            ctypes.c_char_p, ctypes.POINTER(ctypes.c_void_p),
        ]
        libpam.pam_start_confdir.restype = ctypes.c_int
        libpam.pam_authenticate.argtypes = [ctypes.c_void_p, ctypes.c_int]
        libpam.pam_authenticate.restype = ctypes.c_int
        libpam.pam_setcred.argtypes = [ctypes.c_void_p, ctypes.c_int]
        libpam.pam_setcred.restype = ctypes.c_int
        libpam.pam_end.argtypes = [ctypes.c_void_p, ctypes.c_int]
        libpam.pam_end.restype = ctypes.c_int

        user = pwd.getpwuid(os.getuid()).pw_name.encode("utf-8")
        status = libpam.pam_start_confdir(
            PAM_SERVICE.encode("ascii"), user, ctypes.byref(conv),
            str(cls.pam_dir).encode(), ctypes.byref(pamh),
        )
        if status != 0:
            raise RuntimeError("pam_start_confdir failed for isolated fixture")
        cls.validator_module.fixture_set_expected.argtypes = [ctypes.c_char_p]
        cls.validator_module.fixture_set_expected.restype = ctypes.c_int
        self_status = cls.validator_module.fixture_set_expected(cls.token)
        if self_status != 0:
            libpam.pam_end(pamh, 4)
            raise RuntimeError("could not set in-memory fixture validator token")
        # Keep the callback, conversation, and token response alive through
        # pam_end; the expected token exists only in the fixture module's memory.
        return libpam, pamh, (callback, conv, supplied_token)

    def operation_works(self, kind: str) -> bool:
        if kind in ("primary", "auth"):
            fingerprint = self.fprs[0] if kind == "primary" else self.fprs[1]
            output = self.work / f"{kind}.sig"
            output.unlink(missing_ok=True)
            result = self.gpg_run(
                "--batch", "--no-tty", "--pinentry-mode", "error", "--local-user",
                fingerprint + "!", "--output", str(output), "--detach-sign", str(self.data),
                check=False,
            )
            success = result == 0 and output.is_file() and output.stat().st_size > 0
            output.unlink(missing_ok=True)
            return success
        output = self.work / "decrypted-output"
        output.unlink(missing_ok=True)
        result = self.gpg_run(
            "--batch", "--no-tty", "--pinentry-mode", "error", "--output", str(output),
            "--decrypt", str(self.ciphertext), check=False,
        )
        success = result == 0 and output.is_file() and output.read_bytes() == self.data.read_bytes()
        output.unlink(missing_ok=True)
        return success

    def assert_all_cached_and_usable(self, expected: bool):
        for kind in ("primary", "encryption", "auth"):
            with self.subTest(key_type=kind):
                self.assertEqual(self.operation_works(kind), expected)

    def test_success_only_setcred_presets_all_three_and_reload_clears(self):
        # Key generation may have populated the disposable agent; reset it before
        # assertions. This command can reach only GNUPGHOME inside bwrap.
        self.reload_agent()
        self.assert_all_cached_and_usable(False)

        # The bad token must fail PAM; the caller deliberately does not invoke
        # pam_setcred on failure. pam_end then wipes pam_gnupg's in-memory token.
        libpam, pamh, keepalive = self.begin_pam(self.wrong_token)
        try:
            auth_status = libpam.pam_authenticate(pamh, 0)
            self.assertNotEqual(auth_status, 0)
        finally:
            libpam.pam_end(pamh, auth_status)
            del keepalive
        self.assert_all_cached_and_usable(False)

        # Successful authentication itself only stores the token. Cache-backed
        # operations must still fail until the application establishes creds.
        libpam, pamh, keepalive = self.begin_pam(self.token)
        pam_end_status = 0
        try:
            auth_status = libpam.pam_authenticate(pamh, 0)
            pam_end_status = auth_status
            self.assertEqual(auth_status, 0)
            self.assert_all_cached_and_usable(False)
            setcred_status = libpam.pam_setcred(pamh, 0x0002)  # PAM_ESTABLISH_CRED
            pam_end_status = setcred_status
            self.assertEqual(setcred_status, 0)
            self.assert_all_cached_and_usable(True)
        finally:
            libpam.pam_end(pamh, pam_end_status)
            del keepalive

        # This is the documented lock-time command, still inside the private
        # mount namespace and pointed only at the disposable GNUPGHOME agent.
        self.reload_agent()
        self.assert_all_cached_and_usable(False)


def main() -> int:
    if "--inside-fixture" in sys.argv:
        return _inside_fixture()
    return _outer_sandbox()


if __name__ == "__main__":
    raise SystemExit(main())
