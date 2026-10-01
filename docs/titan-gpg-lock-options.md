# GPG lock/unlock with Hyprlock: implementation options

Research completed 2026-09-30. Subsequently the user chose the private-fork compatibility patch: https://github.com/ZarredFelicite/hyprlock-private/pull/1, commit `eae9b657929a617e7b993e557745be9f0e213376` based on v0.9.2. The patch and focused tests/build are complete; it was subsequently runtime-deployed on Titan without a lock test. Shared Nix package pin and Titan boot-only persistence were subsequently completed; PAM/cache wiring remains pending. No lock hooks, PAM changes or passphrase storage were applied. See [titan-installer-backlog.md](titan-installer-backlog.md) for implementation state; the alternatives below record the research findings before that choice.

## Goal and current state

Keep Titan's full personal GPG key, but clear unlocked-key caches when the screen locks and unlock them automatically after successful Hyprlock authentication. A single-password handoff assumes the login password matches the passphrase protecting each selected GPG component; matching has not been verified here.

SOPS provision/import is separate: Titan's host SSH-to-age identity decrypts the protected full-key export, which is imported into persistent `.gnupg`. Clearing the personal GPG cache does not disable host-key SOPS decryption. Importing again on each screen unlock would not solve the passphrase requirement.

## Verified findings

1. **Hypridle has the required events:** `on_lock_cmd` and `on_unlock_cmd` [1]. They supply an event, not the password entered into Hyprlock.
2. **GPG presetting is supported:** the existing `home/security.nix` enables `allow-preset-passphrase`. Presetting can use stdin; credentials must never be placed in arguments, environment variables, temporary files or logs. GPG's documentation says preset caches can be cleared by reloading the agent [3].
3. **`pam_gnupg` exists in pinned NixOS 25.11**, and `profiles/common.nix` already sets `security.pam.services.hyprlock.gnupg.enable = true`.
4. **That flag is not an effective direct Hyprlock hook today.** The explicit PAM text evaluates to `auth include login`; the active `/etc/pam.d/hyprlock` has that same include and no direct `pam_gnupg` rule. The text override bypasses the generated per-service rules. This does not by itself describe every rule in the included login stack.
5. **The installed locker lacks the required credential step.** `pam-gnupg` explicitly requires screen lockers to call `pam_setcred` after authentication [2]. The actual Titan artifact `/nix/store/74c2dwiyd4ds8cdadi8rx0kkxmxm2jbw-hyprlock-0.9.2/bin/hyprlock` imports `pam_authenticate`, `pam_start` and `pam_end`, but has no `pam_setcred` import or runtime lookup string. The source-selected 0.9.2 artifact was checked separately with the same result. Evidence is binary inspection, not a fetched source-body review: raw source retrieval timed out.
6. **Only one grip is currently in `.pam-gnupg`.** A full-key handoff needs the master, encryption and authentication/signing grips, not just SSH authentication. This must be overridden for Titan only, not silently propagated to other hosts.

## Alternatives

| Method | Keep existing Hyprlock binary? | Extra passphrase storage? | Trade-off |
|---|---|---|---|
| Titan-only PAM auth helper → GPG preset | Yes | No | Best fit for the stated preference, but custom credential handling and authentication ordering need implementation/testing. |
| Small Hyprlock compatibility patch + existing `pam_gnupg` | No; UI can stay unchanged | No | Reuses the purpose-built module instead of a custom password handler. Must add the credential call after successful authentication and correct the PAM text override. |
| Hypridle unlock hook + SOPS/keyring-stored passphrase | Yes | Yes | Straightforward event-driven presetting, but introduces a recoverable passphrase outside GPG Agent. Cache clearing alone does not prevent a same-user process reading/reusing it while locked. Requires explicit approval of that different behavior. |
| Clear cache on lock; prompt on first GPG/SSH use | Yes | No | Simplest supported fallback, but does not meet automatic one-prompt unlocking. |

GNOME Keyring/external Pinentry caching is another possible storage-backed route, not a verified drop-in solution. It needs its own lock/unlock integration, and both caches must be cleared/locked together. The current agent explicitly sets `no-allow-external-cache`, so introducing it would change existing policy. No supported turnkey Hyprlock/GPG recipe was established for that route.

## Implementation plan without changing Hyprlock

1. **Titan-only PAM handoff:** design an app-specific authentication hook using PAM's authentication token and `pam_exec expose_authtok`, or a purpose-built auth-phase module. Feed the token directly to the correct user's GPG preset helper over stdin; never pass it through an unlock shell hook, argv, environment or disk.
2. **Preserve authentication:** review the actual `auth include login` stack first. The helper must not replace password validation, run after a failed authentication, or bypass existing authentication methods. Do not append an untested snippet: PAM success short-circuiting and failure control matter. Use a separate prototype service before changing Hyprlock's service.
3. **Agent target:** use Zarred's existing user agent/socket and preset all three expected grips:
   - Master: `13A4FEE773790871433DF46D116C7AE1C597FBDC`
   - Encryption: `5B32AFE33A293758C727F532FA9BD2E43A44237E`
   - Authentication/signing: `BEF3920E6B79FF4A4F817838844F26D1BCAE35C9`
4. **Lock hook:** add a Titan-only Hypridle `on_lock_cmd` that reloads GPG Agent (`gpgconf --reload gpg-agent`) to clear cached passphrases. Existing `no-allow-external-cache` avoids a separate external cache immediately recalling them. No import/deletion on unlock/lock.
5. **Keep provisioning separate:** retain the existing SOPS full-key declaration and idempotent importer. Neither needs to run on every screen event.

The PAM helper is a feasible architecture, not a completed or validated implementation. It requires explicit approval of a **Titan-specific PAM authentication change**. If a small invisible application patch is acceptable instead, `pam_gnupg` plus the missing credential call is a cleaner alternative to custom password handling.

## Validation and rollback before activation

- Use disposable protected GPG keys and an isolated PAM prototype. Verify successful/failed authentication ordering, correct UID/socket targeting, all three cache entries, and absence of credential output/files.
- Verify both normal GPG operations and SSH signing prompt after cache clearing and work after a successful password handoff. Presetting a wrong password must not count as a successful GPG unlock.
- Keep an independent recovery SSH/TTY session open while testing the actual locker. Ask for the user's attention before a real lock/unlock test.
- Compare effective PAM policy before/after, then activate only with explicit approval. Rollback removes the Titan-specific hook/override and restores the prior PAM text; no key deletion or password rotation is involved.
- Clearing caches does not erase persisted keys or terminate already-established SSH sessions. This feature gates new protected-key use, not existing sessions.

## Sources

1. Hypridle hooks: https://wiki.hypr.land/Hypr-Ecosystem/hypridle/
2. Maintained `pam-gnupg` README, especially screen-locker credential requirements: https://github.com/cruegge/pam-gnupg
3. GnuPG preset helper: https://www.gnupg.org/documentation/manuals/gnupg/gpg_002dpreset_002dpassphrase.html
4. GnuPG agent control/reload: https://www.gnupg.org/documentation/manuals/gnupg26/gpgconf.1.html
5. Local evidence: `profiles/common.nix:290–299`, `home/security.nix:47–70`, targeted Nix evaluation of `nixosConfigurations.titan.config.security.pam.services.hyprlock.text`, active Titan PAM file, and `readelf -Ws`/`strings` inspection of its exact binary. No secrets were inspected or authentication-policy changes made during research.
