# Personal secrets encrypted with sops and age

## Intent

The owner's own environment (personal tokens, the VPN, the media stack) lives
encrypted in the dotfiles repo. Code projects keep their own `.env` inside the
repo (gitignored) and never go through the vault or this setup. No secret lives
in plain text in a synced folder, and daily use never prompts for a password.

## Decisions

- sops with age, one dotenv file per use: `secrets/personal.env` (VPN, Gemini)
  and `secrets/media.env` (media stack). `.sops.yaml` at the repo root holds the
  age recipient.
- One age key, the same on both machines, at `~/.config/sops/age/keys.txt`
  (mode 600). Backup: the vault item `age (dotfiles)`; a new machine restores it
  from there (`missing.sh terminal` prints the command).
- The repo is public. Accepted by the owner: key names are readable, and a leaked
  age key would decrypt the whole git history; rotating then means changing every
  secret, not only the key.
- `vpn` re-runs itself under `secrets run` (sops exec-env); `vpn.env` goes away.
- `GEMINI_API_KEY` reaches only `gemini`, through an alias over `secrets run`.
  The bashrc never decrypts on shell start.
- `media.env` stays a plain generated file (`~/.config/media/media.env`, mode
  600) because compose reads a file. `media-deploy` decrypts it, and encrypts it
  back when it generates a key; the owner commits the change.
- The vault folder `dotfiles`, the "item name is the file path" model and
  `~/Documents/Unimed/Envs` go away. `auditoria-hml-conexao-chave.env` is
  removed from the vault and from Documents; the project's `.env` keeps it.
- `Personal/Security` moves into the password manager: recovery codes into the
  "GitHub (pessoal)" item, `client_secret` as an attachment of a new item
  "Google Cloud OAuth (rclone)", each entry of `API keys.md` as its own item.
  Then the files leave the disk, the Drive and the Drive trash.

## Approaches considered

- sops + age in the repo (chosen): no server, no account, works offline,
  versioned with the config, the community default for dotfiles.
- The same file in `~/Documents/Personal/Secrets` through syncfast: not public,
  but no history; rejected by the owner.
- Bitwarden Secrets Manager with a keyring token: organization, subscription,
  machine accounts and a binary from GitHub for about 15 values; too heavy.
- rbw only: prompts for the master password every 8 hours, including the
  unattended media deploy.
- 1Password (`op run` with `op://` references): simple, but paid and means
  moving the whole password manager.

## Accepted risk

The notebook disk is not encrypted; the age key file is readable by anyone with
the disk.
