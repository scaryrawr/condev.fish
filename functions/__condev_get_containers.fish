function __condev_get_containers
    set -l show_all $argv[1]
    
    set -l filter_args --filter "label=devcontainer.config_file"
    if not test "$show_all" = "all"
        set -a filter_args --filter "status=running"
    end

    # Single docker call with label filter - no need to inspect each container
    docker ps -a $filter_args --format "{{.Names}}" 2>/dev/null
end
