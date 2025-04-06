#!/bin/bash

# Merge notification strings directly into Localizable.xcstrings file

# Change to the project directory
cd /Users/rabble/code/verse/nos

# Create the target directories
LOCALIZATIONS_DIR="Nos/Assets/Localization"
SOURCE_FILE="${LOCALIZATIONS_DIR}/strings-to-add.json"
DEST_FILE="${LOCALIZATIONS_DIR}/Localizable.xcstrings"

echo "=== Adding notification strings to ${DEST_FILE} ==="

# Check if files exist
if [ ! -f "$SOURCE_FILE" ]; then
    echo "Source file not found!"
    exit 1
fi

if [ ! -f "$DEST_FILE" ]; then
    echo "Destination file not found!"
    exit 1
fi

# Back up the original file
cp "$DEST_FILE" "${DEST_FILE}.bak"
echo "Created backup at ${DEST_FILE}.bak"

# Use a simpler approach for merging
# 1. Extract keys and values from the strings-to-add.json file
# 2. Add them directly to the Localizable.xcstrings file

# Use a totally manual approach with specific key insertions
echo "Writing new strings directly to Localizable.xcstrings"

# Create a one-liner script to do the work
cat > /tmp/add_strings.py << EOF
import json
with open("$SOURCE_FILE") as f1, open("$DEST_FILE") as f2:
    source = json.load(f1)
    dest = json.load(f2)
    for key, value in source.items():
        dest["strings"][key] = value
with open("$DEST_FILE", "w") as f:
    json.dump(dest, f, indent=2)
EOF

# Run the script
python3 /tmp/add_strings.py

if [ $? -eq 0 ]; then
    echo "Strings have been successfully merged into $DEST_FILE"
    echo "Remember to rebuild the project to apply changes"
else
    echo "Failed to merge strings - restoring backup"
    cp "${DEST_FILE}.bak" "$DEST_FILE"
    echo "Original file restored"
fi

# Clean up
rm /tmp/add_strings.py