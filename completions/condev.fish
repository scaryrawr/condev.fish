complete -c condev -f
complete -c condev -s h -l help -d "Show help message"
complete -c condev -s l -l list -d "List all devcontainers"
complete -c condev -s a -l all -d "Include stopped containers"
complete -c condev -n "test (commandline -ct | string sub -l 1) != '-'" -a "(__condev_complete_containers)"
