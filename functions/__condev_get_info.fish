function __condev_get_info
    set -l container $argv[1]
    
    # Single docker inspect call with all fields in one Go template
    set -l info (docker inspect "$container" --format '{{index .Config.Labels "vsch.local.repository"}}	{{index .Config.Labels "vsch.local.repository.folder"}}	{{index .Config.Labels "devcontainer.config_file"}}	{{.State.Status}}	{{.State.FinishedAt}}' 2>/dev/null)
    or return 1
    
    set -l fields (string split \t "$info")
    set -l repo $fields[1]
    set -l folder $fields[2]
    set -l config_file $fields[3]
    set -l container_status $fields[4]
    set -l finished $fields[5]
    
    # Extract repo name from URL if available
    set -l repo_name ""
    if test -n "$repo"
        set repo_name (string replace -r '.*/(.+?)(.git)?$' '$1' "$repo")
    else if test -n "$folder"
        set repo_name $folder
    else if test -n "$config_file"
        set repo_name (string replace -r '^/workspaces/([^/]+)/.*' '$1' "$config_file")
    end
    
    echo "$container"
    echo "$repo_name"
    echo "$repo"
    echo "$container_status"
    echo "$finished"
end
