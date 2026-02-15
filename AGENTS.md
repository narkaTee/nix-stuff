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
| SOPS | `modules/secrets/sops.nix` | Secrets and rendered runtime env |
| OpenClaw | `modules/openclaw.nix` | OpenClaw + Home Manager host setup |

## Additional Paths

- Bootstrap script: `scripts/bootstrap-hetzner.sh`
- Secret editor: `scripts/update-secrets`
- Encrypted secrets: `secrets/claw-box.yaml`
- OpenClaw docs: `openclaw-documents/{AGENTS.md,SOUL.md,TOOLS.md}`

## Documentation

- `README.md` is the detailed source for module behavior and operations.
- See `README.md` sections: `Generic Modules` and `claw-box`.

## Rules

- Source of truth is this repo.
- Bootstrap new vms with `scripts/bootstrap-hetzner.sh`.
- Day-2 changes deploy with `nixos-rebuild` from this flake.
- Do not configure the server manually unless break-glass debugging is required.
- Deploy as `narkatee` with `--sudo`.
