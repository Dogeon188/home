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

## Tool Installation

### Tmux

1. Install [TPM](https://github.com/tmux-plugins/tpm):

   ```sh
   git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
   ```

2. Start tmux and press `prefix + I` to install plugins.

### Zsh

```sh
# zplug
curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
```

### Bash

```sh
# ble.sh
git clone --recursive --depth 1 --shallow-submodules https://github.com/akinomyoga/ble.sh.git
make -C ble.sh install PREFIX=~/.local

# starship
curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir ~/.local/bin
# OR
cargo install starship --locked
```

### Optional Tools

```sh
# uv — Python package manager
curl -LsSf https://astral.sh/uv/install.sh | sh

# bun — JavaScript runtime
curl -fsSL https://bun.sh/install | bash

# cargo — Rust package manager
curl https://sh.rustup.rs -sSf | sh

# fzf — fuzzy finder
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install

# eza — modern ls replacement
brew install eza          # macOS
cargo install eza         # Linux

# zoxide — smart cd
cargo install zoxide --locked

# bat — cat with syntax highlighting
brew install bat          # macOS
cargo install bat         # Linux
```

> For `cargo` installs on Linux: install Rust first with `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`

## What's Included

| File         | Description                                                                                                          |
| ------------ | -------------------------------------------------------------------------------------------------------------------- |
| `.zshrc`     | Zsh config — [zplug](https://github.com/zplug/zplug) plugins, [p10k](https://github.com/romkatv/powerlevel10k) theme |
| `.bashrc`    | Bash config — [ble.sh](https://github.com/akinomyoga/ble.sh), [Starship](https://starship.rs) prompt, eza aliases    |
| `.p10k.zsh`  | Powerlevel10k theme settings (Zsh only)                                                                              |
| `.tmux.conf` | Tmux config with TPM plugins                                                                                         |

### Dependencies

Core: `git`, `tmux`, [`tpm`](https://github.com/tmux-plugins/tpm)

Shell-specific:

- **Zsh**: `zsh`, [`zplug`](https://github.com/zplug/zplug)
- **Bash**: [`ble.sh`](https://github.com/akinomyoga/ble.sh) (syntax highlighting + autosuggestions), [`starship`](https://starship.rs) (optional, falls back to git-aware prompt)

Optional tools (both shells benefit from these):

- [`uv`](https://docs.astral.sh/uv/) — Python package manager
- [`bun`](https://bun.com) — JavaScript runtime
- [`fzf`](https://github.com/junegunn/fzf) — Fuzzy finder
- [`eza`](https://github.com/eza-community/eza) — Modern `ls` replacement
- [`zoxide`](https://github.com/ajeetdsouza/zoxide) — Smart `cd`
- [`bat`](https://github.com/sharkdp/bat) — `cat` with syntax highlighting
