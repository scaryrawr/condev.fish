# condev - VS Code DevContainer Discovery Plugin for Fish Shell

A fish shell plugin for discovering and connecting to VS Code devcontainers running in Docker.

[![Fish Shell](https://img.shields.io/badge/fish-3.0+-blue.svg)](https://fishshell.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- 🔍 **Discover devcontainers** - Automatically finds all VS Code devcontainers
- 📊 **Rich information** - Shows repository name, container status, and last used time
- 🎯 **Interactive selection** - Uses fzf for easy container selection (optional)
- 🚀 **Quick connect** - Connect to any devcontainer with a single command
- ⚡ **Auto-start** - Offers to start stopped containers
- 👤 **Non-root user** - Automatically detects and uses the correct non-root user
- 🔄 **Lifecycle scripts** - Executes postStartCommand when configured
- 🐚 **Smart shell detection** - Automatically uses fish, bash, zsh, or sh

## Installation

### Using Fisher (Recommended)

Then install condev:

```bash
fisher install scaryrawr/condev
```

## Usage

### Interactive Selection

Simply run `condev` to interactively select and connect to a devcontainer:

```bash
condev
```

If you have `fzf` installed, you'll get a fuzzy-finder interface. Otherwise, a numbered menu will appear.

### List Devcontainers

List all running devcontainers:

```bash
condev --list
# or
condev -l
```

List all devcontainers (including stopped ones):

```bash
condev --list --all
# or
condev -la
```

Example output:

```
CONTAINER                 REPOSITORY           STATUS          LAST USED
──────────────────────────────────────────────────────────────────────────────────────────────────────────────────
determined_tharp          flare                running         running
sweet_cartwright          my-app               exited          2025-12-15 14:23:10
```

### Connect to Specific Container

Connect directly to a container by name:

```bash
condev my-container-name
```

### Get Help

```bash
condev --help
```

## How It Works

The plugin works by:

1. **Discovering devcontainers** - Queries Docker for containers with devcontainer labels
2. **Extracting metadata** - Reads labels like:
   - `devcontainer.config_file` - Location of devcontainer.json
   - `devcontainer.metadata` - Container metadata including remoteUser and lifecycle commands
   - `vsch.local.repository` - Original Git repository URL
   - `vsch.local.repository.folder` - Repository folder name
3. **User detection** - Automatically detects the correct non-root user to connect as:
   - First checks `remoteUser` from devcontainer metadata
   - Falls back to container's configured user
   - Searches for common devcontainer users (vscode, node, codespace)
   - Avoids connecting as root when possible
4. **Lifecycle scripts** - Runs `postStartCommand` if configured in devcontainer.json
5. **Connecting** - Uses `docker exec` to open an interactive shell inside the container
6. **Smart shell detection** - Automatically uses fish, bash, zsh, or sh

## Requirements

- Fish shell 3.0+
- Docker
- Optional: `fzf` for enhanced interactive selection

## Container Information

The plugin displays:

- **Container name** - Docker container name
- **Repository** - Git repository that was cloned (if available)
- **Status** - Current container status (running, exited, etc.)
- **Last used** - When the container was last active

## Advanced Usage

### Tab Completion

The plugin provides tab completion with rich information - press TAB to see containers with their repository and status:

```bash
condev <TAB>
# Shows:
# determined_tharp    flare (determined_tharp) [exited]
# sweet_cartwright    my-app (sweet_cartwright) [running]
# gifted_lalande      dotfiles (gifted_lalande) [exited]
```

The completion text is the container name, with the description showing the repository name, container name, and status.

### Auto-start Containers

If you select a stopped container, condev will offer to start it:

```bash
condev stopped-container
# Container 'stopped-container' is not running (status: exited)
# Start the container? [y/N] y
# Starting container...
# Connecting to devcontainer: stopped-container (my-repo)
```

### Working Directory

condev automatically changes to the workspace directory inside the container, typically `/workspaces/<repo-name>`.

### User Handling

condev connects as a non-root user by default:

1. Checks for `remoteUser` in devcontainer metadata
2. Falls back to the container's configured user
3. Searches for common devcontainer users (vscode, node, codespace, devcontainer)
4. Only uses root as a last resort

You'll see the user in the connection message:

```
Connecting to devcontainer: my-container (my-repo) as user 'vscode'
```

## Devcontainer CLI Integration

For more advanced devcontainer lifecycle management, consider using the official [devcontainer CLI](https://github.com/devcontainers/cli):

```bash
npm install -g @devcontainers/cli
```

The devcontainer CLI provides:

- Full lifecycle command support (postCreateCommand, postStartCommand, postAttachCommand)
- Feature installation and management
- Container rebuild and updates
- More robust metadata parsing

You can use both tools together:

- Use `devcontainer up` to create/start containers with full lifecycle support
- Use `condev` for quick discovery and connection to running containers

## Troubleshooting

### No containers found

Make sure you have VS Code devcontainers created. The plugin only detects containers with devcontainer labels.

### Permission denied

Ensure your user has permission to run Docker commands:

```bash
docker ps
```

If you get a permission error, you may need to add your user to the docker group or use sudo.

### Container won't start

Check Docker logs:

```bash
docker logs <container-name>
```

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - feel free to use and modify as needed.

## Acknowledgments

Built for use with VS Code's Remote - Containers extension and devcontainer CLI.
