function condev --description "Discover and connect to VS Code devcontainers"
    set -l options (fish_opt --short h --long help)
    set -a options (fish_opt --short l --long list)
    set -a options (fish_opt --short a --long all)
    argparse $options -- $argv
    or return 1

    if set -q _flag_help
        __condev_help
        return 0
    end

    if set -q _flag_list
        if set -q _flag_all
            __condev_list all
        else
            __condev_list
        end
        return 0
    end

    # If no arguments, list containers and let user select
    if test (count $argv) -eq 0
        if set -q _flag_all
            set -l selected (__condev_select all)
        else
            set -l selected (__condev_select)
        end
        if test -z "$selected"
            echo "No container selected" >&2
            return 1
        end
        set argv $selected
    end

    # Connect to the specified container
    __condev_connect $argv[1]
end
