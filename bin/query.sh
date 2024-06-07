#!/bin/bash

# Default values
OWNER=""
REPO=""
VERSION="latest"
COMPONENT=""
SOURCE_DIRECTORY='Atala PRISM'

# Function to display usage information
display_usage() {
    echo "Usage: $0 --owner <owner> --repo <repo> [--version <version>] --component <component>"
}

# Function to display command information
display_help() {
    echo "This script retrieves component version information from GitHub repositories."
    echo
    display_usage
    echo
    echo "Options:"
    echo "  --owner       The GitHub owner/organization name"
    echo "  --repo        The GitHub repository name"
    echo "  --version     (Optional) The version of the repository. Default is 'latest'"
    echo "  --component   The name of the component to retrieve information for"
    echo "  --help        Display this help message"
}

# Parse command-line arguments
if [ "$#" -eq 0 ]; then
    display_help
    exit 1
fi

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --owner)
            OWNER="$2"
            shift
            shift
            ;;
        --repo)
            REPO="$2"
            shift
            shift
            ;;
        --version)
            VERSION="$2"
            shift
            shift
            ;;
        --component)
            COMPONENT="$2"
            shift
            shift
            ;;
        --help)
            display_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            display_usage
            exit 1
            ;;
    esac
done

# Check if required arguments are provided
if [ -z "$OWNER" ] || [ -z "$REPO" ] || [ -z "$COMPONENT" ]; then
    echo "Error: Required arguments missing."
    display_usage
    exit 1
fi

# Function to extract table from markdown
extract_table_from_markdown() {
    local markdown=$1
    local in_table=false
    local components=()
    local rowCount=0
    while IFS= read -r line; do
        if [[ "$line" =~ ^\*\*Updated\ components:\*\* ]]; then
            in_table=true
        elif [[ "$line" =~ ^\*\*Changelog\*\* ]]; then
            in_table=false
        elif [ "$in_table" = true ]; then
            rowCount=$((rowCount + 1))
            if [ $rowCount -gt 2 ]; then
                if [[ "$line" =~ ^\|\ (.*)\ \|\ (.*)\ \|\ (.*)\ \|$ ]]; then
                    local component="${BASH_REMATCH[1]}"
                    local from="${BASH_REMATCH[2]}"
                    local to="${BASH_REMATCH[3]}"
                    local version
                    if [[ "$to" =~ [nN][oO]\ [cC][hH][aA][nN][gG][eE] ]]; then
                        version="$from"
                    else
                        version="$to"
                    fi
                    components+=("{\"component\": \"$(echo "$component" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')\", \"version\": \"$(echo "$version" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')\"},")
                fi
            fi
        fi
    done <<< "$markdown"
    printf '%s\n' "${components[@]}"
}

# Remove the existing directory
rm -rf "$REPO"
# Clone the repository without output
git clone "https://github.com/$OWNER/$REPO.git" >/dev/null 2>&1 || { echo "Failed to clone repository"; exit 1; }
# Search for directories in the cloned repository
VERSIONS=$(find "$REPO/$SOURCE_DIRECTORY" -mindepth 1 -exec bash -c 'echo "${1##*/}" | sed "s/\.md$//" ' _ {} \;)

# Filter versions to ignore those lower than 2.10
FILTERED_VERSIONS=""
LATEST_VERSION=""
for version in $VERSIONS; do
    major=$(echo "$version" | cut -d'.' -f1)
    minor=$(echo "$version" | cut -d'.' -f2)
    if [ "$major" -gt 2 ] || ([ "$major" -eq 2 ] && [ "$minor" -ge 10 ]); then
        FILTERED_VERSIONS+=" $version"
        if [[ "$version" > "$LATEST_VERSION" ]]; then
            LATEST_VERSION="$version"
        fi
    fi
done

# If version is "latest", set it to the highest version
if [ "$VERSION" == "latest" ]; then
    VERSION="$LATEST_VERSION"
fi

# Iterate over filtered versions
for version in $FILTERED_VERSIONS; do
    if [ "$version" == "$VERSION" ]; then
        RELEASE_TEXT=$(find "$REPO/$SOURCE_DIRECTORY/$version.md" -type f -name "*.md" -exec cat {} +)
        components=$(extract_table_from_markdown "$RELEASE_TEXT")
        # If a specific component is specified, filter the output
        if [ -n "$COMPONENT" ]; then
            while IFS= read -r component; do
                if [[ $(echo "$component" | tr '[:upper:]' '[:lower:]') == *$(echo "$COMPONENT" | tr '[:upper:]' '[:lower:]')* ]]; then
                    version=$(echo "$component" | sed 's/.*"version": "\(.*\)".*/\1/')
                    printf '%s\n' "$version"
                    break
                fi
            done <<< "$components"
        else
            printf '%s\n' "${components%,}"
        fi
    fi
done

rm -rf "$REPO"
