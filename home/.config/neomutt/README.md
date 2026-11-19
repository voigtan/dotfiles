# NeoMutt + KeePassXC SSH Agent Setup Guide

This directory (`~/.config/neomutt`) contains a modular multi-account NeoMutt setup where all accounts are listed together in the left sidebar (`---[ ACCOUNT ]---`) and account passwords are encrypted on disk (`secrets/<account>.enc`), unlocked on the fly using an **SSH key (`ssh-ed25519` or `ssh-rsa`) held in KeePassXC's SSH Agent**.

When your KeePassXC database is **locked**, the SSH key is removed from the agent and NeoMutt clears the sidebar and message list to an empty `LOCKED` view.

---

## Directory Structure

```text
~/.config/neomutt/
├── neomuttrc                  # Main NeoMutt configuration (sources bindings, colors, accounts)
├── bindings                   # All keybindings in a dedicated file
├── colors                     # Catppuccin Frappé truecolor theme
├── mailcap                    # UTF-8 HTML email rendering and attachment handling
├── README.md                  # This setup & reference guide
├── accounts/                  # Configuration for every account in a separate file
│   ├── example.example        # Template for adding new email accounts (tracked in Git)
│   └── order.txt              # Optional file to define account load order (ignored by Git)
├── signatures/                # Signatures kept separate per account
│   ├── example-sign.example   # Template signature (tracked in Git)
├── scripts/
│   ├── neomutt-pass.sh        # Encrypts/decrypts passwords via KeePassXC SSH Agent
│   └── load-accounts.sh       # Builds unified multi-account sidebar, hooks & lock screen
└── secrets/                   # (Ignored by Git, chmod 700)
    ├── agent.pub              # Public key of the SSH key in KeePassXC's SSH Agent
    └── <account>.enc          # AES-256-CBC encrypted password for each account
```

---

## 1. Setting Up KeePassXC & SSH Agent

NeoMutt uses `ssh-keygen -Y sign` with an **`ssh-ed25519` or `ssh-rsa`** key loaded in your SSH agent. Because both signature types are 100% deterministic in OpenSSH, signing a challenge produces a repeatable 256-bit key **only while KeePassXC has loaded the key into `ssh-agent`**.

### Step 1.1: Enable SSH Agent in KeePassXC
1. Open **KeePassXC** → **Settings** (`Cmd + ,`).
2. Go to **SSH Agent** (left sidebar).
3. Check **[x] Enable SSH Agent integration**.

### Step 1.2: Configure Your SSH Key Entry in KeePassXC
1. On your SSH key entry in KeePassXC, open the **SSH Agent** tab in the left sidebar.
2. Make sure both checkboxes are checked:
   - **[x] Add key to agent when database is opened/unlocked**
   - **[x] Remove key from agent when database is closed/locked**
3. Verify that unlocking KeePassXC shows the key in `ssh-add -L`, and locking KeePassXC removes it from `ssh-add -L`.

### Step 1.3: Initialize `neomutt-pass.sh`
With your KeePassXC database unlocked, run:
```sh
~/.config/neomutt/scripts/neomutt-pass.sh init
~/.config/neomutt/scripts/neomutt-pass.sh check
```
This saves the public key from the active SSH agent to `~/.config/neomutt/secrets/agent.pub` and verifies signing works.

---

## 2. Managing Account Passwords (`neomutt-pass.sh`)

All commands require your KeePassXC database to be unlocked:

```sh
# Add or update the password for an account (e.g. "personal", "work", "voigtan")
~/.config/neomutt/scripts/neomutt-pass.sh set <account>

# Test decrypting an account's password
~/.config/neomutt/scripts/neomutt-pass.sh get <account>

# List all accounts that have an encrypted password stored
~/.config/neomutt/scripts/neomutt-pass.sh list

# Remove a stored password
~/.config/neomutt/scripts/neomutt-pass.sh rm <account>

# Check if KeePassXC SSH agent is unlocked and ready
~/.config/neomutt/scripts/neomutt-pass.sh check
```

---

## 3. Adding, Editing & Ordering Email Accounts

You can name accounts anything you want. The **filename** inside `accounts/<name>` is the account's name and automatically links to:
- Password file: `secrets/<name>.enc`
- Signature file: `signatures/<name>-sign`
- Cache directory: `~/.cache/neomutt/<name>/`
- Sidebar section header: `---[ <NAME> ]---------`

### Adding a New Account
1. Store the account's password:
   ```sh
   ~/.config/neomutt/scripts/neomutt-pass.sh set work
   ```
2. Copy the account and signature templates:
   ```sh
   cp ~/.config/neomutt/accounts/example.example ~/.config/neomutt/accounts/work
   cp ~/.config/neomutt/signatures/example-sign.example ~/.config/neomutt/signatures/work-sign
   ```
3. Edit `~/.config/neomutt/accounts/work`:
   ```muttrc
   set realname   = "Andreas Voigt"
   set from       = "andreas@company.com"
   set imap_user  = "andreas@company.com"
   set folder     = "imaps://$imap_user@imap.company.com:993"
   set smtp_url   = "smtps://$imap_user@smtp.company.com:465"
   ```
   > **Note:** All folders on your IMAP server are discovered automatically and cached in `~/.cache/neomutt/<name>/folders.cache`. Press **`gr`** in NeoMutt anytime to refresh the folder list from the server.
   > **Important:** Always keep `$imap_user@` inside `set folder = "imaps://$imap_user@..."`. This ensures NeoMutt keeps separate IMAP connections when you have multiple accounts on the same email provider.

### Editing an Existing Account
- **Server / folders / name:** edit `~/.config/neomutt/accounts/<name>` (adjust `my_folders` to change which folders appear under `---[ <NAME> ]---` in the sidebar).
- **Signature:** edit `~/.config/neomutt/signatures/<name>-sign`.
- **Password:** run `~/.config/neomutt/scripts/neomutt-pass.sh set <name>`.

### Customizing Account Order (`order.txt`)
By default, accounts appear in the sidebar in alphabetical order (`personal`, `voigtan`, `work`).
To customize the order in the sidebar and for `F2` / `g1`..`g9`, create `~/.config/neomutt/accounts/order.txt` with one account name per line:
```text
personal
work
voigtan
```

### Removing an Account
```sh
rm -f ~/.config/neomutt/accounts/<name> ~/.config/neomutt/signatures/<name>-sign
~/.config/neomutt/scripts/neomutt-pass.sh rm <name>
rm -rf ~/.cache/neomutt/<name> ~/.cache/neomutt/sep/<name>
```

---

## 4. Common Provider IMAP / SMTP Settings

| Provider | `folder` (IMAP) | `smtp_url` (SMTP) | Notes |
| :--- | :--- | :--- | :--- |
| **Websupport** | `imaps://$imap_user@imap.websupport.se:993` | `smtps://$imap_user@smtp.websupport.se:465` | Standard email password |
| **Gmail** | `imaps://$imap_user@imap.gmail.com:993` | `smtps://$imap_user@smtp.gmail.com:465` | Requires Google **App Password** |
| **iCloud** | `imaps://$imap_user@imap.mail.me.com:993` | `smtp://$imap_user@smtp.mail.me.com:587` | Requires Apple **App-Specific Password** |
| **Fastmail** | `imaps://$imap_user@imap.fastmail.com:993` | `smtps://$imap_user@smtp.fastmail.com:465` | Requires Fastmail **App Password** |
| **Outlook / 365** | `imaps://$imap_user@outlook.office365.com:993` | `smtp://$imap_user@smtp.office365.com:587` | STARTTLS on port `587` |
| **ProtonMail** | `imap://$imap_user@127.0.0.1:1143` | `smtp://$imap_user@127.0.0.1:1025` | Requires ProtonMail Bridge running locally |

---

## 5. NeoMutt Keybindings Cheat Sheet

### Account Switching
| Key | Action |
| :--- | :--- |
| **`F2`** or **`gn`** | Cycle to the **next** account's INBOX (wraps around across all accounts) |
| **`F3`** or **`gp`** | Cycle to the **previous** account's INBOX (wraps around) |
| **`g1`**, **`g2`**, **`g3`** ... | Jump directly to Account 1, Account 2, Account 3, ... |

### Folder Sidebar & Quick Folder Jumps
| Key | Action |
| :--- | :--- |
| **`gi`** | Go to current account's **`INBOX`** |
| **`gs`** | Go to current account's **`Sent`** |
| **`gd`** | Go to current account's **`Drafts`** |
| **`ga`** | Go to current account's **`Archive`** |
| **`gt`** | Go to current account's **`Trash`** |
| **`gj`** | Go to current account's **`Junk`** |
| **`J`** (`Shift+j`) or **`Ctrl + j`** | Move highlight **down** to next folder in sidebar (across all accounts) |
| **`K`** (`Shift+k`) or **`Ctrl + k`** | Move highlight **up** to previous folder in sidebar |
| **`O`** (`Shift+o`) or **`Ctrl + o`** | **Open** the highlighted sidebar folder (auto-switches active account!) |
| **`B`** (`Shift+b`) or **`Ctrl + b`** | Show / hide the sidebar |
| **`gr`** | Refresh the sidebar folder list from all IMAP servers |
| **`c`** | Change folder by name (press `?` at prompt to list remote folders) |

### Message List (Index) & Reading (Pager)
| Key | Action |
| :--- | :--- |
| **`j`** / **`k`** | Move down / up (or scroll line-by-line in pager) |
| **`gg`** / **`G`** | Jump to top / bottom |
| **`Enter`** | Open selected email |
| **`Space`** | Collapse / expand thread (in list) or page down (in email) |
| **`q`** | Return to message list (from email) or quit NeoMutt |
| **`Tab`** | Sync & refresh mailbox (or **lock/clear screen** if KeePassXC was locked, and **unlock/reload** once KeePassXC is unlocked again) |

### Composing, Replying & Deleting
| Key | Action |
| :--- | :--- |
| **`m`** | Compose a **new** email in `nvim` (`:wq` in `nvim` when done typing) |
| **`r`** | Reply to sender only |
| **`R`** | **Reply all** (group reply) |
| **`f`** | Forward email |
| **`y`** | **Send** email (from the compose summary screen after closing `nvim`) |
| **`a`** | Attach a file (from the compose summary screen) |
| **`d`** / **`u`** | Mark email for deletion / Undelete |
| **`v`** | View attachments / MIME parts (press `Enter` to open or `s` to save) |

### Searching & Filtering
| Key | Action |
| :--- | :--- |
| **`gu`** or **`U`** (`Shift+u`) | **Toggle** between **Unread messages only (`~U`)** and **All messages (`all`)** |
| **`N`** (`Shift+n`) | Toggle the selected email's **Unread / Read** status |
| **`/`** | Search in current folder (`n` for next match) |
| **`l`** | Filter (`~U` unread, `~F` flagged, `~f sender`, `all` to reset) |
| **`?`** | Open built-in interactive help for all keybindings |
