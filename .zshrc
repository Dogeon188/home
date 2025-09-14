## ====== Environment Variables ======

    # You may need to manually set your language environment
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    export LC_CTYPE=en_US.UTF-8

    # Preferred editor for local and remote sessions
    if [[ -n $SSH_CONNECTION ]]; then # Remote session
        export EDITOR='nano'
    else # Local session
        export EDITOR='nano'
    fi

    export FZF_DEFAULT_OPTS='--height 40% --layout reverse --border top --preview "fzf-preview.sh {}"'
    export FZF_DEFAULT_COMMAND='find . -type f -not \( -path "*/\.git/*" -or -path "*/\.venv/*" -or -path "*/node_modules/*" -or -path "*/__pycache__/*" -or -path "*/.cache/*" -or -path "*/.DS_Store" \)'

    export BUN_INSTALL="$HOME/.bun"
    export PATH="$HOME/.local/bin:/opt/homebrew/bin:$HOME/.cargo/bin:$BUN_INSTALL/bin:$PATH"

    # History config
    HISTSIZE=10000
    SAVEHIST=10000
    HISTFILE=~/.zsh_history

    # Homebrew environment
    if command -v brew >/dev/null 2>&1; then
        eval "$(brew shellenv)"
    fi

    # Rust environment
    if [ -d "$HOME/.cargo" ]; then
        . "$HOME/.cargo/env"
    fi

    # fzf environment
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

## ====== Plugins ======

    # # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
    # # Initialization code that may require console input (password prompts, [y/n]
    # # confirmations, etc.) must go above this block; everything else may go below.
    # if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    # source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
    # fi

    source ~/.zplug/init.zsh

    zplug 'zplug/zplug', hook-build:'zplug --self-manage'
    zplug "romkatv/powerlevel10k", as:theme, depth:1
    zplug "MichaelAquilina/zsh-you-should-use"
    zplug "Katrovsky/zsh-ollama-completion"
    zplug "z-shell/zsh-eza"
    zplug "zsh-users/zsh-autosuggestions"
    zplug "zsh-users/zsh-completions"
    zplug "zsh-users/zsh-history-substring-search"
    zplug "zsh-users/zsh-syntax-highlighting", defer:2
    zplug "plugins/aliases", from:oh-my-zsh
    zplug "plugins/colored-man-pages", from:oh-my-zsh
    zplug "plugins/git", from:oh-my-zsh
    zplug "plugins/qrcode", from:oh-my-zsh
    zplug "plugins/ssh", from:oh-my-zsh
    zplug "plugins/urltools", from:oh-my-zsh
    zplug "plugins/web-search", from:oh-my-zsh
    zplug "plugins/zoxide", from:oh-my-zsh

    # MacOS-specific plugins
    # if [[ $(uname) == "Darwin" ]]; then
    zplug "plugins/macos", from:oh-my-zsh
    # fi

    # Ubuntu-specific plugins
    # if [[ $(uname) == "Linux" && $(lsb_release -si 2&>/dev/null) == "Ubuntu" ]]; then
    zplug "plugins/apt", from:oh-my-zsh
    zplug "plugins/ubuntu", from:oh-my-zsh
    # fi

    # Install packages that have not been installed yet
    if ! zplug check --verbose; then
        printf "Install? [y/N]: "
        if read -q; then
            echo; zplug install
        else
            echo
        fi
    fi
    zplug load

## ====== Plugin Configuration ======

    # To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
    [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

## ====== Completion and Key Bindings ======

    # Initialize uv completion
    eval "$(uv generate-shell-completion zsh)"
    # Fix completions for uv run to autocomplete .py files
    _uv_run_mod() {
        if [[ "$words[2]" == "run" && "$words[CURRENT]" != -* ]]; then
            _arguments '*:filename:_files -g "*.py"'
        else
            _uv "$@"
        fi
    }
    compdef _uv_run_mod uv

    # Initialize fzf key bindings and fuzzy completion
    if fzf --zsh &> /dev/null; then
        source <(fzf --zsh)
    else
        source /usr/share/doc/fzf/examples/key-bindings.zsh
        source /usr/share/doc/fzf/examples/completion.zsh
    fi

    # Initialize bun completions
    [ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"
    
    # https://unix.stackexchange.com/a/214699
    # https://thevaluable.dev/zsh-completion-guide-examples/

    zstyle ':completion:*' verbose yes
    zstyle ':completion:*' menu select

     # Set colors for completion
    if [ -x /usr/bin/dircolors ]; then
        test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    fi
    zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

    zstyle ':completion:*:descriptions' format "$fg[green]-- %d --$reset_color"
    zstyle ':completion:*:corrections' format "$fg[yellow]-- %d (errors: %e) --$reset_color"
    zstyle ':completion:*:messages' format "$fg[purple]-- %d --$reset_color"
    zstyle ':completion:*:warnings' format "$fg[red]No matches for:$reset_color %d"
    zstyle ':completion:*' group-name ''

    # Enable approximate completion
    zstyle ':completion:*' completer _extensions _complete _approximate

    # Enable case-insensitive & from-middle matching
    zstyle ':completion:*' matcher-list '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'

    # Enable caching for completion
    zstyle ':completion:*' use-cache on
    zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompcache"

## ====== Custom Aliases ======

    alias cls=clear
    alias md=mkdir
    alias ipy=ipython
    if command -v batcat &> /dev/null; then
        # On Ubuntu
        alias cat=batcat
        alias bat=batcat
    else
        # On macOS (Homebrew)
        alias cat=bat
    fi

## ====== Custom Functions ======

    # tat: tmux attach
    function tat {
        name=$(basename `pwd` | sed -e 's/\.//g')

        if tmux ls 2>&1 | grep "$name"; then
            tmux attach -t "$name"
        elif [ -f .envrc ]; then
            direnv exec / tmux new-session -s "$name"
        else
            tmux new-session -s "$name"
        fi
    }

    function zdir() {
        if [ "$1" = "-h" ]; then
            echo "Usage: zdir [directory] (output_file)"
            echo "Zips the directory into a zip file"
            return 0
        fi
        typeset DIR_NAME=$1
        typeset ZIP_NAME=${2:-$(basename "$DIR_NAME")}.zip
        if [ -z "$DIR_NAME" ]; then
            echo "No directory provided"
            return 1
        fi
        zip -r -q "$ZIP_NAME" "$DIR_NAME" -x "*.DS_Store" -x "**/__MACOSX" &&
            echo "$fg_bold[cyan] $DIR_NAME$reset_color 󱦰 $fg_bold[green] $ZIP_NAME$reset_color"
    }

    function dsize() {
        if [ "$1" = "-h" ]; then
            echo "Usage: dsize (directory)"
            echo "Prints the size of the directory and its contents"
            echo "If no directory is provided, the current directory is used"
            return 0
        fi
        typeset DIR_NAME=${1:-.}

        # Cache the du output
        du_output=$(du -d 1 -h "$DIR_NAME" 2&>/dev/null)

        # Only process if there is more than one entry
        if [ "$(printf '%s\n' "$du_output" | wc -l)" -gt 1 ]; then
            printf '%s\n' "$du_output" |
            sort -rh |
            while read -r line; do
                echo "$fg_bold[cyan]󰉋$reset_color $line"
            done
        fi
        if [ $(find "$DIR_NAME" -maxdepth 1 -type f | wc -l) -gt 0 ]; then
            find "$DIR_NAME" -maxdepth 1 -type f -exec du -h {} + 2&>/dev/null |
                sort -rh |
                while read -r line; do
                    echo "$fg_bold[green]$reset_color $line"
                done
        fi
    }
