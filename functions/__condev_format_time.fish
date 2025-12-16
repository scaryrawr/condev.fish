function __condev_format_time
    set -l timestamp $argv[1]
    
    # Use date command to parse and format (macOS compatible)
    if date -j -f "%Y-%m-%dT%H:%M:%S" (string sub -l 19 "$timestamp") "+%Y-%m-%d %H:%M:%S" 2>/dev/null
        return
    else
        # Fallback for Linux
        date -d "$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null
        or echo "$timestamp"
    end
end
