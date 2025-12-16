function __condev_select
    set -l show_all $argv[1]
    
    set -l containers (__condev_get_containers $show_all)
    
    if test -z "$containers"
        echo "No devcontainers found" >&2
        return 1
    end
    
    # Build selection list with rich information
    set -l choices
    for container in $containers
        set -l info (__condev_get_info "$container")
        set -l name $info[1]
        set -l repo_name $info[2]
        set -l container_status $info[4]
        
        if test -n "$repo_name"
            set -a choices "$name ($repo_name) [$container_status]"
        else
            set -a choices "$name [$container_status]"
        end
    end
    
    # Use fzf if available, otherwise simple select
    if command -q fzf
        set -l selected (printf "%s\n" $choices | fzf --height 40% --reverse --prompt "Select devcontainer: ")
        if test -n "$selected"
            # Extract container name from selection
            string replace -r '^([^ ]+).*' '$1' "$selected"
        end
    else
        echo "Select a devcontainer:" >&2
        for i in (seq (count $choices))
            echo "  $i) $choices[$i]" >&2
        end
        
        read -l -P "Enter number: " selection
        if test -n "$selection" -a "$selection" -ge 1 -a "$selection" -le (count $containers)
            echo $containers[$selection]
        end
    end
end
