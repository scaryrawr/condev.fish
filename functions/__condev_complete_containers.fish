function __condev_complete_containers
    # Cache completion data for 5 seconds to avoid repeated docker calls during rapid tab completions
    set -l cache_key __condev_completion_cache
    set -l cache_time_key __condev_completion_cache_time
    set -l cache_ttl 5
    
    set -l now (date +%s)
    if set -q $cache_time_key; and set -q $cache_key
        set -l age (math $now - $$cache_time_key)
        if test $age -lt $cache_ttl
            printf "%s\n" $$cache_key
            return
        end
    end
    
    # Fetch fresh data with single docker ps + batch inspect
    set -l containers (__condev_get_containers all)
    test (count $containers) -eq 0; and return
    
    # Batch inspect all containers in one docker call
    set -l all_info (docker inspect $containers --format '{{.Name}}	{{index .Config.Labels "vsch.local.repository"}}	{{index .Config.Labels "vsch.local.repository.folder"}}	{{index .Config.Labels "devcontainer.config_file"}}	{{.State.Status}}' 2>/dev/null)
    
    set -l results
    for line in $all_info
        set -l fields (string split \t "$line")
        set -l name (string replace -r '^/' '' "$fields[1]")
        set -l repo $fields[2]
        set -l folder $fields[3]
        set -l config_file $fields[4]
        set -l container_status $fields[5]
        
        # Extract repo name
        set -l repo_name ""
        if test -n "$repo"
            set repo_name (string replace -r '.*/(.+?)(.git)?$' '$1' "$repo")
        else if test -n "$folder"
            set repo_name $folder
        else if test -n "$config_file"
            set repo_name (string replace -r '^/workspaces/([^/]+)/.*' '$1' "$config_file")
        end
        
        # Format: repo (container) [status]
        set -l description
        if test -n "$repo_name"
            set description "$repo_name ($name) [$container_status]"
        else
            set description "($name) [$container_status]"
        end
        
        set -a results (printf "%s\t%s" "$name" "$description")
    end
    
    # Update cache
    set -g $cache_time_key $now
    set -g $cache_key $results
    
    printf "%s\n" $results
end
