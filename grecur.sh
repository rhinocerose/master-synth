#!/bin/bash

# Most reliable version - uses find to get EVERY git repo at any depth
# Usage: ./grecur.sh <directory>

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

TARGET_DIR=$(realpath "$1")

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' does not exist"
    exit 1
fi

# Process a single repository
process_repo() {
    local repo_dir="$1"
    
    echo "========================================"
    echo "Processing: $repo_dir"
    echo "========================================"
    
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
}

# Main execution
echo "Searching for ALL git repositories in: $TARGET_DIR"

# Use find with -print0 to handle spaces in paths
while IFS= read -r -d '' git_dir; do
    repo_dir=$(dirname "$git_dir")
    process_repo "$repo_dir"
done < <(find "$TARGET_DIR" -name ".git" -type d -print0)

echo "========================================"
echo "ALL git repositories processed successfully!"
echo "========================================"