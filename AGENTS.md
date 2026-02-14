# AGENTS

## Goal

Manage a NixOS hosts with a single flake.

# Hosts

| Host | Flake source | Description |
|------|--------------|-------------|
| `claw-box` | `hosts/claw-box` | vm running OpenClaw |

## Rules

- Source of truth is this repo.
- Bootstraping is for the user `scripts/bootstrap-hetzner.sh`.
- Day-2 changes deploy with `nixos-rebuild` from this flake.
- Do not configure the server manually unless break-glass debugging is required.

## Host: claw-box

### Access model

- `root` SSH login disabled.
- `narkatee` is the admin user (SSH keys + passwordless sudo).
- `narkatee` keys file: `keys/narkatee.pub` (sync from GitHub keys endpoint).
- Deploy target user should be `narkatee` with `--sudo`.
