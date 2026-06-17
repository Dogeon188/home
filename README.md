# Home Directory Config

Configuration files for a functional shell environment. Supports both **Zsh** and **Bash**.

## Installation

First, clone this repository into your home directory and set up the Git remote:

```sh
cd ~
git init
git remote add origin git@github.com:Dogeon188/home.git
git fetch origin
git branch -m main
```

Then, check which local files will be overwritten:

```sh
git diff HEAD..origin/main --name-only
```

Back up anything you want to keep, then apply:

```sh
git reset --hard origin/main
git branch --set-upstream-to=origin/main
```

### Change Shell

1. Install Zsh or Bash if not already installed.
2. Change your default shell:

   ```sh
   chsh -s $(which zsh)  # or $(which bash)
   ```

### Tmux

1. Install [TPM](https://github.com/tmux-plugins/tpm):

   ```sh
   git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
   ```

2. Start tmux and press `prefix + I` to install plugins.

## What's Included

| File         | Description                                                                                                          |
| ------------ | -------------------------------------------------------------------------------------------------------------------- |
| `.zshrc`     | Zsh config — [zplug](https://github.com/zplug/zplug) plugins, [p10k](https://github.com/romkatv/powerlevel10k) theme |
| `.bashrc`    | Bash config — [Starship](https://starship.rs) prompt, eza aliases                                                    |
| `.p10k.zsh`  | Powerlevel10k theme settings (Zsh only)                                                                              |
| `.tmux.conf` | Tmux config with TPM plugins                                                                                         |

### Dependencies

Core: `git`, `tmux`, [`tpm`](https://github.com/tmux-plugins/tpm)

Shell-specific:

- **Zsh**: `zsh`, [`zplug`](https://github.com/zplug/zplug)
- **Bash**: [`starship`](https://starship.rs) (optional, falls back to git-aware prompt)

Optional tools (both shells benefit from these):

- [`uv`](https://docs.astral.sh/uv/) — Python package manager
- [`bun`](https://bun.com) — JavaScript runtime
- [`fzf`](https://github.com/junegunn/fzf) — Fuzzy finder
- [`eza`](https://github.com/eza-community/eza) — Modern `ls` replacement
- [`zoxide`](https://github.com/ajeetdsouza/zoxide) — Smart `cd`
- [`bat`](https://github.com/sharkdp/bat) — `cat` with syntax highlighting
