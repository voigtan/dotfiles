#!/usr/bin/env zsh
# ==============================================================================
# neomutt-pass.sh
# Encrypt and decrypt NeoMutt account passwords using an ssh-ed25519 key
# held in the KeePassXC SSH Agent.
#
# When KeePassXC is locked, the key is not in the SSH agent and passwords
# cannot be decrypted.
# ==============================================================================

set -euo pipefail

NEOMUTT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/neomutt"
SECRETS_DIR="${NEOMUTT_SECRETS_DIR:-$NEOMUTT_DIR/secrets}"
PUBKEY_FILE="${NEOMUTT_SSH_PUBKEY:-$SECRETS_DIR/agent.pub}"

usage() {
  cat <<'EOF'
Usage:
  neomutt-pass.sh init               Select/save an ssh-ed25519 public key from the active SSH agent
  neomutt-pass.sh check              Verify KeePassXC SSH agent is unlocked and key is ready
  neomutt-pass.sh set <account>      Prompt for <account>'s password and encrypt it
  neomutt-pass.sh get <account>      Decrypt and print <account>'s password to stdout
  neomutt-pass.sh rm <account>       Delete the encrypted password for <account>
  neomutt-pass.sh list               List accounts with stored encrypted passwords
EOF
}

ensure_dirs() {
  mkdir -p -m 700 "$SECRETS_DIR"
}

derive_key() {
  local account="$1"

  if [[ ! -f "$PUBKEY_FILE" ]]; then
    echo "Error: Public key not found at $PUBKEY_FILE. Run 'neomutt-pass.sh init' first." >&2
    return 1
  fi

  if ! grep -Eq '^(ssh-ed25519|ssh-rsa) ' "$PUBKEY_FILE" 2>/dev/null; then
    echo "Error: $PUBKEY_FILE must be an ssh-ed25519 or ssh-rsa public key (deterministic signatures required)." >&2
    return 1
  fi

  local raw_sig
  if ! raw_sig="$(printf 'neomutt-v1:%s' "$account" | ssh-keygen -Y sign -f "$PUBKEY_FILE" -n neomutt 2>/dev/null)"; then
    echo "Error: Could not sign with SSH agent. Is your KeePassXC database unlocked?" >&2
    return 1
  fi

  if [[ "$raw_sig" != *"BEGIN SSH SIGNATURE"* ]]; then
    echo "Error: Invalid signature from SSH agent. Is your KeePassXC database unlocked?" >&2
    return 1
  fi

  printf '%s' "$raw_sig" | shasum -a 256 | awk '{print $1}'
}

cmd_init() {
  ensure_dirs
  local keys
  if ! keys="$(ssh-add -L 2>/dev/null | grep -E '^(ssh-ed25519|ssh-rsa) ' || true)" || [[ -z "$keys" ]]; then
    echo "Error: No ssh-ed25519 or ssh-rsa keys found in the active SSH agent." >&2
    echo "1. Unlock your KeePassXC database." >&2
    echo "2. Ensure Settings -> SSH Agent is enabled in KeePassXC." >&2
    echo "3. Ensure an SSH key entry has 'Add key to agent when database is opened' enabled." >&2
    return 1
  fi

  local count
  count="$(printf '%s\n' "$keys" | wc -l | tr -d ' ')"

  if [[ "$count" -eq 1 ]]; then
    printf '%s\n' "$keys" > "$PUBKEY_FILE"
    chmod 600 "$PUBKEY_FILE"
    echo "Saved SSH public key to $PUBKEY_FILE:"
    cat "$PUBKEY_FILE"
  else
    echo "Multiple compatible SSH keys found in agent:"
    local i=1
    local -a key_list
    while IFS= read -r line; do
      key_list+=("$line")
      echo "  [$i] $line"
      ((i++))
    done <<< "$keys"

    printf "Select key number [1-%d]: " "$count"
    local choice
    read -r choice
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > count )); then
      echo "Error: Invalid selection." >&2
      return 1
    fi
    printf '%s\n' "${key_list[$choice]}" > "$PUBKEY_FILE"
    chmod 600 "$PUBKEY_FILE"
    echo "Saved selected public key to $PUBKEY_FILE."
  fi
}

cmd_check() {
  local test_key
  test_key="$(derive_key "__healthcheck__")"
  if [[ -n "$test_key" ]]; then
    echo "OK: KeePassXC SSH agent key is unlocked and ready ($PUBKEY_FILE)."
  fi
}

cmd_set() {
  local account="${1:-}"
  if [[ -z "$account" ]]; then
    echo "Usage: neomutt-pass.sh set <account>" >&2
    return 1
  fi

  ensure_dirs
  local derived_key
  derived_key="$(derive_key "$account")"

  local pass1 pass2
  printf "Enter password for account '%s': " "$account" >&2
  read -rs pass1
  echo >&2
  printf "Confirm password for account '%s': " "$account" >&2
  read -rs pass2
  echo >&2

  if [[ "$pass1" != "$pass2" ]]; then
    echo "Error: Passwords do not match." >&2
    return 1
  fi

  if [[ -z "$pass1" ]]; then
    echo "Error: Password cannot be empty." >&2
    return 1
  fi

  local enc_file="$SECRETS_DIR/${account}.enc"
  printf '%s' "$pass1" | openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -base64 \
    -pass fd:3 -out "$enc_file" 3<<< "$derived_key"
  chmod 600 "$enc_file"
  echo "Saved encrypted password for '$account' to $enc_file" >&2
}

cmd_get() {
  local account="${1:-}"
  if [[ -z "$account" ]]; then
    echo "Usage: neomutt-pass.sh get <account>" >&2
    return 1
  fi

  local enc_file="$SECRETS_DIR/${account}.enc"
  if [[ ! -f "$enc_file" ]]; then
    echo "Error: No encrypted password found for '$account' ($enc_file)." >&2
    return 1
  fi

  local derived_key
  derived_key="$(derive_key "$account")"

  openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -base64 \
    -pass fd:3 -in "$enc_file" 3<<< "$derived_key"
}

cmd_rm() {
  local account="${1:-}"
  if [[ -z "$account" ]]; then
    echo "Usage: neomutt-pass.sh rm <account>" >&2
    return 1
  fi

  local enc_file="$SECRETS_DIR/${account}.enc"
  if [[ -f "$enc_file" ]]; then
    rm -f "$enc_file"
    echo "Removed encrypted password for '$account'."
  else
    echo "No encrypted password found for '$account'." >&2
    return 1
  fi
}

cmd_list() {
  ensure_dirs
  local files=("$SECRETS_DIR"/*.enc(N))
  if (( ${#files} == 0 )); then
    echo "No stored account passwords in $SECRETS_DIR"
    return 0
  fi
  for f in "${files[@]}"; do
    echo "${${f:t}%.enc}"
  done
}

main() {
  local subcmd="${1:-}"
  case "$subcmd" in
    init)  cmd_init ;;
    check) cmd_check ;;
    set)   shift; cmd_set "$@" ;;
    get)   shift; cmd_get "$@" ;;
    rm)    shift; cmd_rm "$@" ;;
    list)  cmd_list ;;
    -h|--help|help|"") usage ;;
    *)
      echo "Unknown command: $subcmd" >&2
      usage >&2
      return 1
      ;;
  esac
}

main "$@"
