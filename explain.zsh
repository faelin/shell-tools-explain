#!/bin/sh

###
alias EXPLAINER="$((command -v bat &>/dev/null) && echo "bat -l'sh'" || echo "cat")"
###
export EXPANSION_ON_SPACE=false
export EXPANSION_FILTER=()
###
RED='\033[1;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color
###

select-from-list () {
  if (command -v fzf)
  then
    fzf --height 40% --reverse <<<$@
  else
    COLUMNS=1
    PS3="option: "
    select item
    do
      echo "$item"
      break;
    done
  fi
}

find-alias () {
  echo -n "searching..."

  source="$(${$(ps -cp "$$" -o command="")##-} -ixlc : 2>&1 | grep "alias '$1=.*'" | tail -1)"
  echo "\r$source"
  read file line <<< $(echo $source | sed -E "s/^\+(.*\/.*):([0-9]+)> alias '$1=.*'/\1 \2/")
  statement="$(cat $file | sed -n "${line}p")"
  
  echo -n "\r"
  echo "${PURPLE}$file\n${GREEN}$line${NC}:${RED}$statement${NC}"
}


## see what aliases and shortcuts mean
explain () {
  command=$@[-1]
  unset $@[-1]

  [[ ! $(command -v $command) ]] && echo "command not found: '$command'" && return 0

  if [[ $(type -a $command | wc -l) -gt 1 ]]
  then    
    target="$(IFS=$'\n'; select-from-list $(type -a "$command") )"
  else
    target="$(type -a "$command")"
  fi

  target="$(echo "$target" | sed -nE "s/^$command is( an?)? (.*)/\2/p")"

  case "$target" in
    alias\ *)
      # echo "alias!"
      find-alias $command
      ;;
    command\ *)
      # echo "command!"
      EXPLAINER $(command -v "$command") $@
      ;;
    function\ *)
      # echo "function!"
      type -f "$command" | EXPLAINER $@
      ;;
    hash\ *)
      echo "hash!"
      output=$(hash -m "$1")
      EXPLAINER ${output##*=} $@
      ;;
    shell\ builtin)
      # echo "builtin!"
      man $command
      ;;
    */*)
      # echo "path!"
      if [[ $(file "$target" | grep -v 'script' | grep -E 'binary|executable') ]]
      then
        man $command 2>/dev/null || $command --help
      else
        EXPLAINER $target
      fi
      ;;
    *)
      # echo "other!"
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
