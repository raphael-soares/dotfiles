# Backups through syncfast, one syncfast config per machine

## Intent

The owner wants the dotfiles to hold no backup mechanism of their own. syncfast already backs folders up with restic: encrypted, versioned, deduplicated, with retention and checks (syncfast ADR 0009). No backup is defined or configured now. The goal is a clean, solid setup: when the owner wants a backup later, it is one `syncfast backup add` on that machine, and the only dotfiles change is the config line syncfast writes.

## Goals

1. **One syncfast config per machine.** `desktop/syncfast/config.toml` is shared by both PCs today. A backup created on one machine would land in it and show up on the other, with missing folders and no key. Instead:
   - `laptop/syncfast/config.toml` is linked on the notebook (Arch, module `laptop`);
   - `home/syncfast/config.toml` is linked on the home PC (Fedora, module `home`);
   - both point to `~/.config/syncfast/config.toml`.
   syncfast follows the symlink when it writes, so changes made in the app still reach the right versioned file.
2. **The old mechanism goes away entirely.** `media-backup`, `media-restore-test`, `creative-backup`, their units, the age recipient, age itself, and the `age backup` entry of the secrets contract.

## Non-goals and anti-goals

- No backup defined, created or granted access now, on either machine.
- No script that declares or reconciles backups: the per-machine config is the declaration.
- Anti-goal: anything that makes a backup on one machine raise alerts on the other.
- Anti-goal: deleting remote data or vault items without asking.

## Design

**Split the config.**
- Move today's file to both machine modules with the same content.
- Swap the `desktop` entry in `.dotter/global.toml` for one entry per module.
- `tests/machines.sh` keeps checking the link on both machines.

**Remove the old mechanism:**
- `media/bin/media-backup`, `media/bin/media-restore-test`, `media/systemd/media-backup.{service,timer}`, `media/systemd/media-restore-test.{service,timer}`, `media/backup.recipient`;
- `creative/bin/creative-backup`, `creative/systemd/creative-backup.{service,timer}`;
- `age` from `media/packages.fedora.txt`;
- references in `media/bin/media-deploy` and its test;
- the `age backup` target in `terminal/bin/secrets`, its cases in `tests/secrets.sh`, and its lines in `ai/skills/cofre/SKILL.md` and `docs/machines.md`;
- the backup sections of `docs/media.md`, `docs/creative.md` and `docs/home.md`, rewritten to say backups are syncfast's, per machine. They also note that a folder of another Flatpak needs a `flatpak override` (syncfast says which);
- on Fedora, after deploy: disable the timers if enabled and trash `~/.config/age/backup.key`.

**Ask the owner, never decide alone:** deleting the vault items `Dotfiles/age backup` and `age (dotfiles)`, and any data under `Raphael:Backups/media` and `Raphael:Backups/fedora` (report first whether it exists).

## Approaches considered

- **Chosen: one syncfast config per machine.** The owner's call: the machines differ.
- A machine field on each backup in one shared config. Rejected by the owner.
- Unversioned syncfast config plus a dotfiles script. Rejected: changes made in the app would not reach git.
- Keep the old scripts with rclone `crypt` instead of age. Rejected: a second backup mechanism next to syncfast's.

## Order

1. Dotfiles: one commit on `main`. Verify with `bash tests/machines.sh arch`, `bash tests/machines.sh fedora`, `bash tests/secrets.sh`, `bash tests/media_deploy.sh`.
2. syncfast: spec `2026-11-26-backup-destination-inside-excluded-sync-design.md`, PR and release. Independent of step 1.
