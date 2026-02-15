# AGENTS

## Goal

Manage NixOS hosts with a single flake.

## Hosts

| Host | Flake source | Description |
|------|--------------|-------------|
| `claw-box` | `hosts/claw-box/default.nix` | VM running OpenClaw |

## Modules

| Module | Path | Purpose |
|--------|------|---------|
| Base | `modules/base.nix` | Baseline host hardening and boot defaults |
| Disko | `modules/disko.nix` | Disk layout and filesystems |
| User `narkatee` | `modules/users/narkatee.nix` | Admin user, SSH keys, sudo policy |
| User `openclaw` | `modules/users/openclaw.nix` | Runtime user for OpenClaw state/service |
| SOPS | `modules/secrets/sops.nix` | Secrets and rendered runtime env |
| OpenClaw | `modules/openclaw.nix` | OpenClaw + Home Manager host setup |

## Additional Paths

- Bootstrap script: `scripts/bootstrap-hetzner.sh`
- Secret editor: `scripts/update-secrets`
- Backup script: `scripts/claw-backup`
- Restore script: `scripts/claw-restore`
- Encrypted secrets: `secrets/claw-box.yaml`
- OpenClaw runtime state: `/home/openclaw/.openclaw`

## Documentation

- `README.md` is the detailed source for module behavior and operations.
- See `README.md` sections: `Generic Modules` and `claw-box`.

## Rules

- Source of truth is this repo.
- Bootstrap new vms with `scripts/bootstrap-hetzner.sh`.
- Day-2 changes deploy from this flake
- Build must happen on the remote node for any host via `--build-host <host>` (or by running `nixos-rebuild` directly on `<host>`).
- Do not configure the server manually unless break-glass debugging is required.
- Deploy as `narkatee` with `--sudo`.
