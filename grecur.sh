#!/bin/bash
set -e
if [ $# -lt 1 ]; then
    echo "Usage: $0 <directory> <command> [command_args...]"
    exit 1
fi

TARGET_DIR="$1"
#COMMAND="${@:2}"

process_repo() {
    local dir="$1"
    
    if [ -d "$dir/.git" ]; then
        echo "=== Processing: $dir ==="
        (cd "$dir" && git checkout main && git pull && git add . && git commit -m "Updating" && git push origin )
        echo ""
        
        # Process submodules if they exist
        if [ -f "$dir/.gitmodules" ]; then
            # Get submodule paths using git config
            git -C "$dir" config --file .gitmodules --get-regexp path | awk '{print $2}' | while read -r submodule_path; do
                local full_path="$dir/$submodule_path"
                if [ -d "$full_path" ]; then
                    process_repo "$full_path"
                fi
            done
        fi
    fi
}

# Start processing from the target directory
process_repo "$TARGET_DIR"