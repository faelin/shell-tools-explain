#!/bin/zsh

echo "$(dirname "$(dirname "$(readlink -F "$0")")")"
_explain_path="$(realpath "${0:A}/./")/explain.sh"

source "$_explain_path"




zle -N expand-or-explain
bindkey '^E' expand-or-explain

zle -N expand-alias
bindkey ' '    expand-alias
bindkey '^ '   magic-space          # control-space to bypass completion
bindkey -M isearch " "  magic-space # normal space during searches

zstyle ':completion:*' completer _expand_alias _complete _ignored
zstyle ':completion:*' regular true
