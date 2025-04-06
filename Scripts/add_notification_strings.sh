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

# Manual approach - directly add the strings
STRINGS_TO_ADD=$(cat "$SOURCE_FILE")
TEMP_FILE=$(mktemp)

# Back up the original file
cp "$DEST_FILE" "${DEST_FILE}.bak"

# Simple text-based approach
# Extract the strings to add (remove the outer braces)
CONTENT_TO_ADD=$(cat "$SOURCE_FILE" | sed '1s/^{//' | sed '$s/}$//')

# Find the position to add the new strings (after "strings" : {)
# and add them there
awk '
BEGIN { found = 0; }
/"strings" : {/ { 
    print $0;
    print "    " substr("'"$CONTENT_TO_ADD"'", 1);
    found = 1;
    next;
}
{ print $0; }
' "${DEST_FILE}.bak" > "$TEMP_FILE"

# Check if awk found the insertion point
if grep -q "$CONTENT_TO_ADD" "$TEMP_FILE"; then
    # Copy the temp file to the destination
    cp "$TEMP_FILE" "$DEST_FILE"
    echo "Strings have been merged into $DEST_FILE"
    echo "A backup of the original file was created at ${DEST_FILE}.bak"
else
    echo "Failed to insert strings into the file. Check the format of Localizable.xcstrings."
    # Don't overwrite the original
    rm "${DEST_FILE}.bak"
    exit 1
fi

# Clean up
rm "$TEMP_FILE"

# Remind to rebuild the project
echo "Remember to rebuild the project to apply changes"