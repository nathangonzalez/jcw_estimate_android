#!/usr/bin/env bash

# This script creates a directory and file structure from a tree representation.
# The first argument is the directory to create.
# It takes the tree structure from stdin.

if [ -z "$1" ]; then
  echo "Usage: $0 <root_directory>"
  exit 1
fi

# Create the base directory
mkdir -p "$1"
cd "$1"

# Read the tree structure from stdin
while IFS= read -r line; do
  # Remove leading whitespace to determine indentation level
  stripped_line=$(echo "$line" | sed 's/^[[:space:]]*//')
  indentation=$(echo "$line" | sed 's/\S.*//' | wc -c)

  # Determine if it's a directory or file
  if [[ "$stripped_line" == *'/'* ]]; then
    # It's a directory
    dir_name="${stripped_line%/}"
    mkdir -p "$dir_name"
  else
    # It's a file
    touch "$stripped_line"
  fi
done
