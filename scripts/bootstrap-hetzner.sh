#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<USAGE
Usage:
  $0 \
    --name <server-name> \
    --ssh-key <hcloud-ssh-key-name-or-id> \
    --flake <flake-ref> \
    [--type cx23] \
    [--location nbg1]

Required:
  --name             Hetzner server name
  --ssh-key          SSH key configured in Hetzner Cloud
  --flake            Nix flake reference (for example: .#claw-box)

Notes:
  - Auth: either export HCLOUD_TOKEN or use a configured hcloud context.
  - The flake host should match --flake.
USAGE
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing command: $1" >&2
    exit 1
  fi
}

need_value() {
  if [[ $# -lt 2 || -z "${2:-}" || "${2:0:1}" == "-" ]]; then
    echo "Missing value for $1" >&2
    usage
    exit 1
  fi
}

SERVER_NAME=""
SSH_KEY=""
SERVER_TYPE="cx23"
LOCATION="nbg1"
FLAKE_REF=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)
      need_value "$@"
      SERVER_NAME="$2"
      shift 2
      ;;
    --ssh-key)
      need_value "$@"
      SSH_KEY="$2"
      shift 2
      ;;
    --type)
      need_value "$@"
      SERVER_TYPE="$2"
      shift 2
      ;;
    --location)
      need_value "$@"
      LOCATION="$2"
      shift 2
      ;;
    --flake)
      need_value "$@"
      FLAKE_REF="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$SERVER_NAME" || -z "$SSH_KEY" || -z "$FLAKE_REF" ]]; then
  usage
  exit 1
fi

need_cmd hcloud
need_cmd nix
need_cmd ssh
need_cmd nc

if hcloud server describe "$SERVER_NAME" >/dev/null 2>&1; then
  echo "Server already exists: $SERVER_NAME" >&2
  exit 1
fi

echo "Creating server $SERVER_NAME"
hcloud server create \
  --name "$SERVER_NAME" \
  --type "$SERVER_TYPE" \
  --image "debian-13" \
  --location "$LOCATION" \
  --ssh-key "$SSH_KEY" >/dev/null

echo "Enabling rescue mode"
hcloud server enable-rescue "$SERVER_NAME" --type linux64 --ssh-key "$SSH_KEY" >/dev/null
hcloud server reboot "$SERVER_NAME" >/dev/null

SERVER_IP="$(hcloud server ip "$SERVER_NAME")"
TARGET="root@$SERVER_IP"
SSH_OPTS=(
  -o BatchMode=yes
  -o UserKnownHostsFile=/dev/null
  -o StrictHostKeyChecking=no
  -o ConnectTimeout=5
)

echo "Waiting for SSH on $SERVER_IP"
for _ in $(seq 1 120); do
  if nc -z "$SERVER_IP" 22 >/dev/null 2>&1; then
    if ssh "${SSH_OPTS[@]}" "$TARGET" true >/dev/null 2>&1; then
      break
    fi
  fi
  sleep 2
done

if ! ssh "${SSH_OPTS[@]}" "$TARGET" true >/dev/null 2>&1; then
  echo "SSH did not become ready in time" >&2
  exit 1
fi

echo "Installing NixOS with nixos-anywhere"
nix --extra-experimental-features "nix-command flakes" run github:nix-community/nixos-anywhere -- \
  --flake "$FLAKE_REF" \
  --ssh-option StrictHostKeyChecking=no \
  --ssh-option UserKnownHostsFile=/dev/null \
  "$TARGET"

echo "Disabling rescue mode and rebooting"
hcloud server disable-rescue "$SERVER_NAME" >/dev/null
hcloud server reboot "$SERVER_NAME" >/dev/null

echo "Done. Server: $SERVER_NAME IP: $SERVER_IP"
