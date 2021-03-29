#!/bin/zsh

export EXPLAINER='cat'
(command -v bat &>/dev/null) && alias EXPLAINER="bat -l'sh'"


## see what aliases and shortcuts mean
function explain () {
  command=$@[-1]
  unset $@[-1]

  [[ ! $(command -v $command) ]] && echo "command not found: '$command'" && return 0

  if [[ $(type -a $command | wc -l) -gt 1 ]]
  then
    target=$(type -a $command | fzf --height 40% --reverse)
  else
    target=$(type -a "$command")
  fi

  target="$(echo "$target" | sed -nE "s/^$command is( an)? (.*)$/\2/p")"

  case "$target" in
    alias)
      EXPLAINER $(unalias "$command"; type "$command" | grep -o '/.*') $@
      ;;
    command)
      EXPLAINER $(command -v "$command") $@
      ;;
    function)
      type -f "$command" | EXPLAINER $@
      ;;
    hash)
      output=$(hash -m "$1")
      EXPLAINER ${output##*=} $@
      ;;
    */*)
      EXPLAINER $target
      ;;
    *)
      echo $target
      ;;
    esac
}


# zle 
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
zle -N expand-or-explain
bindkey '^E' expand-or-explain


typeset -ga EXPANSION_FILTER
export EXPANSION_FILTER
# export EXPANSION_ON_SPACE=true
expand-alias () {
  local target="$(echo $LBUFFER | grep -oE "[-[:alnum:]]+$")" # matches a word at the end of LBUFFER

  if [[ -n $EXPANSION_ON_SPACE &&
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
zle -N expand-alias
bindkey ' '    expand-alias
bindkey '^ '   magic-space          # control-space to bypass completion
bindkey -M isearch " "  magic-space # normal space during searches

zstyle ':completion:*' completer _expand_alias _complete _ignored
zstyle ':completion:*' regular true
