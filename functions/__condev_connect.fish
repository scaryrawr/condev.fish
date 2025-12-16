function __condev_connect
    set -l container $argv[1]
    
    # Single docker inspect call to get all needed metadata
    set -l inspect_data (docker inspect "$container" --format '{{index .Config.Labels "devcontainer.config_file"}}	{{.State.Status}}	{{index .Config.Labels "devcontainer.metadata"}}	{{.Config.User}}	{{index .Config.Labels "vsch.local.repository"}}	{{index .Config.Labels "vsch.local.repository.folder"}}' 2>/dev/null)
    or begin
        echo "Error: Container '$container' not found" >&2
        return 1
    end
    
    set -l fields (string split \t "$inspect_data")
    set -l config_file $fields[1]
    set -l container_status $fields[2]
    set -l metadata $fields[3]
    set -l config_user $fields[4]
    set -l repo_url $fields[5]
    set -l repo_folder $fields[6]
    
    # Verify this is a devcontainer
    if test -z "$config_file"
        echo "Error: '$container' is not a devcontainer" >&2
        return 1
    end
    
    if test "$container_status" != "running"
        echo "Container '$container' is not running (status: $container_status)" >&2
        read -l -P "Start the container? [y/N] " answer
        if test "$answer" = "y" -o "$answer" = "Y"
            echo "Starting container..." >&2
            docker start "$container" >/dev/null
            or begin
                echo "Failed to start container" >&2
                return 1
            end
        else
            return 1
        end
    end
    
    # Determine the user to connect as from cached metadata
    set -l remote_user (echo "$metadata" | grep -o '"remoteUser":"[^"]*"' | cut -d'"' -f4)
    
    # Fallback to container's configured user
    if test -z "$remote_user"
        set remote_user "$config_user"
    end
    
    # Last resort: try common devcontainer users, avoid root
    if test -z "$remote_user" -o "$remote_user" = "root" -o "$remote_user" = "0"
        # Try to find non-root user in the container
        set -l available_users (docker exec "$container" sh -c 'getent passwd | grep -E "/(vscode|node|codespace|devcontainer):" | cut -d: -f1' 2>/dev/null)
        if test -n "$available_users"
            set remote_user (echo "$available_users" | head -n1)
        else
            # Default to vscode as it's most common
            set remote_user "vscode"
        end
    end
    
    # Get workspace folder from config file
    set -l workspace (string replace -r '^(.*/workspaces/[^/]+).*' '$1' "$config_file")
    if test -z "$workspace"
        set workspace "/workspaces"
    end
    
    # Run postStartCommand if configured (from cached metadata)
    set -l post_start_cmd (echo "$metadata" | grep -o '"postStartCommand":"[^"]*"' | cut -d'"' -f4)
    if test -n "$post_start_cmd"
        echo "Running postStartCommand..." >&2
        docker exec -u "$remote_user" "$container" sh -c "$post_start_cmd" >/dev/null 2>&1
    end
    
    # Extract repo name from cached data
    set -l repo_name ""
    if test -n "$repo_url"
        set repo_name (string replace -r '.*/(.+?)(.git)?$' '$1' "$repo_url")
    else if test -n "$repo_folder"
        set repo_name "$repo_folder"
    else if test -n "$config_file"
        set repo_name (string replace -r '^/workspaces/([^/]+)/.*' '$1' "$config_file")
    end
    
    if test -n "$repo_name"
        echo "Connecting to devcontainer: $container ($repo_name) as user '$remote_user'" >&2
    else
        echo "Connecting to devcontainer: $container as user '$remote_user'" >&2
    end
    
    # Connect with interactive shell
    docker exec -it -u "$remote_user" -w "$workspace" "$container" /bin/sh -c '
        if command -v fish >/dev/null 2>&1; then
            exec fish
        elif command -v bash >/dev/null 2>&1; then
            exec bash
        elif command -v zsh >/dev/null 2>&1; then
            exec zsh
        else
            exec sh
        fi
    '
end
