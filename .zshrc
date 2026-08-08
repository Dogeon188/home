## 1. ENVIRONMENT VARIABLES

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export EDITOR='nano'

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
path=("$HOME/.local/bin" "$HOME/.cargo/bin" "$BUN_INSTALL/bin" "$HOME/go/bin" "/opt/homebrew/bin" $path)
fpath=("$HOME/.zfunc" "$HOME/.zsh/completions" $fpath)

## 2. PLUGINS

ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

if [[ ! -d $ZINIT_HOME ]]; then
    printf "Install zinit? [y/N]: "
    if read -q; then
        mkdir -p "${ZINIT_HOME:h}"
        git clone --depth 1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
    fi
fi

if [[ -f $ZINIT_HOME/zinit.zsh ]]; then
    source "$ZINIT_HOME/zinit.zsh"

    zinit ice depth:1
    zinit light romkatv/powerlevel10k

    # `wait lucid` = turbo: loads in the background once the prompt is up
    zinit wait lucid for \
        MichaelAquilina/zsh-you-should-use \
        ocodo/ollama_zsh_completion \
        atload'_zsh_autosuggest_start' \
            zsh-users/zsh-autosuggestions \
        atload'zicdreplay' \
            zsh-users/zsh-syntax-highlighting

    # Eager: only appends to fpath, which has to happen before compinit below
    zinit ice blockf
    zinit light zsh-users/zsh-completions

    zinit wait lucid for \
        OMZP::colored-man-pages \
        OMZP::ssh \
        OMZP::zoxide

    if command -v eza &>/dev/null; then
        zinit wait lucid for z-shell/zsh-eza
    else
        printf "eza not found, skipping zsh-eza plugin. Install it from https://github.com/eza-community/eza \n"
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macos.plugin.zsh sources siblings (music, spotify) from its own
        # directory, which an OMZP:: snippet does not fetch
        zinit ice wait lucid depth:1 pick"plugins/macos/macos.plugin.zsh"
        zinit light ohmyzsh/ohmyzsh
    elif [[ -f /etc/debian_version ]]; then
        zinit wait lucid for OMZP::apt
    fi
else
    echo "[zshrc] zinit not installed — skipping plugins"
fi

## 3. COMPLETION SYSTEM

autoload -Uz compinit
if [[ -n "${ZDOTDIR:-$HOME}/.zcompdump"(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

zstyle ':completion:*' menu select  # Enable menu selection for completions
zstyle ':completion:*' verbose yes  # Show descriptions for completions
zstyle ':completion:*' matcher-list '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'  # Enable case-insensitive and from-middle matching
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}  # Use LS_COLORS for coloring completions
zstyle ':completion:*' use-cache on  # Enable caching for completions
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/.zcompcache"  # Set cache path for completions
zstyle ':completion:*' completer _extensions _complete _approximate  # Enable approximate completion

# Set colors for completion
if [[ "$OSTYPE" == "linux"* ]] && (( $+commands[dircolors] )); then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi

zstyle ':completion:*:descriptions' format '%F{green}-- %d --%f'
zstyle ':completion:*:corrections' format '%F{yellow}-- %d (errors: %e) --%f'
zstyle ':completion:*:messages' format '%F{magenta}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}No matches for:%f %d'
zstyle ':completion:*' group-name ''

## 4. EXTERNAL TOOL INTEGRATIONS

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Initialize fzf key bindings and fuzzy completion
if command -v fzf >/dev/null; then
    if _fzf_init=$(fzf --zsh 2>/dev/null); then
        eval "$_fzf_init"
    else
        source /usr/share/doc/fzf/examples/key-bindings.zsh
        source /usr/share/doc/fzf/examples/completion.zsh
    fi
    unset _fzf_init
fi

# Initialize uv completion
if command -v uv &>/dev/null; then
    _uv_comp_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/_uv_completion"
    if [[ ! -f "$_uv_comp_cache" ]] || [[ "$(command -v uv)" -nt "$_uv_comp_cache" ]]; then
        mkdir -p "${_uv_comp_cache:h}"
        uv generate-shell-completion zsh >| "$_uv_comp_cache"
    fi
    source "$_uv_comp_cache"
    unset _uv_comp_cache
    
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

[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

# nvm (completion comes from zsh-users/zsh-completions' _nvm, not nvm's bash_completion)
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

## 5. ALIASES & FUNCTIONS

alias cls='clear'
alias md='mkdir -p'
command -v batcat >/dev/null && alias bat='batcat'
command -v ipython >/dev/null && alias ipy='ipython'

## 6. CUSTOM FUNCTIONS

tat() {
    local name=${PWD:t:gs/.//}

    if tmux has-session -t "$name" 2>/dev/null; then
        tmux attach -t "$name"
    elif [[ -f .envrc ]]; then
        direnv exec / tmux new-session -s "$name" -c "$PWD"
    else
        tmux new-session -s "$name" -c "$PWD"
    fi
}

zdir() {
    if [[ "$1" == (-h|--help) ]]; then
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

    if zip -r -q -9 "$zip_name" "$dir_raw" -x "*.DS_Store" -x "**/__MACOSX" -x "**/.git/*"; then
        print -P "%B%F{cyan} $dir_raw%f %F{white}󱦰%f %F{green} $zip_name%f%b"
    else
        print -P "%F{red}Error:%f Failed to zip '$dir_raw'"
        return 1
    fi
}

dsize() {
    if [[ "$1" == (-h|--help) ]]; then
        print -P "%F{yellow}Usage:%f dsize [directory]"
        print "Prints the size of the directory and its contents"
        print "If no directory is provided, the current directory is used"
        return 0
    fi

    local dir_name=${1:-.}
    local du_output
    du_output=$(du -d 1 -h "$dir_name" 2>/dev/null)

    if (( $(printf '%s\n' "$du_output" | wc -l) > 1 )); then
        printf '%s\n' "$du_output" |
        sort -rh |
        while read -r line; do
            print -P "%B%F{cyan}󰉋%f%b $line"
        done
    fi

    if [[ -n "$(find "$dir_name" -maxdepth 1 -type f -print -quit 2>/dev/null)" ]]; then
        find "$dir_name" -maxdepth 1 -type f -exec du -h {} + 2>/dev/null |
            sort -rh |
            while read -r line; do
                print -P "%B%F{green}%f%b $line"
            done
    fi
}
