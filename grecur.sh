#!/bin/bash

# Simple version using find to discover all git repos including nested submodules
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

# Find all .git directories (including nested ones) and process their parent directories
find "$TARGET_DIR" -name ".git" -type d | while read -r git_dir; do
    repo_dir=$(dirname "$git_dir")
    
    echo "========================================"
    echo "Processing git repository: $repo_dir"
    echo "========================================"
    
    (cd "$repo_dir" && \
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
done

echo "Done processing all git repositories and nested submodules!"