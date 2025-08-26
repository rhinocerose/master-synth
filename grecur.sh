#!/bin/bash

# Script to execute git workflow on all repos and submodules with error handling
# Usage: ./grecur.sh <directory>

set -e  # Exit on any error

if [ $# -lt 1 ]; then
    echo "Usage: $0 <directory>"
    echo "Example: $0 ~/projects"
    exit 1
fi

TARGET_DIR="$1"

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' does not exist"
    exit 1
fi

# Function to process a directory
process_repo() {
    local dir="$1"
    
    # Check if this is a git repository
    if [ -d "$dir/.git" ]; then
        echo "========================================"
        echo "Processing git repository: $dir"
        echo "========================================"
        
        # Execute the git workflow with error handling
        (cd "$dir" && \
         echo "Checking out main branch..." && \
         git checkout main && \
         echo "Pulling latest changes..." && \
         git pull && \
         echo "Adding all changes..." && \
         git add . && \
         echo "Committing changes..." && \
         git commit -m "Updating" || echo "No changes to commit or commit failed" && \
         echo "Pushing to origin..." && \
         git push origin)
        
        echo ""
        
        # Check for submodules
        if [ -f "$dir/.gitmodules" ]; then
            echo "Found submodules in $dir"
            
            # Get submodule paths from .gitmodules file
            local submodule_paths=$(grep -E "^\s*path\s*=" "$dir/.gitmodules" | sed 's/^.*= //' | tr -d ' ')
            
            for submodule_path in $submodule_paths; do
                local full_submodule_path="$dir/$submodule_path"
                if [ -d "$full_submodule_path" ]; then
                    process_repo "$full_submodule_path"
                fi
            done
        fi
    fi
}

# Start processing from the target directory
process_repo "$TARGET_DIR"

echo "Done processing all git repositories and submodules!"