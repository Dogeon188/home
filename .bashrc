## 0. INTERACTIVE GUARD

case $- in
    *i*) ;;
      *) return;;
esac

# ble.sh — syntax highlighting, autosuggestions, enhanced line editing
[[ -s ~/.local/share/blesh/ble.sh ]] && source ~/.local/share/blesh/ble.sh --noattach

## 1. ENVIRONMENT VARIABLES

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export EDITOR='nano'

# History config
HISTSIZE=10000
HISTFILESIZE=10000
HISTFILE=~/.bash_history
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend

# FZF default options
export FZF_DEFAULT_OPTS='--height 40% --layout reverse --border top --preview "fzf-preview.sh {}"'
if command -v fd >/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f -E ".venv" -E "node_modules" -E "__pycache__" -E ".cache" -E ".DS_Store"'
else
    export FZF_DEFAULT_COMMAND='find . -type f -not \( -path "*/\.git/*" -or -path "*/\.venv/*" -or -path "*/node_modules/*" -or -path "*/__pycache__/*" -or -path "*/.cache/*" -or -path "*/.DS_Store" \)'
fi

# Path config — deduplicate via associative array
export BUN_INSTALL="$HOME/.bun"
_prepend_path() {
    case ":$PATH:" in
        *:"$1":*) ;;
        *) PATH="$1:$PATH" ;;
    esac
}
_prepend_path "/opt/homebrew/bin"
_prepend_path "$HOME/go/bin"
_prepend_path "$BUN_INSTALL/bin"
_prepend_path "$HOME/.cargo/bin"
_prepend_path "$HOME/.local/bin"
_prepend_path "$HOME/.fzf/bin"
unset -f _prepend_path
export PATH

## 2. SHELL SETUP

# Make less handle non-text files
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Chroot identifier (Debian/Ubuntu)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

## 3. SHELL OPTIONS

shopt -s checkwinsize   # Update LINES/COLUMNS after each command
shopt -s globstar 2>/dev/null  # ** recursive glob (bash 4+)
shopt -s cdspell        # Autocorrect minor cd typos
shopt -s dirspell 2>/dev/null  # Autocorrect directory name typos in completion

# Readline completion enhancements (zsh completion styles equivalent)
bind 'set show-all-if-ambiguous on'
bind 'set completion-ignore-case on'
bind 'set colored-stats on'
bind 'set colored-completion-prefix on'
bind 'set mark-symlinked-directories on'
bind 'set visible-stats on'
bind 'TAB:menu-complete'
bind '"\e[Z":menu-complete-backward'

## 4. COMPLETION SYSTEM

if [[ -r /opt/homebrew/etc/profile.d/bash_completion.sh ]]; then
    source /opt/homebrew/etc/profile.d/bash_completion.sh
elif [[ -r /usr/share/bash-completion/bash_completion ]]; then
    source /usr/share/bash-completion/bash_completion
elif [[ -r /etc/bash_completion ]]; then
    source /etc/bash_completion
fi

# Docker completions (if docker installed)
if command -v docker &>/dev/null; then
    if [[ -r /opt/homebrew/etc/bash_completion.d/docker ]]; then
        source /opt/homebrew/etc/bash_completion.d/docker
    fi
fi

## 5. EXTERNAL TOOL INTEGRATIONS

# Starship prompt (cross-shell replacement for Powerlevel10k)
if command -v starship >/dev/null; then
    eval "$(starship init bash)"
else
    # Fallback: git-aware colored prompt
    _parse_git_branch() {
        local branch
        branch=$(git symbolic-ref --short HEAD 2>/dev/null) || return
        printf ' (%s)' "$branch"
    }
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[33m\]$(_parse_git_branch)\[\033[00m\]\$ '
fi

# Initialize fzf key bindings and fuzzy completion
if command -v fzf >/dev/null; then
    if [[ ${BLE_VERSION-} ]]; then
        # Use ble.sh's fzf integration to avoid compatibility issues
        ble-import -d integration/fzf-completion
        ble-import -d integration/fzf-key-bindings
    else
        eval "$(fzf --bash 2>/dev/null)" || {
            [[ -f ~/.fzf.bash ]] && source ~/.fzf.bash
        }
    fi
fi

# Initialize uv completion
if command -v uv &>/dev/null; then
    _uv_comp_cache="${XDG_CACHE_HOME:-$HOME/.cache}/bash/_uv_completion"
    mkdir -p "$(dirname "$_uv_comp_cache")"
    if [[ ! -f "$_uv_comp_cache" ]] || [[ "$(command -v uv)" -nt "$_uv_comp_cache" ]]; then
        uv generate-shell-completion bash >| "$_uv_comp_cache"
    fi
    source "$_uv_comp_cache"
    unset _uv_comp_cache

    # Wrap uv completion to autocomplete .py files for `uv run`
    __uv_orig_comp=$(complete -p uv 2>/dev/null | sed 's/.*-F \([^ ]*\).*/\1/')
    if [[ -n "$__uv_orig_comp" ]]; then
        _uv_run_wrapper() {
            if [[ "${COMP_WORDS[1]}" == "run" && "${COMP_WORDS[COMP_CWORD]}" != -* ]]; then
                local cur="${COMP_WORDS[COMP_CWORD]}"
                COMPREPLY=( $(compgen -f -X '!*.py' -- "$cur") $(compgen -d -- "$cur") )
            else
                "$__uv_orig_comp" "$@"
            fi
        }
        complete -F _uv_run_wrapper uv
    fi
fi

# Initialize bun completions
if [[ -s "$BUN_INSTALL/_bun" ]]; then
    # bun's completion script auto-detects the shell
    source "$BUN_INSTALL/_bun" 2>/dev/null
fi

# Initialize zoxide (if available)
if command -v zoxide >/dev/null; then
    eval "$(zoxide init bash)"
fi

# Colored man pages (oh-my-zsh colored-man-pages equivalent)
export LESS_TERMCAP_mb=$'\e[1;31m'
export LESS_TERMCAP_md=$'\e[1;36m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_so=$'\e[1;44;33m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;32m'
export LESS_TERMCAP_ue=$'\e[0m'

# eza aliases (replacement for zsh-eza plugin)
if command -v eza &>/dev/null; then
    alias ls='eza'
    alias ll='eza -l --git'
    alias la='eza -la --git'
    alias lt='eza --tree --level=2'
    alias l='eza -1'
fi

## 6. ALIASES & FUNCTIONS

alias cls='clear'
alias md='mkdir -p'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
command -v batcat >/dev/null && alias bat='batcat'
command -v ipython >/dev/null && alias ipy='ipython'
alias als='alias | sort'

## 7. CUSTOM FUNCTIONS

# Colors for use in functions
_RED='\033[0;31m'
_GREEN='\033[0;32m'
_YELLOW='\033[0;33m'
_CYAN='\033[0;36m'
_BOLD_CYAN='\033[1;36m'
_BOLD_GREEN='\033[1;32m'
_WHITE='\033[0;37m'
_BOLD='\033[1m'
_RESET='\033[0m'

# tat: tmux attach
tat() {
    local name
    name=$(basename "$PWD" | tr -d '.')

    if tmux ls 2>&1 | grep -q "$name"; then
        tmux attach -t "$name"
    elif [[ -f .envrc ]]; then
        direnv exec / tmux new-session -s "$name"
    else
        tmux new-session -s "$name"
    fi
}

zdir() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        printf "${_YELLOW}Usage:${_RESET} zdir [directory] (output_file)\n"
        echo "Zips the directory into a zip file"
        return 0
    fi

    if [[ ! -d "$1" ]]; then
        printf "${_RED}Error:${_RESET} '%s' is not a valid directory.\n" "$1"
        return 1
    fi

    local dir_raw="${1%/}"
    local dir_name="${dir_raw##*/}"
    local zip_name="${2:-${dir_name}.zip}"

    if zip -r -q -9 "$zip_name" "$dir_raw" -x "*.DS_Store" -x "**/__MACOSX" -x "**/.git/*"; then
        printf "${_BOLD}${_CYAN} %s${_RESET} ${_WHITE}󱦰${_RESET} ${_GREEN} %s${_RESET}${_RESET}\n" "$dir_raw" "$zip_name"
    else
        printf "${_RED}Error:${_RESET} Failed to zip '%s'\n" "$dir_raw"
        return 1
    fi
}

dsize() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        printf "${_YELLOW}Usage:${_RESET} dsize [directory]\n"
        echo "Prints the size of the directory and its contents"
        echo "If no directory is provided, the current directory is used"
        return 0
    fi

    local dir_name="${1:-.}"

    # Cache the du output
    local du_output
    du_output=$(du -d 1 -h "$dir_name" 2>/dev/null)

    # Folders
    if [[ $(printf '%s\n' "$du_output" | wc -l) -gt 1 ]]; then
        printf '%s\n' "$du_output" |
        sort -rh |
        while IFS= read -r line; do
            printf "${_BOLD_CYAN}󰉋${_RESET} %s\n" "$line"
        done
    fi

    # Files
    if [[ -n "$(find "$dir_name" -maxdepth 1 -type f -print -quit 2>/dev/null)" ]]; then
        find "$dir_name" -maxdepth 1 -type f -exec du -h {} + 2>/dev/null |
            sort -rh |
            while IFS= read -r line; do
                printf "${_BOLD_GREEN}${_RESET} %s\n" "$line"
            done
    fi
}

# macOS utilities (oh-my-zsh macos plugin equivalent)
if [[ "$OSTYPE" == "darwin"* ]]; then
    ofd() { open "${1:-.}"; }
    cdf() { cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)' 2>/dev/null)" || return; }
fi

## 8. LOCAL ENVIRONMENT

[[ -s "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

[[ ${BLE_VERSION-} ]] && ble-attach
