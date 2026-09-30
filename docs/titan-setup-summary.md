# Titan setup summary

## Overall goal
Make the installed Titan desktop match Nano except for disk/hardware differences, then make the all-in-one Titan SSD installer reproduce the completed setup. Record future live changes in [titan-installer-backlog.md](titan-installer-backlog.md) and integrate them into the installer together later.

## Completed setup
- Titan live Quickshell was restored from Nano's tracked commit `5056dbe2e582911029921e0e70a41568d633cede`; tracked parity, QML startup, service and bar rendering were checked. Ignored `.env` and secrets were not copied; Nano was not modified. Not every widget/popout was tested.
- Installer commit `e325818e` on `feat/portable-usb-mvp` seeds 191 runtime files from `portable/config/quickshell/titan-primary/primary`. USB QML stayed unchanged. Syntax and two focused tests passed; no installer/Disko operation was run. This is a pinned snapshot, not automatic Nano synchronization.
- Complete Nano app configs were copied into Titan's persistence-backed `.config`: keyboard (995 files / 22,444,952 bytes), OrcaSlicer (1,214 / 51,454,370), PrusaSlicer (99 / 1,911,914), BambuStudio (713 / 11,515,473). Counts, bytes, aggregate digests, ownership and backing matched. User approved copying complete slicer settings; private settings were not disclosed. Nano was read-only and applications were not restarted.
- Titan display settings (commits `4d6f4c68`, `afb2430e`): 2880×1920 at 120 Hz, scale 1.5, VRR off; live behavior verified and user confirmed motion. Boot-time generation references older Home Manager settings, so reboot coverage remains unverified. Do not reboot to test without coordination.

## Current task: personal GPG SSH authentication via sops-nix
- Titan reaches Web over Tailscale, but Zarred's GPG SSH agent offers no identities and `ssh web` fails public-key authentication. No default personal SSH private-key files were found. Private GPG keyring contents were not inspected, so personal secret-key absence is not established.
- The separate root-owned SOPS `nixremote-private` key authenticates remote builds as `nixremote`, not Zarred's personal login.
- `home/security.nix` selects keygrip `BEF3920E6B79FF4A4F817838844F26D1BCAE35C9`. Public metadata on Web confirms it corresponds to an authentication/signing (`sa`) subkey, key ID `4DB986A6D8C648AB`. Persistence of `.gnupg` alone does not provision that subkey.
- User asked to continue GPG provisioning; planned scope is the authentication-capable subkey only, NOT the master private key. No private-key export/import, ciphertext asset or provisioning config has yet been implemented.
- Intended design: Titan-scoped SOPS ciphertext in Git; restrictive runtime ownership/permissions; import as Zarred into persisted `.gnupg`; verify the intended SSH identity and Web authorization. Check GPG export/import passphrase behavior before implementing unattended import. Never put plaintext private keys in Git, the Nix store, tool output, or logs.

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
- Diagnostic TTY: Herdr pane `wB:pFX` below parent `wB:p8V` in tab `wB:t7J`; tmux session `titan-sops-converted-check`. Corrected check completed and SSH exited. Revalidate IDs before reuse; do not control unrelated panes. CLI `--current` once resolved another UI pane despite injected IDs, so verify returned context and use explicit owned IDs when necessary.
- User-facing interactive prompts belong in a downward split of the agent's current Herdr tab, not a separate Kitty window. Warn/TTS before authentication. User asked to stop repeatedly asking for attention during the current coordinated prompt workflow; announce and show prompts correctly.
- Never Disko/reinstall, rotate host keys, bypass SSH pins, change EFI/bootloader, reboot, or blindly switch systems. Keep Nano read-only; no personal secret disclosures or unrelated private-data inspection.
- Global AGENTS update `6efb54f` explicitly covers current-tab Herdr prompts and mistake cause/impact/prevention suggestions. The original wrong Kitty prompt was cancelled without changes.

## Durable records
The original `/home/zarred/titan-*.md` files disappeared from the non-persisted top-level home location. Restored summary/backlog live here in the persisted Git project. Continue updating these files rather than ephemeral top-level home copies.
