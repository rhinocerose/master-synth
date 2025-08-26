#!/bin/bash

# Script to process ALL git repos including deeply nested submodules
# and then update the parent repos with submodule references
# Usage: ./grecur.sh <directory>

set -e  # Exit on any error

if [ $# -lt 1 ]; then
    echo "Usage: $0 <directory>"
    echo "Example: $0 ~/projects"
    exit 1
fi

TARGET_DIR=$(realpath "$1")

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' does not exist"
    exit 1
fi

# Array to track which repos have submodules that were processed
declare -A processed_repos

# Function to process a single git repository
process_git_repo() {
    local repo_dir="$1"
    local is_submodule="$2"
    
    echo "========================================"
    echo "Processing: $repo_dir"
    echo "========================================"
    
    # Try main branch first, then master, then stay on current
    (cd "$repo_dir" && \
     echo "1. Checking out main branch..." && \
     git checkout main 2>/dev/null || git checkout master 2>/dev/null || echo "Staying on current branch" && \
     echo "2. Pulling latest changes..." && \
     git pull && \
     echo "3. Adding all changes..." && \
     git add . && \
     echo "4. Committing changes..." && \
     git commit -m "Updating" || echo "No changes to commit" && \
     echo "5. Pushing to origin..." && \
     git push origin)
    
    echo ""
    
    # If this repo has submodules, remember it for later processing
    if [ -f "$repo_dir/.gitmodules" ]; then
        processed_repos["$repo_dir"]=1
    fi
}

# Function to update parent repos with submodule references
update_parent_repos() {
    echo "========================================"
    echo "Updating parent repositories with submodule references"
    echo "========================================"
    
    for repo_dir in "${!processed_repos[@]}"; do
        if [ -d "$repo_dir/.git" ]; then
            echo "Updating parent repo: $repo_dir"
            
            # Update submodule references in the parent repo
            (cd "$repo_dir" && \
             echo "1. Adding submodule changes..." && \
             git add . && \
             echo "2. Committing submodule updates..." && \
             git commit -m "Update submodules" || echo "No submodule changes to commit" && \
             echo "3. Pushing submodule updates..." && \
             git push origin)
            
            echo ""
        fi
    done
}

# Find ALL .git directories recursively (including deeply nested ones)
echo "Searching for all git repositories in: $TARGET_DIR"
find "$TARGET_DIR" -name ".git" -type d | while read -r git_dir; do
    repo_dir=$(dirname "$git_dir")
    # Check if this is a submodule (has a .git file instead of .git directory)
    if [ -f "$repo_dir/.git" ]; then
        process_git_repo "$repo_dir" "submodule"
    else
        process_git_repo "$repo_dir" "main"
    fi
done

# Now update all parent repos that have submodules
update_parent_repos

echo "Done processing ALL git repositories and updating parent repos!"