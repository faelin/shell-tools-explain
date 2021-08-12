#!/bin/bash

###
# shellcheck disable=SC2139
alias READER="$(  (command -v bat &>/dev/null) && echo "bat -l'sh'" || echo "cat"  )"
###
export EXPANSION_ON_SPACE=false
export EXPANSION_FILTER=()
typeset -ga EXPANSION_FILTER
##
RED='\033[1;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color
###


select-from-list () {
  # local IFS=$'\n'
  list=()
  if [ "$#" -gt 0 ]; then
    for line in "$@";
    do
      list+=("$line");
    done
  else
    # while read -r line ; do
    #   list+=("$line")
    # done
  fi

  # if (command -v fzf >/dev/null 2>&1)
  # then
  #     printf '%s\n' "${list[@]}" | fzf --height 40% --reverse
  # else
    length=0
    for x in ${list[@]}
    do
       if [ ${#x} -gt $length ]
       then
          length=${#x}
       fi
    done
    
    local COLUMNS=$length
    local PS3="option: "
    select item in ${list[@]}
    do
      echo "$item"
      return;
    done
  # fi
}

find-alias () {
  echo -n "searching..."

  source="$(${$(ps -cp "$$" -o command="")##-} -ixlc : 2>&1 | grep "alias '$1=.*'" | tail -1)"
  read file line <<< $(echo $source | sed -E "s/^\+(.*\/.*):([0-9]+)> alias '$1=.*'/\1 \2/")
  statement="$(cat $file | sed -n "${line}p")"
  
  echo -n "\r"
  echo "${PURPLE}$file\n${GREEN}$line${NC}:${RED}$statement${NC}"
}

explain () {
  args=($@)
  command=${args[-1]}
  unset $args[-1]

  [[ ! $(command -v $command) ]] && echo "command not found: '$command'" && return 0

  if [[ $(type -a $command | wc -l) -gt 1 ]]
  then    
    # zsh variant:  target="$( IFS=$'\n'; select-from-list $(type -a "$command") )"
    # bash variant:  target="$( IFS=$'\n' select-from-list $(type -a "$command") )"
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
      READER $(command -v "$command") $args
      ;;
    function\ *)
      # echo "function!"
      type -f "$command" | READER $args
      ;;
    hash\ *)
      echo "hash!"
      output=$(hash -m "$1")
      READER ${output##*=} $args
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
        READER $target
      fi
      ;;
    *)
      # echo "other!"
      echo $target
      ;;
    esac
}


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
