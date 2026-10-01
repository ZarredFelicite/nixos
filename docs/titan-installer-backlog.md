# Titan installer integration backlog

## Workflow
- Read this file and [titan-setup-summary.md](titan-setup-summary.md) when resuming Titan work.
- Record every future setup change here: change, source/commit, verification, installer action and status.
- Accumulate changes for one deliberate all-in-one installer integration batch later; do not update the installer after each live change.
- Successful manual setup does not establish installer coverage. Mark integrated only after checking installer behavior.
- Never record passwords, private keys, tokens or decrypted secrets here. Sensitive provisioning needs explicit scope and privacy-safe handling, not blind copying.
- Keep these records in this persisted Git project, not the non-persisted top-level home directory.

## Pending integration / coverage checks

### 1. Nano keyboard configuration
- Copied full `.config/keyboard` into Titan persistence: 995 files, 22,444,952 bytes. Counts/digest/ownership/backing verified.
- Installer action: provision approved config with correct ownership/persistence; decide curated tracked seed versus approved source-host transfer at integration time.
- Status: manually applied; integration pending.

### 2. Nano OrcaSlicer configuration
- Copied full `.config/OrcaSlicer`: 1,214 files, 51,454,370 bytes; parity/ownership/backing verified.
- Installer action: provision profiles/preferences from an approved privacy-safe source. Complete folder may contain device/account settings; manual-copy approval does not permit publishing them or embedding credentials in assets.
- Status: manually applied; integration pending.

### 3. Nano PrusaSlicer configuration
- Copied full `.config/PrusaSlicer`: 99 files, 1,911,914 bytes; parity/ownership/backing verified.
- Installer action: provision approved profiles/preferences with correct ownership/persistence; review private settings before choosing tracked assets.
- Status: manually applied; integration pending.

### 4. Nano BambuStudio configuration
- Copied full `.config/BambuStudio`: 713 files, 11,515,473 bytes; parity/ownership/backing verified.
- Installer action: provision approved profiles/preferences; do not commit account/device credentials.
- Status: manually applied; integration pending.

### 5. Titan display settings
- Source/live changes: commits `4d6f4c68`, `afb2430e`; scale 1.5, VRR disabled. Live 2880×1920 at 120 Hz verified; user confirmed motion.
- Installer action: verify selected NixOS/Home Manager generation contains settings and preserves them on boot/reboot.
- Status: source/live changes exist; installer coverage needs verification. Current boot generation has older Home Manager settings. No switch/reboot approved by this backlog.

### 6. Titan → Web personal GPG SSH authentication
- Implemented/live: **full personal secret key**, including master plus encryption and authentication/signing subkeys, exported directly into `secrets/titan/gpg-key.bin`. User requested parity with other full-key computers; initial assistant-imposed auth-only restriction was corrected. Titan-only SOPS recipient and existing GPG passphrase protection retained. Runtime `/run/secrets/titan-gpg-key` is `zarred:0400`; full key imported into persisted `.gnupg`.
- Source: `.sops.yaml` exact full-key rule, import in `hosts/titan.nix`, module `hosts/titan/gpg-ssh.nix`, helper `hosts/titan/gpg-import.sh`, focused tests `portable/tests/test_titan_gpg_import.py`. User oneshot/path watcher waits for runtime availability and cannot prompt. Importer validates exact full metadata, permits master availability, supports auth-only-to-full upgrade, and requires all three private keygrips. Shared `home/security.nix` unchanged.
- Evidence: disposable protected full upgrade/import/idempotence/wrong-key tests passed; syntax/targeted eval passed. Real full import exit 0; independent master/encryption/auth Agent availability all OK; idempotent rerun passed. Agent still offers exact Web-authorized SSH fingerprint; earlier strict live SSH succeeded as Zarred. Sudo authorization invalidated and temporary SSH session closed.
- Installer action: verify source/assets include full-key ciphertext/module, SOPS precedes importer, no-loop first-boot watcher behavior, `.gnupg` persistence, and user-driven protected-key unlock. Titan host builds include the module but installer/first-boot coverage has not been exercised. Do not strip passphrase or put plaintext in Nix store/Git; full master-key provisioning is explicitly approved.
- Status: live full key/SSH configured; declarative source prepared; no installer-script edit or NixOS/HM activation. System-managed full-secret deployment/user units are not yet active; keyring persistent, manual runtime secret ephemeral. Batch installer coverage/activation pending. Hyprlock cache hooks were discussed only, not implemented.

### 7. Restrictive GPG directory permissions
- Live change: Titan persistence-backed `.gnupg` tightened from `0755` to `0700`, owner Zarred; no keyring-content inspection.
- Installer action: ensure initial persistent `.gnupg` provisioning creates/retains mode `0700` with correct owner; validate existing Home Manager/impermanence coverage before adding a redundant installer change.
- Status: live fix verified; installer directory-mode coverage pending.

### 8. Private Hyprlock PAM credential patch
- User selected a private fork and application patch, not a custom password-handling helper. Private upstream-based repo (GitHub cannot make public forks private): https://github.com/ZarredFelicite/hyprlock-private.
- Base: upstream tag `v0.9.2`, commit `c48279d1e0f0a4399b5a2d56c16f2ec677ba18f8`. Patch branch `fix/pam-gnupg-credentials`, signed commit `eae9b657929a617e7b993e557745be9f0e213376`; private review https://github.com/ZarredFelicite/hyprlock-private/pull/1.
- Change: `src/auth/Pam.cpp` calls `pam_setcred(PAM_ESTABLISH_CRED)` only after successful authentication, before `pam_end`. Credential failure logs generic status but preserves successful screen unlock. UI and authentication failure behavior unchanged.
- Evidence: actual auth-body mocked-PAM regression covers success ordering, failed authentication, and nonfatal credential errors without input logging; passed. Out-of-system pinned Nixpkgs build passed; `/nix/store/41ar253zxpayk1xhfs9hqgnmkpcc951k-hyprlock-0.9.2` imports `pam_setcred`/`pam_strerror`. No real lock test or deployment.
- Installer action: pin/build the private fork revision, ensure private-source access works during Web/bootstrap builds, and include its output in Titan's generation. Do not assume Titan GPG credentials exist before installation; do not embed access tokens in Git/Nix expressions/store.
- Deployment staging: tested package copied to Titan; matched native `pkgs.replaceDependency` outputs built without evaluating pending host configuration. Candidate system `/nix/store/zsajinm80b7fb5mliwh8lw2dr6g43lvi-nixos-system-titan-25.11.20260630.b6018f8`; candidate active HM `/nix/store/jdanslhzagskmcvqxfc3k73zcqj7xvbi-home-manager-generation`. System HM service points to the patched active configuration, avoiding transient older VRR settings. Parent verified default package/launch references and unchanged kernel/initrd/PAM paths; source proof shows `config-only` reload does not replay `exec-once`.
- Reproduction/audit: `/tmp/titan-hyprlock-active-home.nix`, `/tmp/titan-hyprlock-system.nix`, `/tmp/titan-hyprlock-manifest.txt`, `/tmp/titan-hyprlock-hyprland-proof.txt` on Web and Titan. No activation yet; Hypridle's 300-second lock listener means fresh physical Titan activity/attention is required before its config-triggered restart. Planned system `test` activation does not touch boot/EFI and will revert on reboot; persistent source/package wiring remains a later integration task.
- Rollback: original system `/nix/store/ipha2dwfb8v7ph808vd907mdvjm3rpy9-nixos-system-titan-25.11.20260630.b6018f8` in `test` mode, then original HM `/nix/store/h2pyh8y6j4h5yybncc1j5vl95qlqh00p-home-manager-generation/activate`; same attention requirements apply.
- Verification lesson: an initial parent SSH loop used zsh's special `path` variable, temporarily breaking command lookup in that shell only. No host configuration changed. Corrected explicit Bash verification with error-checked `readlink -e` assignments passed; use this pattern rather than unchecked empty-string comparisons.
- Status: patch committed/pushed; private PR open; matched runtime deployment staged and awaiting coordinated activation. Repository Actions disabled. Persistent package wiring/merge/installer integration pending.

## Follow-up integration — not yet implemented or activated

### Hyprlock/GPG cache wiring
- Research: [titan-gpg-lock-options.md](titan-gpg-lock-options.md). The application blocker is fixed in the private patch above; Titan's active locker is still unpatched.
- Remaining: make `pam_gnupg` effective in Titan's PAM stack (existing explicit `auth include login` bypasses generated direct rules), select all three full-key grips, and clear GPG Agent caches on lock through Hypridle. Validate matching passphrases and cache behavior with an independent recovery session.
- Approval boundary: user approved the private application fork/patch, not PAM-policy changes, passphrase storage, a system switch or live lock tests. Obtain required specific approval before those operations. Host-age SOPS provisioning remains separate and already works.

## Verified prerequisites — no repair indicated

### SOPS bootstrap / fresh decryption
- Both configured host-key paths exist, root-owned mode 0600. Earlier unprivileged absence checks were permission-related false negatives.
- Public fingerprint matches existing Titan pin; public conversion matches expected age recipient.
- Corrected fresh decryption passed for BOTH active YAML/binary inputs using only Titan host identity converted exactly like sops-nix; exit status 0, plaintext sent only to `/dev/null`.
- Temporary standalone `ssh-to-age` v1.3.0 is available in Titan's Nix store; no system profile changed.
- Installer already uses the correct conversion. No host-key repair or installer change currently indicated. Full future activation/reboot readiness is not established by decryption alone.

## Already integrated — batch-validation reference

### Nano-derived Quickshell baseline
- Installer commit `e325818e` on `feat/portable-usb-mvp`, Web worktree and Titan source checkout.
- `portable/bin/install-titan` seeds 191 runtime files in `portable/config/quickshell/titan-primary/primary`, pinned to Nano commit `5056dbe2e582911029921e0e70a41568d633cede`.
- Live parity/service/bar verified; installer syntax and two focused tests passed. No installer/Disko run. Ignored `.env`/secrets excluded; USB QML unchanged. Not automatic Nano synchronization.

## Future change log

| Change | Source/commit | Verification | Installer action | Status |
|---|---|---|---|---|
| Corrected SOPS diagnostic and temporary converter transfer | `/nix/store/5jbm99w5x6py300p1iq0dq9a0581zkc2-ssh-to-age-1.3.0` | SSH/age public identities match; YAML and binary fresh decryption passed, exit 0 | Existing installer uses correct conversion; no edit indicated | Diagnostic-only; no profile change |
| Restored durable summary/backlog after ephemeral home copies disappeared | These two project docs; commit `7f26f8a9` | Project directory is persistence-backed; tracked in Git | None | Operational record |
| Initial auth-only provisioning and actual Web SSH login | Commit `d8c2ac2d` | Strict SSH to Web succeeded as Zarred, exit 0 | Superseded by user-approved full-key scope below | Auth-only restriction removed |
| Full GPG key provisioning, matching other computers | Full-key ciphertext + corrected Titan module/importer/tests | Actual full import and idempotence passed; master/encryption/auth grips all available; SSH identity unchanged | Validate full-key assets/order/first-boot coverage; active generation unchanged | Live complete; activation/installer validation pending |
| GPG homedir mode `0700` | Live persisted `.gnupg` | Owner Zarred, mode `0700` | Check directory-mode coverage | Live fixed |
| Private Hyprlock credential-initialization patch | Private repo/PR above; `eae9b657929a617e7b993e557745be9f0e213376` | Mocked actual auth lifecycle passed; pinned package compile and PAM linkage verified | Pin private revision and validate PAM/keygrip/lock-cache wiring | Patch ready; not deployed |
