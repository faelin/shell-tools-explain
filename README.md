# shell-tools-explain

Quickly access the source for shell functions/aliases, or the man page for external programs.

## Usage

To enable automatic-expansion-on-space, set the following value anywhere in your shell configuration. When turned on, this feature will automatically expand any typed alias to its full command.

```bash
EXPANSION_ON_SPACE=true
```


```
alias READ=''
```

```
EXPANSION_FILTER=()
```



```
zle -N expand-or-explain
bindkey '^E' expand-or-explain

zle -N expand-alias
bindkey ' '    expand-alias
bindkey '^ '   magic-space          # control-space to bypass completion
bindkey -M isearch " "  magic-space # normal space during searches

zstyle ':completion:*' completer _expand_alias _complete _ignored
zstyle ':completion:*' regular true
```
