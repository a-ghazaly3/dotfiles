# dotfiles

Personal dotfiles managed with **GNU Stow**. Each top-level directory is a
"package" whose tree mirrors where the files land relative to `$HOME`.

## New machine

```sh
git clone --recurse-submodules git@github.com:a-ghazaly3/dotfiles.git ~/dotfiles
~/dotfiles/bootstrap.sh
exec zsh
```

`bootstrap.sh` installs missing tools via Homebrew, installs oh-my-zsh,
initialises submodules, and stows every package.

```sh
./bootstrap.sh --dry-run     # preview, change nothing
./bootstrap.sh --skip-tools  # only submodules + symlinks
./bootstrap.sh --adopt       # pull existing real files into packages
./bootstrap.sh zsh nvim      # only stow these packages
```

## Packages

| Package   | Lands at |
|-----------|----------|
| `zsh`     | `~/.zshrc`, `~/.zshenv`, `~/.zprofile` |
| `bash`    | `~/.bashrc` |
| `git`     | `~/.gitconfig` |
| `tmux`    | `~/.config/tmux/tmux.conf` |
| `yazi`    | `~/.config/yazi/*` |
| `lazygit` | `~/.config/lazygit/config.yml` |
| `gh`      | `~/.config/gh/config.yml` |
| `nvim`    | `~/.config/nvim` → git submodule |

## Everyday use

```sh
cd ~/dotfiles
stow <pkg>        # link a package
stow -D <pkg>     # unlink a package
stow -R <pkg>     # re-link after changing structure
stow -n -v <pkg>  # dry run
```

To add a package: create `~/dotfiles/<name>/`, place files at their
target-relative path, move the real files in, then `stow <name>`.

## Neovim

`nvim/.config/nvim` is a git **submodule** pointing at
`github.com/a-ghazaly3/new-nvim`. Edit config normally through
`~/.config/nvim`, but commit in the submodule first, then bump the pointer:

```sh
cd ~/.config/nvim && git add -A && git commit -m "..." && git push
cd ~/dotfiles && git add nvim && git commit -m "Bump nvim" && git push
```

## Secrets

These are intentionally **not** tracked and are listed in `.gitignore`:

- `~/.config/gh/hosts.yml` (OAuth token)
- `~/.config/opencode/service.json` (password)
