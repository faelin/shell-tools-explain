# shell-tools-explain

Quickly access the source for shell functions/aliases, or the man page for external programs.

## Usage

To enable automatic-expansion-on-space, set the following value anywhere in your shell configuration. When turned on, this feature will automatically expand any typed alias to its full command.

```bash
EXPANSION_ON_SPACE=true
```

To disable expand-on-space for specific commands, add them to the EXPANSION_FILTER list anywhere in your shell configuration:

```
EXPANSION_FILTER=()
```
