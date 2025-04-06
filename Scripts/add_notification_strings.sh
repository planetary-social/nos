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

# Read the source JSON into a variable
SOURCE_CONTENT=$(cat "$SOURCE_FILE")

# Extract the strings from the source JSON
SOURCE_STRINGS=$(echo "$SOURCE_CONTENT" | sed -e 's/^{//' -e 's/}$//' -e 's/,$//')

# Read the destination xcstrings file
DEST_CONTENT=$(cat "$DEST_FILE")

# Find the position after the first "strings" : { in the destination file
# and add the source strings there
MERGED_CONTENT=$(echo "$DEST_CONTENT" | sed -e 's/"strings" : {/"strings" : {\
'"$SOURCE_STRINGS"',/')

# Write the merged content to the temp file
echo "$MERGED_CONTENT" > "$TEMP_FILE"

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