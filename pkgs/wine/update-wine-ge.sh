#!/usr/bin/env -S nix shell nixpkgs#npins -c bash

# Repository information
# This script interacts with the GitHub API to fetch branch information from a specified repository.
# The repository owner and name are hardcoded for clarity and ease of use.
REPO_OWNER="GloriousEggroll"
REPO_NAME="proton-wine"

# Get branch names
# This command fetches the list of branches from the GitHub repository using the GitHub API.
# The `curl` command retrieves the JSON response, and `grep` extracts the branch names.
branches=$(curl -s "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/branches?per_page=10000" | grep -oP '(?<="name": ")[^"]+')

# Initialize variables
# These variables are used to track the latest version found among the branches.
latest_major=0
latest_minor=0

# Find the latest version
# This loop iterates over each branch name, extracts the major and minor version numbers,
# and updates the `latest_major`, `latest_minor`, and `latest_branch` variables if a newer version is found.
for branch in $branches; do
  if [[ $branch =~ ^Proton([0-9]+)-([0-9]+)$ ]]; then
    major=${BASH_REMATCH[1]}
    minor=${BASH_REMATCH[2]}
    if (( major > latest_major )) || (( major == latest_major && minor > latest_minor )); then
      latest_major=$major
      latest_minor=$minor
      latest_branch=$branch
    fi
  fi
done

# Add the latest branch to npins
# This command adds the latest branch found to the `npins` tool, which is used for managing pinned dependencies.
npins add github -b "$latest_branch" "$REPO_OWNER" "$REPO_NAME"
