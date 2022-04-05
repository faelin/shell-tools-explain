#!/bin/zsh


# used for zle widgets
expand-or-explain () {
  local lh="$(echo $LBUFFER | grep -oE "[-[:alnum:]]+$")" # matches a word at the end of LBUFFER
  local rh="$(echo $RBUFFER | grep -oE "^[-[:alnum:]]+")" # matches a word at the beginning of RBUFFER
  [ -z "$lh$rh" ] && local lh="$(echo $LBUFFER | grep -oE "[-[:alnum:]]+" | tail -1)"
  local target="$lh$rh"

  if [[ `type -w "$target"` == *": alias" ]]
  then
    unset 'functions[_expand-aliases]'
    functions[_expand-aliases]=$target
    (($+functions[_expand-aliases])) &&
      BUFFER="${LBUFFER/%$lh}${functions[_expand-aliases]#$'\t'}${RBUFFER/#$rh}" &&
      CURSOR=$#BUFFER
  else
    explain $(echo $target | cut -d' ' -f1) --pager='less -R'
  fi
}


# used for zle widgets
expand-alias () {
  local target="$(echo $LBUFFER | grep -oE "[-_[:alnum:]]+$")" # matches a word at the end of LBUFFER

  if [[ $EXPANSION_ON_SPACE == 'true' &&
        -z ${EXPANSION_FILTER[(re)$target]} &&
        `type -w "$target" 2>/dev/null` == *": alias"
     ]]
  then
    unset 'functions[_expand-aliases]'
    functions[_expand-aliases]=$target
    (($+functions[_expand-aliases])) &&
      BUFFER="${functions[_expand-aliases]#$'\t'}" &&
      CURSOR=$#BUFFER
  fi
  zle magic-space
}

zle -N expand-or-explain
bindkey '^E' expand-or-explain

zle -N expand-alias
# bindkey ' '    expand-alias
bindkey '^ '   magic-space          # control-space to bypass completion
bindkey -M isearch " "  magic-space # normal space during searches

zstyle ':completion:*' completer _expand_alias _complete _ignored
zstyle ':completion:*' regular true
