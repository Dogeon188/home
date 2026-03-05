
## 1. POWERLEVEL10K INSTANT PROMPT (Must stay at the very top)

# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
# source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

## 2. ENVIRONMENT VARIABLES

# Set defaults if not already set in .zshenv

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export EDITOR='nano'  # Preferred editor for local and remote sessions

# History config
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS SHARE_HISTORY

# FZF default options
export FZF_DEFAULT_OPTS='--height 40% --layout reverse --border top --preview "fzf-preview.sh {}"'
if command -v fd >/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f -E ".venv" -E "node_modules" -E "__pycache__" -E ".cache" -E ".DS_Store"'
else
    export FZF_DEFAULT_COMMAND='find . -type f -not \( -path "*/\.git/*" -or -path "*/\.venv/*" -or -path "*/node_modules/*" -or -path "*/__pycache__/*" -or -path "*/.cache/*" -or -path "*/.DS_Store" \)'
fi

# Path config
typeset -U path fpath
export BUN_INSTALL="$HOME/.bun"
# export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$BUN_INSTALL/bin:$HOME/go/bin:$PATH"
path=("$HOME/.local/bin" "$HOME/.cargo/bin" "$BUN_INSTALL/bin" "$HOME/go/bin" "/opt/homebrew/bin" $path)
fpath=("$HOME/.zfunc" "$HOME/.zsh/completions" $fpath)

## 3. PLUGINS

if [[ ! -d ~/.zplug ]]; then
    printf "Install zplug? [y/N]: "
    if read -q; then
        curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
    fi
fi

source ~/.zplug/init.zsh

zplug 'zplug/zplug', hook-build:'zplug --self-manage'
zplug "romkatv/powerlevel10k", as:theme, depth:1  # Powerlevel10k theme
zplug "MichaelAquilina/zsh-you-should-use"  # Suggest aliases when you type a command that has an alias
zplug "ocodo/ollama_zsh_completion"  # Ollama completions for zsh
zplug "zsh-users/zsh-autosuggestions"  # Suggest commands as you type based on history and completions
zplug "zsh-users/zsh-syntax-highlighting", defer:2
zplug "zsh-users/zsh-completions"  # Additional completion definitions for various commands

zplug "plugins/aliases", from:oh-my-zsh  # Use `als` to list all aliases
zplug "plugins/colored-man-pages", from:oh-my-zsh  # Colorize man
# zplug "plugins/common-aliases", from:oh-my-zsh  # Common aliases for various commands
zplug "plugins/docker", from:oh-my-zsh  # Docker completions and aliases
zplug "plugins/emoji", from:oh-my-zsh  # Adds emoji autocompletion
zplug "plugins/ssh", from:oh-my-zsh  # SSH completions and utility functions
zplug "plugins/zoxide", from:oh-my-zsh  # Initialize zoxide for fast directory navigation

if command -v eza &> /dev/null; then
    zplug "z-shell/zsh-eza"
else
    printf "eza not found, skipping zsh-eza plugin. Install it from https://github.com/eza-community/eza \n"
fi

# OS Specifics
if [[ "$OSTYPE" == "darwin"* ]]; then
    zplug "plugins/macos", from:oh-my-zsh
elif [[ -f /etc/debian_version ]]; then
    zplug "plugins/apt", from:oh-my-zsh
fi

# Install plugins if they are not already installed
if ! zplug check; then
    zplug install
fi
zplug load

# 4. COMPLETION SYSTEM

# https://unix.stackexchange.com/a/214699
# https://thevaluable.dev/zsh-completion-guide-examples/

autoload -Uz compinit
for dump in "${ZDOTDIR:-$HOME}/.zcompdump"(N.mh+24); do
  compinit
done
compinit -C

zstyle ':completion:*' menu select  # Enable menu selection for completions
zstyle ':completion:*' verbose yes  # Show descriptions for completions
zstyle ':completion:*' matcher-list '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'  # Enable case-insensitive and from-middle matching
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}  # Use LS_COLORS for coloring completions
zstyle ':completion:*' use-cache on  # Enable caching for completions
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompcache"  # Set cache path for completions
zstyle ':completion:*' completer _extensions _complete _approximate  # Enable approximate completion

# Set colors for completion
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

zstyle ':completion:*:descriptions' format "$fg[green]-- %d --$reset_color"
zstyle ':completion:*:corrections' format "$fg[yellow]-- %d (errors: %e) --$reset_color"
zstyle ':completion:*:messages' format "$fg[purple]-- %d --$reset_color"
zstyle ':completion:*:warnings' format "$fg[red]No matches for:$reset_color %d"
zstyle ':completion:*' group-name ''

# 5. EXTERNAL TOOL INTEGRATIONS

# Load Powerlevel10k theme configuration if it exists
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Initialize fzf key bindings and fuzzy completion
if command -v fzf >/dev/null; then
    source <(fzf --zsh)
fi

# Initialize uv completion
if command -v uv &> /dev/null; then
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
fi

# Initialize bun completions
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"


# OpenClaw Completion
source "/Users/dogeon/.openclaw/completions/openclaw.zsh"

# 6. ALIASES & FUNCTIONS

alias cls='clear'
alias md='mkdir -p'
command -v batcat >/dev/null && alias bat='batcat'
command -v ipython >/dev/null && alias ipy='ipython'

# ## ====== Custom Functions ======

# tat: tmux attach
function tat {
    local name=$(basename "$PWD" | tr -d '.')

    if tmux ls 2>&1 | grep "$name"; then
        tmux attach -t "$name"
    elif [ -f .envrc ]; then
        direnv exec / tmux new-session -s "$name"
    else
        tmux new-session -s "$name"
    fi
}

function zdir() {
    zparseopts -D -E h=help
    if [[ "$help" ]]; then
        print -P "%F{yellow}Usage:%f zdir [directory] (output_file)"
        print "Zips the directory into a zip file"
        return 0
    fi

    if [[ ! -d "$1" ]]; then
        print -P "%F{red}Error:%f '$1' is not a valid directory."
        return 1
    fi

    local dir_raw=${1%/}
    local dir_name=${dir_raw:t}
    local zip_name=${2:-${dir_name}.zip}

    typeset DIR_NAME=$1
    typeset ZIP_NAME=${2:-$(basename "$DIR_NAME")}.zip
    
    if zip -r -q -9 "$zip_name" "$dir_raw" -x "*.DS_Store" -x "**/__MACOSX" -x "**/.git/*"; then
        print -P "%B%F{cyan} $dir_raw%f %F{white}󱦰%f %F{green} $zip_name%f%b"
    else
        print -P "%F{red}Error:%f Failed to zip '$dir_raw'"
        return 1
    fi
}

function dsize() {
    zparseopts -D -E h=help
    if [[ "$help" ]]; then
        print -P "%F{yellow}Usage:%f dsize [directory]"
        print "Prints the size of the directory and its contents"
        print "If no directory is provided, the current directory is used"
        return 0
    fi

    local dir_name=${1:-.}

    # Cache the du output
    du_output=$(du -d 1 -h "$dir_name" 2&>/dev/null)

    # Folders
    # Only process if there is more than one entry
    if [ "$(printf '%s\n' "$du_output" | wc -l)" -gt 1 ]; then
        printf '%s\n' "$du_output" |
        sort -rh |
        while read -r line; do
            echo "$fg_bold[cyan]󰉋$reset_color $line"
        done
    fi

    # Files
    if [ $(find "$dir_name" -maxdepth 1 -type f | wc -l) -gt 0 ]; then
        find "$dir_name" -maxdepth 1 -type f -exec du -h {} + 2&>/dev/null |
            sort -rh |
            while read -r line; do
                echo "$fg_bold[green]$reset_color $line"
            done
    fi
}
