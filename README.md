# NixOS Configs

This repo manages NixOS hosts with a single flake.
Optionally, it bootstraps a host inside a Hetzner Cloud VM.


# Hosts

## claw-box

- Flake output: `.#claw-box`
- Host config: `hosts/claw-box/default.nix`
- `claw-box`: 🦞 VM running OpenClaw

### Users

- `root`: no password, no SSH login, no authorized keys.
- `narkatee`: SSH key-only login, passwordless sudo.
- `narkatee` keys source: `https://github.com/narkaTee.keys`
- Keys are stored in `keys/narkatee.pub`.
- `sshguard` enabled for `sshd`.

To refresh `narkatee` keys:

```bash
curl -fsSL https://github.com/narkaTee.keys > keys/narkatee.pub
```

## Hetzner Bootstrap

```bash
# upload your local public key to Hetzner (once, from file)
hcloud ssh-key create \
  --name my-laptop-file \
  --public-key-from-file ~/.ssh/id_ed25519.pub

# upload from key string (alternative)
hcloud ssh-key create \
  --name my-laptop-string \
  --public-key "<key string>"

# or whatever the context is called
hcloud context use nix
./scripts/bootstrap-hetzner.sh \
  --name claw-box-01 \
  --ssh-key my-laptop-file \
  --flake .#claw-box
```

## Update the server

```bash
nix run nixpkgs#nixos-rebuild -- \
  switch --flake .#claw-box \
  --target-host <connection> \
  --build-host <connection> \
  --sudo
```

## Update flake inputs

```bash
nix flake update
```

## Validate flake

```bash
# evaluate flake outputs shape
nix flake show "path:$PWD" --no-write-lock-file
```
