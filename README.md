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

Then re-encrypt the secret file:

```bash
./scripts/update-secrets secrets/claw-box.yaml
```

```bash
./scripts/update-secrets secrets/<file>.yaml
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

- no password login
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

### SOPS module

Path: `modules/secrets/sops.nix`

Declares encrypted secrets and renders runtime environment variables for OpenClaw.

Key points:

- uses `secrets/claw-box.yaml` as default SOPS file
- decrypts with host SSH age key (`/etc/ssh/ssh_host_ed25519_key`)
- installs OpenClaw secrets with mode `0400` for user `openclaw`
- renders `OPENCLAW_GATEWAY_TOKEN`, `ANTHROPIC_API_KEY`, and `BRAVE_API_KEY`

### OpenClaw module

Path: `modules/openclaw.nix`

Configures Home Manager and the OpenClaw gateway service for host `claw-box`.

Key points:

- enables `nix-openclaw` overlay and Home Manager for `openclaw`
- runs one `instances.default` gateway in local mode with token auth
- Telegram bot auth uses SOPS token file and `dmPolicy = "pairing"`
- gateway environment is sourced from rendered SOPS template
- gateway restarts automatically on secrets file changes

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
- `openclaw_telegram_token`
- `openclaw_gateway_token` (use `openssl rand -hex 32`)
- `openclaw_anthropic_api_key`
- `openclaw_brave_search_token` (enables `web_search` via `BRAVE_API_KEY`)

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

Encrypted secrets file:
- `secrets/claw-box.yaml`
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
