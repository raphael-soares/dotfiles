# Machines in detail

## What the deploy does besides links

`.dotter/post_deploy.sh` runs after every `dotter deploy`, only for the modules
the machine has:

- installs missing packages from `<module>/packages.<distro>.txt` (`yay`/`pacman`
  on Arch, `dnf` on Fedora);
- copies the Fuxi-H3 udev rule and the greetd config to `/etc` with sudo;
- sets gsettings, `gcr-ssh-agent`, the work omp profile, and reloads Hyprland.

`DOTFILES_LINKS_ONLY=1 dotter deploy` creates only the links.

## First run

`.dotter/adopt.sh` removes old links into the repo (from stow), moves every
real file in the way to `~/.dotfiles-backup/<date>/` and deploys. Nothing is
deleted.

## Fuxi-H3 on the `fedora` machine

Before trusting the rules with the dongle, check that it shows up like the
cable does:

- `lsusb` lists ID `040b:0897` (what the udev rule matches);
- `wpctl status` lists a device named `Fuxi-H3-00` (what
  `55-fuxi-soft-mixer.conf` matches).

## Secrets

Kept out of the repo, in `~/.env.local` (created from `.env.example` on the
first deploy) and `~/.bash_profile.local`.

## Tests

`tests/machines.sh arch`, `tests/machines.sh fedora` and `tests/adopt.sh`
deploy into a fake HOME and check what each machine gets.

## Visual

Desktop design decisions live in [`design-system.md`](design-system.md).
