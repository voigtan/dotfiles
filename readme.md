# Installation

1. Clone the repository into `~/.dotfiles`:

```zsh
git clone https://github.com/voigtan/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

> **Note:** On a brand-new Mac without `git` or `make` yet, running `git clone` will automatically prompt macOS to install Xcode Command Line Tools (or `scripts/osx.sh` will install them automatically if you run `./install.sh`).

2. *(Optional)* Create `home/.extra` for local overrides (such as Git credentials):

```zsh
# Git credentials
GIT_AUTHOR_NAME=""
GIT_AUTHOR_EMAIL=""
GIT_SIGNINGKEY=""
```

3. Run the installer (installs Xcode CLI Tools, Oh My Zsh, Homebrew + `brewfile` packages/fonts, symlinks `home/` via GNU Stow, configures Ghostty/iTerm2/Dock/macOS defaults, and sets up `pinentry-mac`):

```zsh
make install
```

---

# GPG Key & Git Commit Signing Guide

> **Placeholder used below:** Replace `1E62EB9A74CF9C3A` with your actual GPG `KEY_ID`.

## 1. List Your Keys & Find Your `KEY_ID`

```zsh
gpg --list-secret-keys --keyid-format=long
```

Look at the `sec` line—your **`KEY_ID`** is the 16-character hex string after the `/` (for example `1E62EB9A74CF9C3A`):

```text
sec   rsa4096/1E62EB9A74CF9C3A 2024-01-01 [SC]
      F66F012CC31111555E8A22451E62EB9A74CF9C3A
uid                 [ultimate] Andreas Voigt <voigtan@users.noreply.github.com>
```

---

## 2. Export Your Public Key (to Add to GitHub)

Export the public certificate in ASCII-armor format (and copy it directly to your macOS clipboard):

```zsh
gpg --armor --export 1E62EB9A74CF9C3A | pbcopy
```

*(Or print it to the terminal without `| pbcopy`):*

```zsh
gpg --armor --export 1E62EB9A74CF9C3A
```

1. Go to **[GitHub Settings → SSH and GPG keys](https://github.com/settings/keys)**.
2. Click **New GPG key**.
3. Paste the entire block (including `-----BEGIN PGP PUBLIC KEY BLOCK-----` and `-----END PGP PUBLIC KEY BLOCK-----`).

---

## 3. Add a Work Email to an Existing GPG Key

If you use one GPG key for both personal and work commits, add your work email as an additional identity (`uid`) on the same key:

```zsh
gpg --edit-key 1E62EB9A74CF9C3A
```

Inside the interactive `gpg>` prompt:
1. Type `adduid` and press `<Enter>`.
2. Enter your **Real name**, **Work email address**, and optional **Comment**, then type `O` (Okay) and enter your passphrase.
3. Type `save` and press `<Enter>` to save and exit.
4. **Re-export your public key** (`gpg --armor --export 1E62EB9A74CF9C3A | pbcopy`) and re-upload it to GitHub so GitHub recognizes the new email address on your key.

---

## 4. Back Up a GPG Key (Before Moving to a New Mac)

Run these commands to export your **private key** and **trust level**:

```zsh
# 1. Export secret (private) key (prompts for your passphrase)
gpg --export-secret-key 1E62EB9A74CF9C3A > 1E62EB9A74CF9C3A.gpg

# 2. Export ownertrust level
gpg --export-ownertrust > 1E62EB9A74CF9C3A.trustlevel.txt
```

> Store `1E62EB9A74CF9C3A.gpg` and `1E62EB9A74CF9C3A.trustlevel.txt` securely (e.g., 1Password) and delete the local files once backed up.

---

## 5. Import & Trust Your Key on a New Mac

### Step A: Import the secret key

```zsh
gpg --import 1E62EB9A74CF9C3A.gpg
```

### Step B: Set the key's trust level to "Ultimate"

You can do this **either** via your exported trust file **or** interactively:

* **Option 1 — From your backup trust file:**
  ```zsh
  gpg --import-ownertrust 1E62EB9A74CF9C3A.trustlevel.txt
  ```

* **Option 2 — Manually via interactive prompt:**
  ```zsh
  gpg --edit-key 1E62EB9A74CF9C3A trust quit
  ```
  Then at the prompts:
  1. Press **`5`** + `<Enter>` (*I trust ultimately*)
  2. Press **`y`** + `<Enter>` (*Really set this key to ultimate trust - Yes*)

---

## 6. Configure Git & macOS Keychain (`pinentry-mac`)

Your `.dotfiles` already sets `[commit] gpgSign = true` and `[gpg] program = gpg` in `home/.gitconfig`. To point Git at your key ID:

```zsh
git config --global user.signingkey 1E62EB9A74CF9C3A
git config --global commit.gpgsign true
```

To ensure macOS caches your passphrase in Keychain via `pinentry-mac` (also handled by `scripts/SetupPinentry.sh`):

```zsh
echo "pinentry-program $(brew --prefix)/bin/pinentry-mac" > ~/.gnupg/gpg-agent.conf
gpgconf --kill gpg-agent
```

---

## 7. Test & Troubleshoot Signing

* **Test signing a string directly with GPG:**
  ```zsh
  echo "<sha>" | gpg -a --default-key 1E62EB9A74CF9C3A --detach-sig
  ```
  *(If `pinentry-mac` is working, a native macOS dialog will prompt for your passphrase once and print a `-----BEGIN PGP SIGNATURE-----` block).*

* **Verify the signature on your latest Git commit:**
  ```zsh
  git log --show-signature -1
  ```

### References
* [Adding Work E-Mail to a GPG Key and Signing Git Commits](https://code.dblock.org/2021/04/16/adding-work-email-to-a-gpg-key-and-signing-git-commits.html)
* [Signing your commits on GitHub (Gist)](https://gist.github.com/trevorlinton/f3be63f1d4b1695e598d12d05f8d7cca)
