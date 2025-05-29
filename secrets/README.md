# Secrets

This directory contains encrypted secrets managed using sops-nix. Sensitive information, such as API keys or passwords, should be stored in encrypted files within this directory and decrypted at build time by NixOS. Refer to the sops-nix documentation for details on how to manage these secrets.
