# Home Directory Config

This repository contains necessary configuration files for setting up a good-looking and functional Z-shell environment.

## Installation

Should use ZSH as the default shell.

```sh
cd ~
git remote add origin git@github.com:Dogeon188/home.git
git fetch origin
git checkout -b main --track origin/main
git reset origin/main
```

## Content

- Uses [zplug](https://github.com/zplug/zplug) for plugin management.
- Uses [Powerlevel10k](https://github.com/romkatv/powerlevel10k) for theming.
- Assumes the following programs are installed:
  - `zsh`
  - `zplug`
  - `tmux`
  - `git`
  - [`uv`](https://docs.astral.sh/uv/) - Modern Python package manager
  - [`bun`](https://bun.com) - JavaScript runtime
  - [`fzf`](https://github.com/junegunn/fzf) - Fuzzy finder
  - [`eza`](https://github.com/eza-community/eza) - Modern replacement for `ls`
  - [`zoxide`](https://github.com/ajeetdsouza/zoxide) - Smart directory navigation
