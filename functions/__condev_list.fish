function __condev_list
    set -l show_all $argv[1]
    
    set -l containers (__condev_get_containers $show_all)
    
    if test -z "$containers"
        echo "No devcontainers found" >&2
        return 1
    end
    
    # Header
    set_color --bold
    printf "%-25s %-20s %-15s %-50s\n" "CONTAINER" "REPOSITORY" "STATUS" "LAST USED"
    set_color normal
    printf "%s\n" (string repeat -n 110 "─")
    
    for container in $containers
        set -l info (__condev_get_info "$container")
        set -l name $info[1]
        set -l repo_name $info[2]
        set -l repo_url $info[3]
        set -l container_status $info[4]
        set -l finished $info[5]
        
        # Format last used time
        set -l last_used "-"
        if test "$container_status" = "running"
            set last_used "running"
            set_color green
        else if test -n "$finished" -a "$finished" != "0001-01-01T00:00:00Z"
            set last_used (__condev_format_time "$finished")
            set_color normal
        end
        
        printf "%-25s %-20s %-15s %-50s\n" \
            (string sub -l 25 "$name") \
            (string sub -l 20 "$repo_name") \
            (string sub -l 15 "$container_status") \
            (string sub -l 50 "$last_used")
        set_color normal
    end
end
