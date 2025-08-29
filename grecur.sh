#!/bin/bash

# Use git submodule status to detect and skip unpopulated submodules
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

# Function to process a repository
process_repo() {
    local repo_dir="$1"
    
    echo "========================================"
    echo "Processing: $repo_dir"
    echo "========================================"
    
    # Execute checkout and pull
    (cd "$repo_dir" && \
     echo "1. Checking out main branch..." && \
     git checkout main 2>/dev/null || git checkout master 2>/dev/null || echo "Staying on current branch" && \
     echo "2. Pulling latest changes..." && \
     git pull && \
     echo "3. Adding all changes..." && \
     git add .)
    
    # Check if there are staged changes to commit
    if (cd "$repo_dir" && git diff --cached --quiet); then
        echo "4. No changes to commit"
    else
        echo "4. Committing changes..."
        (cd "$repo_dir" && \
         git commit -m "Updating" && \
         echo "5. Pushing to origin..." && \
         git push origin)
    fi
    
    echo ""
}

# Function to recursively process submodules using git submodule status
process_submodules() {
    local parent_dir="$1"
    
    if [ ! -f "$parent_dir/.gitmodules" ]; then
        return
    fi
    
    echo "Checking for submodules in: $parent_dir"
    
    # Use git submodule status to get populated submodules
    (cd "$parent_dir" && git submodule status --recursive) | while read -r status_line; do
        # Extract submodule path (second field)
        submodule_path=$(echo "$status_line" | awk '{print $2}')
        
        if [ -n "$submodule_path" ] && [ "$submodule_path" != "." ]; then
            full_path="$parent_dir/$submodule_path"
            
            # If the line starts with '-' it's unpopulated, skip it
            if echo "$status_line" | grep -q "^-"; then
                echo "Skipping unpopulated submodule: $submodule_path"
            else
                echo "Processing populated submodule: $submodule_path"
                process_repo "$full_path"
                
                # Recursively process submodules of this submodule
                process_submodules "$full_path"
            fi
        fi
    done
}

# Main execution
echo "Processing main repository..."
process_repo "$TARGET_DIR"

# Process all populated submodules recursively
process_submodules "$TARGET_DIR"

echo "========================================"
echo "All populated repositories processed!"
echo "========================================"