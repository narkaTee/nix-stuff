# NixOS Configs

This repo manages NixOS hosts with a single flake.
Optionally, it bootstraps a host inside a Hetzner Cloud VM.

## Secret management

Create an age key on your management machine:

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt
```

Copy the printed `age1...` recipient into `secrets/.sops.yaml` as `user_local` and
include it in `creation_rules`.

Then edit/re-encrypt the secret files:

```bash
./scripts/update-secrets secrets/claw-box.yaml
./scripts/update-secrets secrets/claw-shared.yaml
./scripts/update-secrets secrets/claw-workstation.yaml
```

## WireGuard keys

Generate a new keypair for each host and one shared PSK:

```bash
mkdir -p /tmp/wg-rotate

wg genkey | tee /tmp/wg-rotate/claw-box.key | wg pubkey > /tmp/wg-rotate/claw-box.pub
wg genkey | tee /tmp/wg-rotate/claw-workstation.key | wg pubkey > /tmp/wg-rotate/claw-workstation.pub
wg genpsk > /tmp/wg-rotate/openclaw.psk
```

Put values in secrets:

- `secrets/claw-box.yaml`: `wireguard_claw_box_private_key` from `/tmp/wg-rotate/claw-box.key`
- `secrets/claw-workstation.yaml`: `wireguard_claw_workstation_private_key` from `/tmp/wg-rotate/claw-workstation.key`
- `secrets/claw-shared.yaml`: `wireguard_openclaw_preshared_key` from `/tmp/wg-rotate/openclaw.psk`

Update peer public keys in config:

- `hosts/claw-box/default.nix`: set peer `publicKey` to `/tmp/wg-rotate/claw-workstation.pub`
- `hosts/claw-workstation/default.nix`: set peer `publicKey` to `/tmp/wg-rotate/claw-box.pub`

Rotate (small tunnel interruption while both hosts converge):

```bash
nix run nixpkgs#nixos-rebuild -- switch --flake .#claw-box --target-host <claw-box> --build-host <claw-box> --sudo
nix run nixpkgs#nixos-rebuild -- switch --flake .#claw-workstation --target-host <claw-workstation> --build-host <claw-workstation> --sudo
```

Verify:

```bash
ssh claw-box 'sudo -n wg show wg-openclaw'
ssh claw-workstation 'sudo -n wg show wg-openclaw'
```

## Update keys

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

## Generic Modules

### User: narkatee

Path: `modules/users/narkatee.nix`

The user account used to manage machines.

Key points:

- SSH key-only login
- passwordless sudo, full system access
- user manager can run without active login session (`linger = true`)
- `narkatee` keys source: `https://github.com/narkaTee.keys`
- Keys are stored in `keys/narkatee.pub`.

### User: openclaw

Path: `modules/users/openclaw.nix`

Dedicated runtime account for the OpenClaw gateway and its mutable state.

Key points:

- no password login by default (host-specific overrides can set one)
- no SSH authorized keys
- user services can run without active login session (`linger = true`)
- runtime state is stored in `/home/openclaw/.openclaw`

### Base module

Path: `modules/base.nix`

Applies the baseline OS hardening and boot settings for remote hosts.

Key points:

- SSH installed
- no root login
- secure ssh defaults
- sshguard protects sshd service
- host firewall enabled (default deny), only `22/tcp` allowed
- inbound ping disabled
- `root`: no password, no SSH login, no authorized keys
- enables `nix-command` and `flakes`
- configures GRUB for `/dev/sda` EFI boot

### Disko module

Path: `modules/disko.nix`

Defines the disk partitioning and filesystems used during bootstrap install.

Key points:

- GPT layout on `/dev/sda`
- 1M BIOS partition (`EF02`)
- 1G EFI system partition mounted at `/boot`
- ext4 root filesystem mounted at `/`

### SOPS module (gateway)

Path: `modules/secrets/sops.nix`

Declares encrypted secrets and renders runtime environment variables for OpenClaw.

Key points:

- uses `secrets/claw-box.yaml` as default SOPS file
- decrypts with host SSH age key (`/etc/ssh/ssh_host_ed25519_key`)
- loads gateway-host secrets from `secrets/claw-box.yaml`
- loads shared secrets (`openclaw_gateway_token`, `wireguard_openclaw_preshared_key`) from `secrets/claw-shared.yaml`
- renders `OPENCLAW_GATEWAY_TOKEN`, `ANTHROPIC_API_KEY`, and `BRAVE_API_KEY`

### SOPS module (node)

Path: `modules/secrets/node.nix`

Declares minimal secrets for a node host that connects to a remote gateway.

Key points:

- uses `secrets/claw-workstation.yaml` as default SOPS file
- decrypts with host SSH age key (`/etc/ssh/ssh_host_ed25519_key`)
- loads shared secrets (`openclaw_gateway_token`, `wireguard_openclaw_preshared_key`) from `secrets/claw-shared.yaml`
- loads workstation-host secrets from `secrets/claw-workstation.yaml`
- installs `user_openclaw_password` from `secrets/claw-workstation.yaml` with `neededForUsers = true`
- renders `OPENCLAW_GATEWAY_TOKEN` for node host auth

### OpenClaw gateway module

Path: `modules/openclaw.nix`

Configures Home Manager and the OpenClaw gateway service for host `claw-box`.

Key points:

- enables `nix-openclaw` overlay and Home Manager for `openclaw`
- runs one `instances.default` gateway in local mode with token auth
- gateway listens on `lan` so remote nodes can connect
- opens `18789/tcp` only on interface `wg-openclaw` (not publicly)
- Telegram bot auth uses SOPS token file and `dmPolicy = "pairing"`
- gateway environment is sourced from rendered SOPS template
- gateway restarts automatically on secrets file changes

### OpenClaw node module

Path: `modules/openclaw-node.nix`

Configures a headless OpenClaw node host service for `claw-workstation`.

Key points:

- enables `nix-openclaw` overlay and Home Manager for `openclaw`
- sets `gateway.mode = "remote"` in OpenClaw config
- disables local `openclaw-gateway` user service on workstation
- runs `openclaw node run` as a user service (`openclaw-node-host`)
- injects `OPENCLAW_CONFIG_PATH` for node runtime browser settings (default profile `openclaw`, explicit Chromium path on NixOS)
- uses SOPS-rendered `OPENCLAW_GATEWAY_TOKEN` to authenticate to `claw-box`

### Workstation desktop module

Path: `modules/workstation-desktop.nix`

Enables KDE Plasma and xrdp for workstation hosts.

Key points:

- enables SDDM + Plasma 6
- keeps Wayland available for local desktop logins
- enables xrdp for remote desktop sessions
- does not open firewall for RDP
- xrdp session command is `dbus-run-session startplasma-x11`

# Hosts

## claw-box

A VM running OpenClaw 🦞

- Flake output: `.#claw-box`
- Host config: `hosts/claw-box/default.nix`

### Security Model

- management user `narkatee`
- OpenClaw runtime user `openclaw`
- `openclaw` has no SSH login and no password login
- operations run as `narkatee` and switch user via `sudo -iu openclaw` when needed
- WireGuard link `wg-openclaw` is used for node-to-gateway traffic
- public ingress is limited to `22/tcp` and `51820/udp`; gateway `18789/tcp` is tunnel-only

Operational note:
- use `sudo -iu openclaw` (login shell), not plain `sudo -u openclaw`, for `openclaw` CLI commands; non-login shells can miss gateway auth env and fail with auth/token errors

### OpenClaw on claw-box

- OpenClaw module: `modules/openclaw.nix`
- Home Manager user: `openclaw`
- Runtime state path: `/home/openclaw/.openclaw` (self-managed on host)

#### Telegram setup

1. Create bot with `@BotFather`:
   - send `/newbot`
   - pick name + username
   - copy bot token
2. Edit secrets file:

```bash
./scripts/update-secrets secrets/claw-box.yaml
```

In the editor set:
- in `secrets/claw-box.yaml`:
  - `openclaw_telegram_token`
  - `openclaw_anthropic_api_key`
  - `openclaw_brave_search_token` (enables `web_search` via `BRAVE_API_KEY`)
  - `wireguard_claw_box_private_key`
- in `secrets/claw-shared.yaml`:
  - `openclaw_gateway_token` (use `openssl rand -hex 32`)
  - `wireguard_openclaw_preshared_key`

Apply changes with nix run.

#### Telegram access control (no chat ID in git)

`claw-box` uses `channels.telegram.dmPolicy = "pairing"` so no `allowFrom` list is stored in the repo.

After deploy:

1. Message your bot once from the Telegram account you want to allow.
2. On the server, list pending pairing requests:

```bash
ssh claw-box 'sudo -iu openclaw openclaw pairing list telegram'
```

3. Approve the code:

```bash
ssh claw-box 'sudo -iu openclaw openclaw pairing approve telegram <CODE>'
```

Approved IDs are stored on-host under `/home/openclaw/.openclaw/credentials/telegram-allowFrom.json`.

#### Verify OpenClaw

```bash
ssh claw-box 'sudo -n systemctl --machine=openclaw@.host --user status openclaw-gateway --no-pager'
ssh claw-box 'sudo -n journalctl --machine=openclaw@.host --user-unit openclaw-gateway -n 100 --no-pager'
```

Then message your bot again from the approved account.

Encrypted secrets files:
- `secrets/claw-box.yaml`
- `secrets/claw-shared.yaml`
- `secrets/claw-workstation.yaml`
- SOPS config: `secrets/.sops.yaml`

If the VM is reprovisioned (new SSH host key), update `secrets/.sops.yaml`
recipient and re-encrypt with `scripts/update-secrets`.

## OpenClaw State Backup

Back up OpenClaw runtime state from the backup host in pull mode:

```bash
scripts/claw-backup claw-box /ssd-pool/backup/claw-box/
```

Restore to a (re)provisioned host:

```bash
scripts/claw-restore /ssd-pool/backup/claw-box/ claw-box
```

## claw-workstation

A workstation VM running KDE Plasma + xrdp and a headless OpenClaw node host.

- Flake output: `.#claw-workstation`
- Host config: `hosts/claw-workstation/default.nix`
- Desktop module: `modules/workstation-desktop.nix`
- OpenClaw node module: `modules/openclaw-node.nix`

OpenClaw behavior on this host:

- no Telegram/provider secrets are installed here
- only `openclaw_gateway_token` is materialized
- `openclaw-node-host` user service connects to `10.77.0.1:18789` over `wg-openclaw`
- this host does not run the OpenClaw gateway service
- browser control is configured via service-level `OPENCLAW_CONFIG_PATH` (not `~/.openclaw/openclaw.json`, which is self-managed runtime state)
- browser config pins `browser.defaultProfile = "openclaw"` and `browser.executablePath = "/run/current-system/sw/bin/chromium-browser"` to avoid `No supported browser found` / Chrome extension relay mismatch errors
- required decrypted secrets:
  - from `secrets/claw-shared.yaml`: `openclaw_gateway_token`, `wireguard_openclaw_preshared_key`
  - from `secrets/claw-workstation.yaml`: `wireguard_claw_workstation_private_key`, `user_openclaw_password`

Set `user_openclaw_password` to a password hash (not plaintext):

```bash
nix shell nixpkgs#mkpasswd -c mkpasswd -m yescrypt
```

Node pairing (from `claw-box`):

```bash
ssh claw-box 'sudo -iu openclaw openclaw devices list'
ssh claw-box 'sudo -iu openclaw openclaw devices approve <REQUEST_ID>'
ssh claw-box 'sudo -iu openclaw openclaw nodes status'
```

Verify node host service (on `claw-workstation`):

```bash
ssh claw-workstation 'sudo -n systemctl --machine=openclaw@.host --user status openclaw-node-host --no-pager'
ssh claw-workstation 'sudo -n journalctl --machine=openclaw@.host --user-unit openclaw-node-host -n 100 --no-pager'
ssh claw-workstation 'sudo -n systemctl --machine=openclaw@.host --user show openclaw-node-host -p Environment | grep OPENCLAW_CONFIG_PATH'
```

Verify WireGuard:

```bash
ssh claw-box 'sudo -n wg show wg-openclaw'
ssh claw-workstation 'sudo -n wg show wg-openclaw'
```

RDP is not opened on the firewall. Use an SSH tunnel:

```bash
ssh -N -L 13389:127.0.0.1:3389 narkatee@claw-workstation
```

Then connect your RDP client to `127.0.0.1:13389`.
