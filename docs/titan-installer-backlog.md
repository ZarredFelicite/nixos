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
- Current state: GPG SSH agent offers no identities; personal login fails. Public keygrip corresponds to Web authentication/signing subkey. Personal private-key availability not inspected.
- Proposed change: authentication-subkey-only SOPS ciphertext, Titan-scoped recipients, restrictive runtime secret, import as Zarred into persisted `.gnupg`, correct keygrip, verify Web authorization.
- Installer action: record actual chosen provisioning and dependencies once implemented; ensure secrets activate before importer and handle passphrase requirements without hidden boot-time prompts. Never copy master private key or put plaintext in Nix store/Git.
- Status: user asked to continue setup; no export/import/config implementation yet. Update this item as work proceeds.

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
| Restored durable summary/backlog after ephemeral home copies disappeared | These two project docs | Project directory is persistence-backed; track in Git | None | Operational record |
