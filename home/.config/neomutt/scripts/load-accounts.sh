#!/usr/bin/env zsh
# ==============================================================================
# load-accounts.sh
# Auto-discovers ~/.config/neomutt/accounts/* and builds:
#   1. A unified multi-account sidebar (macowners.club style) showing all
#      accounts and their server folders under "---[ ACCOUNT ]---" headers.
#   2. Automatic IMAP server folder discovery (cached in ~/.cache/neomutt/<acc>/folders.cache
#      for instant startup; press 'gr' in NeoMutt to refresh folders from the server).
#   3. Per-account account-hooks and folder-hooks so navigating the sidebar
#      (Ctrl+j / Ctrl+k / Ctrl+o) or pressing F2/F3/g1..g9 automatically
#      switches credentials, From address, SMTP server, and signature.
#   4. KeePassXC SSH Agent lock protection on startup, account switch, and <Tab>.
# ==============================================================================

set -euo pipefail

NEOMUTT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/neomutt"
ACCOUNTS_DIR="$NEOMUTT_DIR/accounts"
SCRIPT_PATH="$NEOMUTT_DIR/scripts/load-accounts.sh"
PASS_SCRIPT="$NEOMUTT_DIR/scripts/neomutt-pass.sh"
ORDER_FILE="$ACCOUNTS_DIR/order.txt"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/neomutt"
LOCKED_MAILDIR="$CACHE_DIR/locked"
SEP_BASE_DIR="$CACHE_DIR/sep"

TARGET_IDX="${1:-1}"
MODE="${2:---init}" # "--init", "--switch", or "--refresh"

# Ensure the empty Maildir exists for the locked screen
mkdir -p -m 700 "$LOCKED_MAILDIR/cur" "$LOCKED_MAILDIR/new" "$LOCKED_MAILDIR/tmp"

typeset -a account_files=()
typeset -A seen=()

# 1. Respect explicit ordering in accounts/order.txt if present
if [[ -f "$ORDER_FILE" ]]; then
  while IFS= read -r line; do
    line="${line%%#*}"
    line="${line//[[:space:]]/}"
    [[ -z "$line" ]] && continue
    for candidate in "$ACCOUNTS_DIR/$line" "$ACCOUNTS_DIR/${line%.muttrc}" "$ACCOUNTS_DIR/${line%.muttrc}.muttrc"; do
      if [[ -f "$candidate" && -z "${seen[$candidate]:-}" ]]; then
        account_files+=("$candidate")
        seen[$candidate]=1
        break
      fi
    done
  done < "$ORDER_FILE"
fi

# 2. Append any remaining account files in alphabetical order (ignore *.example and order.txt)
for file in "$ACCOUNTS_DIR"/*(N.); do
  base="${file:t}"
  [[ "$base" == *.example || "$base" == "order.txt" || "$base" == .* ]] && continue
  if [[ -z "${seen[$file]:-}" ]]; then
    account_files+=("$file")
    seen[$file]=1
  fi
done

total=${#account_files}

if (( total == 0 )); then
  cat <<'EOF'
echo "NeoMutt: No accounts found in ~/.config/neomutt/accounts/ (copy example.example to <name>)"
EOF
  exit 0
fi

# Clamp TARGET_IDX into [1..total]
if [[ ! "$TARGET_IDX" =~ ^[0-9]+$ ]] || (( TARGET_IDX < 1 || TARGET_IDX > total )); then
  TARGET_IDX=1
fi

# Helper: extract a `set key = "value"` setting from an account file
extract_var() {
  local file="$1"
  local key="$2"
  awk -v k="$key" '
    /^[[:space:]]*set[[:space:]]+/ {
      line = $0
      sub(/^[[:space:]]*set[[:space:]]+/, "", line)
      if (line ~ "^" k "[[:space:]]*=") {
        sub("^" k "[[:space:]]*=[[:space:]]*", "", line)
        sub(/[[:space:]]*#.*$/, "", line)
        gsub(/^["'\'']|["'\'']$/, "", line)
        print line
        exit
      }
    }
  ' "$file"
}

# Build a "---[ NAME ]-----------" sidebar header string of width 26
format_header() {
  local upper="${(U)1}"
  local prefix="---[ ${upper} ]"
  local pad_len=$(( 26 - ${#prefix} ))
  (( pad_len < 2 )) && pad_len=2
  local dashes
  dashes="$(printf '%*s' "$pad_len" '' | tr ' ' '-')"
  printf '%s%s' "$prefix" "$dashes"
}

# Fetch folders from the IMAP server (or read from cache unless --refresh)
get_account_folders() {
  local name="$1"
  local imap_user="$2"
  local folder_url="$3"
  local acc_cache_dir="$CACHE_DIR/$name"
  local cache_file="$acc_cache_dir/folders.cache"

  mkdir -p -m 700 "$acc_cache_dir"

  if [[ "$MODE" != "--refresh" && -s "$cache_file" ]]; then
    cat "$cache_file"
    return 0
  fi

  # Parse scheme, host, port from folder_url (e.g. imaps://user@imap.websupport.se:993)
  local proto="${folder_url%%://*}"
  local hostport="${folder_url##*@}"
  hostport="${hostport%%/*}"
  local host="${hostport%%:*}"
  local port="${hostport##*:}"
  if [[ "$port" == "$host" ]]; then
    [[ "$proto" == "imaps" ]] && port=993 || port=143
  fi

  if python3 - "$PASS_SCRIPT" "$name" "$imap_user" "$proto" "$host" "$port" > "${cache_file}.tmp" 2>/dev/null <<'PYEOF'
import sys, imaplib, re, codecs, subprocess

pass_script, acc_name, imap_user, proto, host, port = sys.argv[1:7]
port = int(port)

def decode_mutf7(s):
    def repl(m):
        b = m.group(1)
        if not b:
            return "&"
        b64 = b.replace(",", "/")
        pad = (4 - len(b64) % 4) % 4
        return codecs.decode((b64 + "=" * pad).encode("ascii"), "base64").decode("utf-16-be")
    return re.sub(r"&([^-]*)-", repl, s)

pw = subprocess.check_output([pass_script, "get", acc_name]).decode("utf-8").rstrip("\r\n")
M = imaplib.IMAP4_SSL(host, port) if proto == "imaps" else imaplib.IMAP4(host, port)
M.login(imap_user, pw)
typ, data = M.list()
M.logout()

folders = []
for raw in (data or []):
    if not raw:
        continue
    line = raw.decode("utf-8", "replace")
    m = re.match(r'\(([^)]*)\)\s+"([^"]+)"\s+(.*)', line)
    if not m:
        continue
    flags, delim, fname = m.groups()
    if "\\Noselect" in flags:
        continue
    fname = fname.strip().strip('"')
    folders.append(decode_mutf7(fname))

priority = [
    "INBOX", "Archive", "Archives", "Sent", "Sent Messages",
    "Drafts", "Notes", "Junk", "Spam", "Trash", "Deleted Messages"
]
pri_map = {k: i for i, k in enumerate(priority)}
folders.sort(key=lambda x: (pri_map.get(x, 999), x.lower()))

for f in folders:
    print(f)
PYEOF
  then
    if [[ -s "${cache_file}.tmp" ]]; then
      mv "${cache_file}.tmp" "$cache_file"
      chmod 600 "$cache_file"
      cat "$cache_file"
      return 0
    fi
  fi
  rm -f "${cache_file}.tmp"

  # Fallback if server query failed
  if [[ -s "$cache_file" ]]; then
    cat "$cache_file"
  else
    printf '%s\n' "INBOX" "Archive" "Sent" "Drafts" "Junk" "Trash"
  fi
}

# Check if KeePassXC SSH agent is unlocked and able to sign
if ! "$PASS_SCRIPT" check >/dev/null 2>&1; then
  for (( idx = 1; idx <= total; idx++ )); do
    name="${${account_files[$idx]:t}%.muttrc}"
    cat <<EOF
macro index g${idx} '<enter-command>source "${SCRIPT_PATH} ${idx} --init|"<enter><change-folder><kill-line>!<enter>' "Unlock and switch to ${name}"
macro pager g${idx} '<exit><enter-command>source "${SCRIPT_PATH} ${idx} --init|"<enter><change-folder><kill-line>!<enter>' "Unlock and switch to ${name}"
EOF
  done

  cat <<EOF
unmailboxes *
unhook *
unset imap_user
unset imap_pass
unset smtp_url
unset smtp_pass
unset header_cache
unset message_cachedir
set my_account = "LOCKED"
set folder = "${LOCKED_MAILDIR}"
set spoolfile = "${LOCKED_MAILDIR}"
set status_format = "───[ LOCKED: KeePassXC SSH Agent is locked — Unlock KeePassXC & press <Tab> or F2 ]───%>───"
macro index <tab> '<enter-command>source "${SCRIPT_PATH} ${TARGET_IDX} --init|"<enter><change-folder><kill-line>!<enter>' "Unlock and reload accounts"
macro pager <tab> '<exit><enter-command>source "${SCRIPT_PATH} ${TARGET_IDX} --init|"<enter><change-folder><kill-line>!<enter>' "Unlock and reload accounts"
macro index <f2>  '<enter-command>source "${SCRIPT_PATH} ${TARGET_IDX} --init|"<enter><change-folder><kill-line>!<enter>' "Unlock and reload accounts"
macro pager <f2>  '<exit><enter-command>source "${SCRIPT_PATH} ${TARGET_IDX} --init|"<enter><change-folder><kill-line>!<enter>' "Unlock and reload accounts"
macro index gn    '<enter-command>source "${SCRIPT_PATH} ${TARGET_IDX} --init|"<enter><change-folder><kill-line>!<enter>' "Unlock and reload accounts"
macro pager gn    '<exit><enter-command>source "${SCRIPT_PATH} ${TARGET_IDX} --init|"<enter><change-folder><kill-line>!<enter>' "Unlock and reload accounts"
macro index <f3>  '<enter-command>source "${SCRIPT_PATH} ${TARGET_IDX} --init|"<enter><change-folder><kill-line>!<enter>' "Unlock and reload accounts"
macro pager <f3>  '<exit><enter-command>source "${SCRIPT_PATH} ${TARGET_IDX} --init|"<enter><change-folder><kill-line>!<enter>' "Unlock and reload accounts"
macro index gp    '<enter-command>source "${SCRIPT_PATH} ${TARGET_IDX} --init|"<enter><change-folder><kill-line>!<enter>' "Unlock and reload accounts"
macro pager gp    '<exit><enter-command>source "${SCRIPT_PATH} ${TARGET_IDX} --init|"<enter><change-folder><kill-line>!<enter>' "Unlock and reload accounts"
macro index gr    '<enter-command>source "${SCRIPT_PATH} ${TARGET_IDX} --refresh|"<enter><change-folder><kill-line>!<enter>' "Refresh folders from server"
macro pager gr    '<exit><enter-command>source "${SCRIPT_PATH} ${TARGET_IDX} --refresh|"<enter><change-folder><kill-line>!<enter>' "Refresh folders from server"
echo "LOCKED: KeePassXC SSH Agent is locked. Unlock KeePassXC, then press <Tab> or F2."
EOF
  exit 0
fi

typeset -a acc_names=()
typeset -a acc_urls=()
typeset -a acc_users=()

for (( idx = 1; idx <= total; idx++ )); do
  file="${account_files[$idx]}"
  name="${${file:t}%.muttrc}"
  imap_user="$(extract_var "$file" "imap_user")"
  raw_folder="$(extract_var "$file" "folder")"
  folder_url="${raw_folder//\$imap_user/$imap_user}"
  folder_url="${folder_url%/}"
  acc_names+=("$name")
  acc_urls+=("$folder_url")
  acc_users+=("$imap_user")
done

# Rebuild the sidebar and hooks on --init or --refresh
if [[ "$MODE" == "--init" || "$MODE" == "--refresh" ]]; then
  cat <<'EOF'
unmailboxes *
unhook *
EOF

  # 1. Register account-hooks, folder-hooks, and g1..gN macros FIRST (before named-mailboxes connects)
  for (( idx = 1; idx <= total; idx++ )); do
    file="${account_files[$idx]}"
    name="${acc_names[$idx]}"
    folder_url="${acc_urls[$idx]}"
    imap_user="${acc_users[$idx]}"

    next_idx=$(( (idx % total) + 1 ))
    prev_idx=$(( ((idx - 2 + total) % total) + 1 ))
    next_name="${acc_names[$next_idx]}"
    prev_name="${acc_names[$prev_idx]}"

    cat <<EOF
account-hook "${folder_url}" 'set imap_user = "${imap_user}" imap_pass = "\`${PASS_SCRIPT} get ${name}\`"'
folder-hook "${folder_url}" 'set my_account = "${name}"; source "${file}"; set status_format = "[ Account [${idx}/${total}]: ${name} (\$from) | Folder: %f ] [ %r%m messages%?n? (%n new)?%?d? (%d to delete)?%?t? (%t tagged)? ]%>─%?p?( %p postponed )?"; macro index <tab> "<sync-mailbox><enter-command>source \"${SCRIPT_PATH} ${idx} --switch|\"<enter><change-folder><kill-line>!<enter>" "Sync mailbox"; macro pager <tab> "<exit><sync-mailbox><enter-command>source \"${SCRIPT_PATH} ${idx} --switch|\"<enter><change-folder><kill-line>!<enter>" "Sync mailbox"; macro index gr "<enter-command>source \"${SCRIPT_PATH} ${idx} --refresh|\"<enter><change-folder><kill-line>!<enter>" "Refresh server folders"; macro pager gr "<exit><enter-command>source \"${SCRIPT_PATH} ${idx} --refresh|\"<enter><change-folder><kill-line>!<enter>" "Refresh server folders"; macro index <f2> "<enter-command>source \"${SCRIPT_PATH} ${next_idx} --switch|\"<enter><change-folder><kill-line>!<enter>" "Next account: ${next_name}"; macro pager <f2> "<exit><enter-command>source \"${SCRIPT_PATH} ${next_idx} --switch|\"<enter><change-folder><kill-line>!<enter>" "Next account: ${next_name}"; macro index gn "<enter-command>source \"${SCRIPT_PATH} ${next_idx} --switch|\"<enter><change-folder><kill-line>!<enter>" "Next account: ${next_name}"; macro pager gn "<exit><enter-command>source \"${SCRIPT_PATH} ${next_idx} --switch|\"<enter><change-folder><kill-line>!<enter>" "Next account: ${next_name}"; macro index <f3> "<enter-command>source \"${SCRIPT_PATH} ${prev_idx} --switch|\"<enter><change-folder><kill-line>!<enter>" "Previous account: ${prev_name}"; macro pager <f3> "<exit><enter-command>source \"${SCRIPT_PATH} ${prev_idx} --switch|\"<enter><change-folder><kill-line>!<enter>" "Previous account: ${prev_name}"; macro index gp "<enter-command>source \"${SCRIPT_PATH} ${prev_idx} --switch|\"<enter><change-folder><kill-line>!<enter>" "Previous account: ${prev_name}"; macro pager gp "<exit><enter-command>source \"${SCRIPT_PATH} ${prev_idx} --switch|\"<enter><change-folder><kill-line>!<enter>" "Previous account: ${prev_name}"'
macro index g${idx} '<enter-command>source "${SCRIPT_PATH} ${idx} --switch|"<enter><change-folder><kill-line>!<enter>' "Switch to account ${idx}: ${name}"
macro pager g${idx} '<exit><enter-command>source "${SCRIPT_PATH} ${idx} --switch|"<enter><change-folder><kill-line>!<enter>' "Switch to account ${idx}: ${name}"
EOF
  done

  # 2. Register named-mailboxes for the unified sidebar (fetched from IMAP server or my_folders override)
  for (( idx = 1; idx <= total; idx++ )); do
    file="${account_files[$idx]}"
    name="${acc_names[$idx]}"
    folder_url="${acc_urls[$idx]}"
    imap_user="${acc_users[$idx]}"
    custom_folders="$(extract_var "$file" "my_folders")"

    sep_dir="$SEP_BASE_DIR/$name"
    mkdir -p -m 700 "$sep_dir/cur" "$sep_dir/new" "$sep_dir/tmp"
    header_label="$(format_header "$name")"

    cat <<EOF
named-mailboxes "${header_label}" "${sep_dir}"
EOF

    if [[ -n "$custom_folders" ]]; then
      for mbox in ${(z)custom_folders}; do
        mbox="${mbox//\"/}"
        cat <<EOF
named-mailboxes "  ${mbox}" "${folder_url}/${mbox}"
EOF
      done
    else
      while IFS= read -r mbox; do
        [[ -z "$mbox" ]] && continue
        cat <<EOF
named-mailboxes "  ${mbox}" "${folder_url}/${mbox}"
EOF
      done < <(get_account_folders "$name" "$imap_user" "$folder_url")
    fi
  done
fi

# Activate TARGET_IDX without clearing the unified sidebar
active_file="${account_files[$TARGET_IDX]}"
active_name="${acc_names[$TARGET_IDX]}"
next_idx=$(( (TARGET_IDX % total) + 1 ))
prev_idx=$(( ((TARGET_IDX - 2 + total) % total) + 1 ))
next_name="${acc_names[$next_idx]}"
prev_name="${acc_names[$prev_idx]}"

cat <<EOF
set my_account = "${active_name}"
source "${active_file}"
set status_format = "[ Account [${TARGET_IDX}/${total}]: ${active_name} (\$from) | Folder: %f ] [ %r%m messages%?n? (%n new)?%?d? (%d to delete)?%?t? (%t tagged)? ]%>─%?p?( %p postponed )?"
macro index <tab> '<sync-mailbox><enter-command>source "${SCRIPT_PATH} ${TARGET_IDX} --switch|"<enter><change-folder><kill-line>!<enter>' "Sync mailbox (or lock if KeePassXC is locked)"
macro pager <tab> '<exit><sync-mailbox><enter-command>source "${SCRIPT_PATH} ${TARGET_IDX} --switch|"<enter><change-folder><kill-line>!<enter>' "Sync mailbox (or lock if KeePassXC is locked)"
macro index gr    '<enter-command>source "${SCRIPT_PATH} ${TARGET_IDX} --refresh|"<enter><change-folder><kill-line>!<enter>' "Refresh server folders"
macro pager gr    '<exit><enter-command>source "${SCRIPT_PATH} ${TARGET_IDX} --refresh|"<enter><change-folder><kill-line>!<enter>' "Refresh server folders"
macro index <f2>  '<enter-command>source "${SCRIPT_PATH} ${next_idx} --switch|"<enter><change-folder><kill-line>!<enter>' "Next account: ${next_name}"
macro pager <f2>  '<exit><enter-command>source "${SCRIPT_PATH} ${next_idx} --switch|"<enter><change-folder><kill-line>!<enter>' "Next account: ${next_name}"
macro index gn    '<enter-command>source "${SCRIPT_PATH} ${next_idx} --switch|"<enter><change-folder><kill-line>!<enter>' "Next account: ${next_name}"
macro pager gn    '<exit><enter-command>source "${SCRIPT_PATH} ${next_idx} --switch|"<enter><change-folder><kill-line>!<enter>' "Next account: ${next_name}"
macro index <f3>  '<enter-command>source "${SCRIPT_PATH} ${prev_idx} --switch|"<enter><change-folder><kill-line>!<enter>' "Previous account: ${prev_name}"
macro pager <f3>  '<exit><enter-command>source "${SCRIPT_PATH} ${prev_idx} --switch|"<enter><change-folder><kill-line>!<enter>' "Previous account: ${prev_name}"
macro index gp    '<enter-command>source "${SCRIPT_PATH} ${prev_idx} --switch|"<enter><change-folder><kill-line>!<enter>' "Previous account: ${prev_name}"
macro pager gp    '<exit><enter-command>source "${SCRIPT_PATH} ${prev_idx} --switch|"<enter><change-folder><kill-line>!<enter>' "Previous account: ${prev_name}"
EOF
