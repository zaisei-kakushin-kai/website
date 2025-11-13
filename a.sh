#!/bin/bash

# Script to create a Git branch containing only the /site directory contents
# Usage: ./create_site_branch.sh [branch_name]

set -e  # Exit on error

# Configuration
BRANCH_NAME="static"
SITE_DIR="./site"
TEMP_DIR=$(mktemp -d)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Site Branch Creator ===${NC}"

# Check if /site directory exists
if [ ! -d "$SITE_DIR" ]; then
    echo -e "${RED}Error: $SITE_DIR directory does not exist${NC}"
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

# Check if branch already exists
if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
    echo -e "${YELLOW}Warning: Branch '$BRANCH_NAME' already exists${NC}"
    read -p "Do you want to delete and recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git branch -D "$BRANCH_NAME"
        echo -e "${GREEN}Deleted existing branch${NC}"
    else
        echo -e "${YELLOW}Aborted${NC}"
        exit 0
    fi
fi

echo -e "${GREEN}Step 1: Copying /site contents to temporary directory${NC}"
cp -r "$SITE_DIR"/* "$TEMP_DIR/" 2>/dev/null || {
    echo -e "${YELLOW}Warning: /site directory might be empty${NC}"
}

echo -e "${GREEN}Step 2: Creating orphan branch '$BRANCH_NAME'${NC}"
git checkout --orphan "$BRANCH_NAME"

echo -e "${GREEN}Step 3: Removing all files from staging${NC}"
git rm -rf . > /dev/null 2>&1 || true

echo -e "${GREEN}Step 4: Copying site contents to repository root${NC}"
cp -r "$TEMP_DIR"/* . 2>/dev/null || true
cp -r "$TEMP_DIR"/.[^.]* . 2>/dev/null || true  # Copy hidden files if any

echo -e "${GREEN}Step 5: Adding files to git${NC}"
git add .

echo -e "${GREEN}Step 6: Creating initial commit${NC}"
git commit -m "Initial commit: Contents from /site directory" || {
    echo -e "${RED}Error: Nothing to commit. /site directory might be empty${NC}"
    git checkout -
    git branch -D "$BRANCH_NAME" 2>/dev/null || true
    rm -rf "$TEMP_DIR"
    exit 1
}

echo -e "${GREEN}Step 7: Cleaning up temporary directory${NC}"
rm -rf "$TEMP_DIR"

echo -e "${GREEN}=== Success! ===${NC}"
echo -e "Branch '${GREEN}$BRANCH_NAME${NC}' has been created with contents from /site"
echo -e "You are now on the ${GREEN}$BRANCH_NAME${NC} branch"
echo ""
echo -e "To switch back to your previous branch, run:"
echo -e "  ${YELLOW}git checkout -${NC}"
echo ""
echo -e "To push this branch to remote, run:"
echo -e "  ${YELLOW}git push -u origin $BRANCH_NAME${NC}"