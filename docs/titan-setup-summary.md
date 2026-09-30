# Titan setup summary

## Overall goal
Make the installed Titan desktop match Nano except for disk/hardware differences, then make the all-in-one Titan SSD installer reproduce the completed setup. Record future live changes in [titan-installer-backlog.md](titan-installer-backlog.md) and integrate them into the installer together later.

## Completed setup
- Titan live Quickshell was restored from Nano's tracked commit `5056dbe2e582911029921e0e70a41568d633cede`; tracked parity, QML startup, service and bar rendering were checked. Ignored `.env` and secrets were not copied; Nano was not modified. Not every widget/popout was tested.
- Installer commit `e325818e` on `feat/portable-usb-mvp` seeds 191 runtime files from `portable/config/quickshell/titan-primary/primary`. USB QML stayed unchanged. Syntax and two focused tests passed; no installer/Disko operation was run. This is a pinned snapshot, not automatic Nano synchronization.
- Complete Nano app configs were copied into Titan's persistence-backed `.config`: keyboard (995 files / 22,444,952 bytes), OrcaSlicer (1,214 / 51,454,370), PrusaSlicer (99 / 1,911,914), BambuStudio (713 / 11,515,473). Counts, bytes, aggregate digests, ownership and backing matched. User approved copying complete slicer settings; private settings were not disclosed. Nano was read-only and applications were not restarted.
- Titan display settings (commits `4d6f4c68`, `afb2430e`): 2880×1920 at 120 Hz, scale 1.5, VRR off; live behavior verified and user confirmed motion. Boot-time generation references older Home Manager settings, so reboot coverage remains unverified. Do not reboot to test without coordination.

## Current task: personal GPG SSH authentication via sops-nix
- **Resolved live:** Titan's GPG SSH agent now offers the intended authentication subkey, and a strict Titan → Web SSH test succeeded as `zarred` (`TITAN_TO_WEB_AUTH_OK user=zarred host=web`, exit 0). Previously the agent offered no identities and personal login failed.
- The separate root-owned SOPS `nixremote-private` key authenticates remote builds as `nixremote`, not Zarred's personal login.
- `home/security.nix` selects keygrip `BEF3920E6B79FF4A4F817838844F26D1BCAE35C9`. Public metadata on Web confirms it corresponds to an authentication/signing (`sa`) subkey, key ID `4DB986A6D8C648AB`. Persistence of `.gnupg` alone does not provision that subkey.
- **Full key now provisioned**, matching the user's other computers. The initial auth-only scope was an incorrect assistant-imposed restriction and was replaced at the user's request. Exported `--export-secret-keys 1504329BCE4AE308C2218F2CD276AC444633E146` (primary plus both subkeys) on Web directly through SOPS into `secrets/titan/gpg-key.bin`. Exactly Titan's age recipient; no PGP/shared recipients. Existing GPG passphrase protection retained; no plaintext export file or plaintext in Git/Nix store/logs.
- Titan-only source: anchored `.sops.yaml` rule; `hosts/titan/gpg-ssh.nix` declares binary `titan-gpg-key`, owner `zarred`, mode `0400`, with matching user importer/path watcher. `hosts/titan/gpg-import.sh` validates exact primary/auth/encryption metadata and full key set, permits full master-key availability, forbids pinentry and verifies all three keygrips after import. Shared GPG settings and installer script unchanged.
- Focused disposable-key tests passed for protected auth-only-to-full upgrade, noninteractive import, full availability, idempotence and wrong-key rejection. Bash/Nix syntax, targeted evaluation and Titan-only recipient-rule checks passed; no full builds.
- Decrypted only on Titan into `/run/secrets/titan-gpg-key`, owner `zarred`, group `users`, mode `0400`, then imported as Zarred into persistence-backed `.gnupg` (mode `0700`). Full import exited 0; actual idempotent rerun reported already provisioned.
- Independently verified GPG Agent `HAVEKEY`: **master, encryption subkey and authentication/signing subkey all available**. SSH fingerprint remains `SHA256:RvSNusv4+f+hxgcpVak3I//A67ER7KSL+/zb8tfCutI`, matching Web's authorized key. No private contents or passphrases printed.
- User unlocked the protected subkey in the lower Herdr TTY. A small signing check wrote its signature only to `/dev/null`; then strict SSH authenticated successfully to Web at `100.64.1.150` with a verified host-key pin. Ordinary future use may require GPG passphrase unlocking again after cache expiry.
- **Activation caveat:** live secret/import were applied narrowly without NixOS switch or Home Manager activation. The new declarative SOPS secret and user units are source-ready, NOT part of Titan's current active generation. Imported key persists; manual runtime secret does not survive reboot/next managed-secret replacement. Coordinate future activation/installer validation separately.

## SOPS prerequisite: verified
- Earlier unprivileged checks falsely treated host-key paths as absent because `/persist/etc/ssh` is root-owned mode 0700.
- Privileged metadata confirmed `/persist/etc/ssh/ssh_host_ed25519_key` and `/etc/ssh/ssh_host_ed25519_key` exist, root-owned mode 0600 (399 bytes); both public files exist mode 0644.
- Public host fingerprint matches the existing pin: `SHA256:yk9ounQX5uMFS8nwjj099ZvAdxfgInaWgjjgyLxAaZc`.
- Public conversion matches Titan age recipient: `age1nzlr59275d22ma4j3kecf2pmf46rq24mvldmlpgunt0ukw8gu9kq54g32w`.
- First decryption test incorrectly used SOPS native SSH identities, which is not the active sops-nix SSH-to-age conversion. Its failure was inconclusive.
- Corrected test used matching `ssh-to-age` v1.3.0 via `SOPS_AGE_KEY_CMD`; BOTH active YAML and binary encrypted inputs decrypted successfully to `/dev/null`, exit status 0. No plaintext was printed/saved; no activation, keys or secret files changed.
- Temporary converter on Web/Titan: `/nix/store/5jbm99w5x6py300p1iq0dq9a0581zkc2-ssh-to-age-1.3.0/bin/ssh-to-age`. Copied into the Nix store only, not installed into a system profile.
- Active system: `/nix/store/ipha2dwfb8v7ph808vd907mdvjm3rpy9-nixos-system-titan-25.11.20260630.b6018f8`.
- Active SOPS manifest: `/nix/store/c53xyp5ikv5gcx0zivawg5amybb73b6m-manifest.json`; 31 secrets / two encrypted inputs. Sole age SSH key path is the persisted Titan host key. No alternative age key file or GPG home.
- Inputs: `/nix/store/1zjw9v011nrx1l43am9j6kgs48p7w3xi-secrets.yaml` (yaml) and `/nix/store/hk3s8raxyzvil7a121jmk1rp28kdqjg8-twitch-api-token.json` (binary).
- This proves fresh decryption, NOT all future activation/reboot behavior. No missing-key repair is needed.

## Access, prompts and safety
- Current strict SSH config `/tmp/titan-ssd-ssh-config` uses Tailscale `100.75.251.42`, alias `titan-ssd`, HostKeyAlias `titan`, existing `/home/zarred/.ssh/known_hosts`, strict checking and no host-key updates. Its pin was independently verified. Temporary files may disappear; reconstruct only from existing trusted public identity, never bypass checks.
- Diagnostic TTY: Herdr pane `wB:pFX` below parent `wB:p8V` in tab `wB:t7J`; tmux session `titan-sops-converted-check`. All setup/verification commands completed, sudo cache was explicitly invalidated, and the temporary SSH session was closed. No password was shared/stored or sudo policy changed. Revalidate IDs before reuse; do not control unrelated panes. CLI `--current` once resolved another UI pane despite injected IDs, so verify returned context and use explicit owned IDs when necessary.
- User-facing interactive prompts belong in a downward split of the agent's current Herdr tab, not a separate Kitty window. Warn/TTS before authentication. User asked to stop repeatedly asking for attention during the current coordinated prompt workflow; announce and show prompts correctly.
- Never Disko/reinstall, rotate host keys, bypass SSH pins, change EFI/bootloader, reboot, or blindly switch systems. Keep Nano read-only; no personal secret disclosures or unrelated private-data inspection.
- Global AGENTS update `6efb54f` explicitly covers current-tab Herdr prompts and mistake cause/impact/prevention suggestions. The original wrong Kitty prompt was cancelled without changes.

## Hyprlock integration (private patch ready; not deployed)
Research: [titan-gpg-lock-options.md](titan-gpg-lock-options.md). User chose a private fork/application patch. Private upstream-based repository https://github.com/ZarredFelicite/hyprlock-private preserves the upstream v0.9.2 history/license. Branch `fix/pam-gnupg-credentials`, signed commit `eae9b657929a617e7b993e557745be9f0e213376`, private PR https://github.com/ZarredFelicite/hyprlock-private/pull/1. Local checkout `/home/zarred/dev/hyprlock-private`.

The patch calls `pam_setcred(PAM_ESTABLISH_CRED)` after successful authentication and before `pam_end`; failed authentication never sets credentials, and optional credential errors do not block successful unlock. Actual-auth-body mocked-PAM regression and out-of-system pinned-package compilation passed; compiled artifact imports the new PAM call. No UI changes, runtime deployment, real lock test or PAM changes. Actions disabled in the new repository to avoid unrequested CI; publishing used existing SSH credentials with a repo-local transport override, without expanding OAuth scopes.

Remaining wiring: pin the private patched package; make `pam_gnupg` effective despite explicit `auth include login`; configure all three keygrips; add Hypridle lock-time cache clearing and recovery-backed tests. User approved the source fork/patch only; PAM authentication changes, system activation and live lock tests still require specific approval/attention. No passphrase storage was introduced. Host-age SOPS decryption is independent of this personal GPG cache.

## Scope correction lesson
The assistant optimized only for SSH and imposed an auth-only secret-key restriction, failing the user's requested parity with other full-key computers. User explicitly requested the full key and the restriction was removed. Prevention suggestion for AGENTS/workflow: match the reference host's requested capabilities/security model; do not silently narrow them based on an inferred threat model. Instruction files were not edited for this suggestion.

## Runtime publication lesson
A first runtime-secret publication attempt failed because `/run/secrets.d` is on a separate memory filesystem and the hardlink staging file was under `/run`. It cleaned up without publishing a secret. The corrected attempt staged within the destination directory and succeeded. Prevention suggestion: atomic secret-write staging must use the destination filesystem; do not add that instruction to skills/AGENTS without approval.

## Durable records
The original `/home/zarred/titan-*.md` files disappeared from the non-persisted top-level home location. Restored summary/backlog live here in the persisted Git project. Continue updating these files rather than ephemeral top-level home copies.
