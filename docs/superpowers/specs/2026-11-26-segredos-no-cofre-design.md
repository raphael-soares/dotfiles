# Machine secrets live in the Bitwarden vault, read through rbw only

Supersedes the sops+age layout of `2026-11-25-personal-secrets-design.md` and
`2026-11-26-ssh-no-dotfiles-design.md`.

## Why

The owner edits secrets in the Bitwarden app; agents edit them from the
terminal. With sops, the app cannot see `secrets/`, so there would be two
sources for the same secret. Three vault clients (`rbw`, `bw`, the MCP) with
separate logins are the other source of friction.

Verified on 2026-11-26 with rbw 1.15.0 against bitwarden.com:
- `rbw edit` and `rbw add` read the entry from stdin when it is not a terminal
  (first line is the password, the rest are notes); round trip confirmed by hash.
- `rbw get --field private_key` returns SSH Key items as valid OpenSSH keys.
- `rbw list --raw` includes URIs (148 of 150 logins).

## Goals

- One source: a vault folder `Dotfiles`. `secrets/`, `.sops.yaml`, sops and the
  age key leave the repo and both PCs.
- One client: `rbw`. `bw` and the Bitwarden MCP server are removed.
- Deploy never prompts. It refreshes from the vault when `rbw` is unlocked and
  otherwise keeps the files already on disk.
- Agents create and replace secrets without seeing values; deleting needs the
  owner's approval.
- Same commands for the owner: `secrets run`, `secrets aws`, `secrets ssh`,
  `secrets check`, plus `secrets pull` and `secrets put`.

## Out of scope

- `gh` login (per machine token in the keyring).
- TEAjudo secrets (AWS SSM).
- Website passwords stay where they are; only `Dotfiles` is read by the deploy.

## Vault layout (folder `Dotfiles`)

| Item | Type | Becomes |
|---|---|---|
| `env personal` | Note | env of `secrets run` (dotenv in notes) |
| `env aws` | Note | `secrets aws` credential_process |
| `env media` | Note | env copy read by `media-deploy`, which writes `~/.config/media/media.env` |
| `ssh config`, `ssh config.d/<name>.conf` | Note | `~/.ssh/config`, `~/.ssh/config.d/<name>.conf` |
| `ssh key <name>` | SSH Key | `~/.ssh/keys/<name>` and `.pub` |
| `age backup` | Note | `~/.config/age/backup.key`, only where the media module is deployed |

The item name is the contract: prefix `env `, `ssh `, `ssh key ` or `age `.
Nothing else in the folder is touched.

**Media backup keeps age.** `media-backup` encrypts to the public key in
`media/backup.recipient` (not a secret, versioned); `media-restore-test` reads
the private key from `~/.config/age/backup.key` so the weekly timer runs alone.
The key is today's `age (dotfiles)` key, so existing backups stay readable.

## Behaviour

- `secrets pull`: requires unlocked `rbw` (runs `rbw unlock` if a terminal is
  attached), `rbw sync`, then writes every item to its target, mode 600, only
  when content changed. Env items go to `$XDG_STATE_HOME/secrets/<name>.env`
  (mode 600), which `run`, `aws` and `media-deploy` read without the vault.
- Deploy (`post_deploy`) runs `secrets pull --if-unlocked`: refresh when the
  agent is unlocked, silent no-op when locked. That is "ask only when something
  changed": after editing in the app, the owner runs `secrets pull` once.
- `secrets put <item> [file]`: creates or replaces an item from a file or
  stdin, never echoing it. SSH keys go in as a Note named `ssh key <name>`
  because rbw cannot create SSH Key items; reading handles both types.
- `media-deploy` keys it generates go to the vault with `secrets put env media`.
- `secrets check`: rbw installed, local copies present and mode 600, files in
  `~/.ssh/keys` with no vault item, and (when unlocked) local copies older than
  the vault.
- `vault` drops `bw`: `ls`, `folders`, `dupes`, `add`, `rm`, `note`, `run`,
  `env` move to rbw. `mv` and `rename` are removed; done in the app.
- Removing an item is only through the app or `vault rm`, which agents call
  only after asking.

## Migration

1. **Keys diverge.** The existing vault items `SSH pessoal` and `SSH Unimed`
   do not match the keys in use (`~/.ssh/keys/personal`, `unimed`, by
   fingerprint). The repo copies are the live ones. Migration imports the
   repo keys as new `ssh key <name>` items; the two old items are the owner's
   call (likely stale, keep until confirmed).
2. One-off script: decrypt each file in `secrets/` with sops and pipe it into
   `secrets put`, printing only names and hashes.
3. `secrets pull` on both PCs, compare hashes of every target with the sops
   output, then check `aws sts get-caller-identity`, `ssh -T git@github.com`,
   `ssh fedora`, `ssh arch`, `media-deploy --check`.
4. Copy the `age (dotfiles)` item into `Dotfiles/age backup`. Remove
   `secrets/`, `.sops.yaml`, sops from packages, `~/.config/sops` from both PCs,
   `bw` and the MCP entry. age stays (media backup). The `age (dotfiles)` item
   stays until the owner decides: it also opens the files in git history.

## Trade-offs accepted

- No git history of secret changes; Bitwarden keeps password history only.
- A lost Bitwarden account loses everything. Mitigation is the owner's choice
  (open question below).
- Plain copies stay on disk (`~/.ssh`, state dir, `media.env`) because the media
  stack and PC to PC SSH run with nobody logged in. Same as today.

## Open question

- Offline backup: periodic encrypted `rbw`/app export kept off the PC, or the
  Bitwarden emergency kit only.

## Tests

`tests/secrets.sh` uses a fake `rbw` on `PATH` backed by a JSON fixture: pull
writes only changed files with mode 600, locked agent is a no-op, put never
echoes, unknown prefixes are ignored, `check` flags strays.
`tests/media_deploy.sh` swaps sops for the same fake.
