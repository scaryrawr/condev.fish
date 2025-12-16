# Copilot Instructions for condev.fish

## Overview
condev is a Fish shell plugin for discovering and connecting to VS Code devcontainers. It provides a CLI interface to list, select, and exec into devcontainers with intelligent user detection and lifecycle management.

## Architecture

### Function Organization
- **Main entry**: [functions/condev.fish](../functions/condev.fish) - Argument parsing and command routing
- **Private helpers**: `__condev_*` functions in [functions/](../functions/) - Follow fish shell convention of double underscore prefix for private functions
- **Completions**: [completions/condev.fish](../completions/condev.fish) - Tab completion definitions

### Core Component Responsibilities
- `__condev_get_containers`: Queries Docker for containers with `devcontainer.config_file` label
- `__condev_get_info`: Extracts metadata from Docker labels (`vsch.local.repository`, `vsch.local.repository.folder`, `devcontainer.metadata`)
- `__condev_connect`: Handles user detection, container startup, lifecycle scripts, and shell execution
- `__condev_select`: Interactive picker using fzf or numbered menu fallback

## Critical Patterns

### Docker Label Inspection
All container metadata comes from Docker labels set by VS Code:
```fish
docker inspect "$container" --format '{{index .Config.Labels "label.name"}}'
```
Key labels: `devcontainer.config_file`, `devcontainer.metadata` (JSON), `vsch.local.repository`, `vsch.local.repository.folder`

### User Detection Hierarchy
[functions/__condev_connect.fish](../functions/__condev_connect.fish#L21-L36) implements fallback chain:
1. Parse `remoteUser` from `devcontainer.metadata` JSON label
2. Fallback to container's `.Config.User`
3. Search for common users (vscode, node, codespace, devcontainer) via `getent passwd`
4. Last resort: default to `vscode` (never root)

### Shell Detection
Always use inline shell detection in `docker exec` to handle containers without specific shells:
```fish
docker exec -it "$container" /bin/sh -c 'if command -v fish >/dev/null; then exec fish; elif ...'
```

### Cross-Platform Compatibility
- Date parsing differs between macOS and Linux - see [functions/__condev_format_time.fish](../functions/__condev_format_time.fish#L4-L10)
- Use `date -j -f` for macOS, `date -d` for Linux with fallback
- Always check command availability with `command -q` or `command -v`

## Development Workflows

### Testing Changes
```fish
# Reload functions after edits
source functions/condev.fish

# Test with existing containers
condev -l
condev -la

# Test connection flow
condev container-name
```

### Debugging Docker Labels
```fish
# Inspect all labels on a devcontainer
docker inspect container-name --format '{{json .Config.Labels}}' | jq

# Check specific label
docker inspect container-name --format '{{index .Config.Labels "devcontainer.metadata"}}'
```

## Conventions

### Error Handling
- Write errors to `>&2` (stderr)
- Return non-zero exit codes on failure
- Provide actionable error messages with context

### Output Formatting
- Use `set_color` for status indicators (green for running)
- Truncate output with `string sub -l N` for consistent column widths
- Use UTF-8 box drawing characters (`─`) for visual separators

### String Manipulation
Prefer `string` builtin over external tools:
```fish
string replace -r '^(.*/workspaces/[^/]+).*' '$1' "$config_file"  # Extract workspace path
string sub -l 19 "$timestamp"  # Truncate timestamp
```

## Integration Points

### External Dependencies
- **Required**: Docker CLI - all functionality depends on `docker ps`, `docker inspect`, `docker exec`
- **Optional**: fzf - enhanced interactive selection; falls back to numbered menu
- **Runtime**: Uses container's available shells (fish > bash > zsh > sh)

### VS Code Devcontainer Labels
Plugin depends on VS Code Remote-Containers extension labels. When devcontainer configuration changes, labels are updated on container rebuild.

### Fisher Plugin Manager
Plugin follows Fisher conventions:
- Functions in `functions/` auto-loaded
- Completions in `completions/` auto-loaded
- No installation script needed

## Testing Considerations

Test with containers in different states:
- Running vs. stopped containers (`--all` flag behavior)
- Containers with/without repository metadata
- Different `remoteUser` configurations
- Containers with `postStartCommand` in devcontainer.json

When adding features:
- Ensure `__condev_complete_containers` returns updated info for tab completion
- Update help text in `__condev_help` and README.md
- Test both fzf and non-fzf code paths in `__condev_select`
