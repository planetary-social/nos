#!/bin/bash

# Merge the contents of the strings-to-add.json file into the main Localizable.xcstrings file
# This is a temporary solution until we get proper xcstrings integration

# Path to the source JSON file
SOURCE_FILE="/Users/rabble/code/verse/nos/Nos/Assets/Localization/strings-to-add.json"

# Path to the destination xcstrings file
DEST_FILE="/Users/rabble/code/verse/nos/Nos/Assets/Localization/Localizable.xcstrings"

# Check if source file exists
if [ ! -f "$SOURCE_FILE" ]; then
    echo "Source file not found!"
    exit 1
fi

# Check if destination file exists
if [ ! -f "$DEST_FILE" ]; then
    echo "Destination file not found!"
    exit 1
fi

# Create a temp file for the merged content
TEMP_FILE=$(mktemp)

# Read the source JSON
SOURCE_CONTENT=$(cat "$SOURCE_FILE")

# Extract the strings section (everything between the first { and the last })
SOURCE_STRINGS=$(echo "$SOURCE_CONTENT" | sed -e 's/^{//' -e 's/}$//' -e 's/,$//')

# Create a simpler approach using Python to merge the JSON files
python3 -c "
import json
import sys

# Read the source strings
with open('$SOURCE_FILE', 'r') as f:
    source = json.load(f)

# Read the destination file
with open('$DEST_FILE', 'r') as f:
    dest = json.load(f)

# Merge the strings
for key, value in source.items():
    dest['strings'][key] = value

# Write back to a temp file
with open('$TEMP_FILE', 'w') as f:
    json.dump(dest, f, indent=2)
"

# Check if the Python command succeeded
if [ $? -ne 0 ]; then
    echo "Error merging JSON files using Python!"
    exit 1
fi

# Back up the original file
cp "$DEST_FILE" "${DEST_FILE}.bak"

# Copy the temp file to the destination
cp "$TEMP_FILE" "$DEST_FILE"

# Clean up
rm "$TEMP_FILE"

echo "Strings have been merged into $DEST_FILE"
echo "A backup of the original file was created at ${DEST_FILE}.bak"

# Remind to rebuild the project
echo "Remember to rebuild the project to apply changes"