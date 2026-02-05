#!/bin/bash

# Documentation Validation Script for hassio-addons
# This script helps validate that documentation is properly updated

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔍 Validating documentation for hassio-addons monorepo..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project directories
PROJECTS=("sambanas" "sambanas2" "plex" "RPiMySensor" "addon-plex")

# Function to check if a project has changes
has_changes() {
    local project=$1
    git diff --name-only HEAD~1..HEAD | grep -q "^$project/" 2>/dev/null
}

# Function to check if documentation was updated
has_doc_changes() {
    local project=$1
    git diff --name-only HEAD~1..HEAD | grep -q "^$project/.*\.md$" 2>/dev/null
}

# Function to validate project documentation structure
validate_project_docs() {
    local project=$1
    local errors=0
    
    echo -e "${BLUE}Validating $project documentation...${NC}"
    
    # Check README.md exists
    if [ ! -f "$project/README.md" ]; then
        echo -e "${RED}❌ Missing README.md in $project${NC}"
        ((errors++))
    else
        echo -e "${GREEN}✅ README.md exists${NC}"
        
        # Check for main title
        if ! grep -q "^# " "$project/README.md"; then
            echo -e "${RED}❌ README.md missing main title (# heading)${NC}"
            ((errors++))
        fi
        
        # Special check for sambanas maintenance mode
        if [ "$project" = "sambanas" ]; then
            if ! grep -q -i "maintenance mode" "$project/README.md"; then
                echo -e "${RED}❌ sambanas README.md missing maintenance mode notice${NC}"
                ((errors++))
            else
                echo -e "${GREEN}✅ Maintenance mode notice found${NC}"
            fi
        fi
    fi
    
    # Check DOCS.md if it exists
    if [ -f "$project/DOCS.md" ]; then
        echo -e "${GREEN}✅ DOCS.md exists${NC}"
    fi
    
    # Check CHANGELOG.md if it exists
    if [ -f "$project/CHANGELOG.md" ]; then
        echo -e "${GREEN}✅ CHANGELOG.md exists${NC}"
    fi
    
    return $errors
}

# Function to check for cross-project references
check_cross_references() {
    local project=$1
    local errors=0
    
    echo -e "${BLUE}Checking for cross-project references in $project...${NC}"
    
    for md_file in "$project"/*.md; do
        if [ -f "$md_file" ]; then
            for other_project in "${PROJECTS[@]}"; do
                if [ "$project" != "$other_project" ]; then
                    # Allow sambanas to reference sambanas2 for migration
                    if [ "$project" = "sambanas" ] && [ "$other_project" = "sambanas2" ]; then
                        continue
                    fi
                    
                    if grep -q "\b$other_project\b" "$md_file"; then
                        echo -e "${RED}❌ Cross-project reference found in $md_file referencing $other_project${NC}"
                        ((errors++))
                    fi
                fi
            done
        fi
    done
    
    if [ $errors -eq 0 ]; then
        echo -e "${GREEN}✅ No inappropriate cross-project references found${NC}"
    fi
    
    return $errors
}

# Main validation logic
main() {
    local total_errors=0
    local projects_with_changes=()
    
    echo "Checking for recent changes..."
    
    # Find projects with changes
    for project in "${PROJECTS[@]}"; do
        if [ -d "$project" ]; then
            if has_changes "$project"; then
                projects_with_changes+=("$project")
                echo -e "${YELLOW}📝 Changes detected in $project${NC}"
                
                if ! has_doc_changes "$project"; then
                    echo -e "${RED}❌ No documentation updates found for $project${NC}"
                    echo -e "${YELLOW}💡 Consider updating:${NC}"
                    echo -e "   - $project/README.md"
                    echo -e "   - $project/DOCS.md"
                    echo -e "   - $project/CHANGELOG.md"
                    ((total_errors++))
                else
                    echo -e "${GREEN}✅ Documentation updated for $project${NC}"
                fi
            fi
        fi
    done
    
    if [ ${#projects_with_changes[@]} -eq 0 ]; then
        echo -e "${GREEN}✅ No recent changes detected in project directories${NC}"
    fi
    
    echo ""
    echo "Validating all project documentation structure..."
    
    # Validate all projects
    for project in "${PROJECTS[@]}"; do
        if [ -d "$project" ]; then
            validate_project_docs "$project"
            if [ $? -ne 0 ]; then
                ((total_errors++))
            fi
            
            check_cross_references "$project"
            if [ $? -ne 0 ]; then
                ((total_errors++))
            fi
            
            echo ""
        fi
    done
    
    # Summary
    echo "================================================"
    if [ $total_errors -eq 0 ]; then
        echo -e "${GREEN}🎉 All documentation validation checks passed!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Documentation validation failed with $total_errors error(s)${NC}"
        echo ""
        echo -e "${BLUE}📋 Documentation Guidelines:${NC}"
        echo "1. Update README.md for feature/installation changes"
        echo "2. Update DOCS.md for configuration changes"
        echo "3. Update CHANGELOG.md with your changes"
        echo "4. Keep each project's documentation self-contained"
        echo "5. See .copilot-instructions.md for detailed guidelines"
        exit 1
    fi
}

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ Not in a git repository${NC}"
    exit 1
fi

# Run main function
main "$@"
