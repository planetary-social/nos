#!/usr/bin/env python3

import json
import os

# Load the Swahili translations
with open('swahili_imagepicker_translations.json', 'r') as f:
    translations = json.load(f)

# Load the ImagePicker.xcstrings file
with open('Nos/Assets/Localization/ImagePicker.xcstrings', 'r') as f:
    xcstrings = json.load(f)

# Add Swahili translations to each string key
for key, translation in translations.items():
    # Skip 'camera' as we already added it manually
    if key == 'camera':
        continue
    
    # Check if the key exists in the xcstrings file
    if key in xcstrings["strings"]:
        # Add the Swahili translation
        xcstrings["strings"][key]["localizations"]["sw"] = {
            "stringUnit": {
                "state": "translated",
                "value": translation
            }
        }

# Save the updated ImagePicker.xcstrings file
with open('Nos/Assets/Localization/ImagePicker.xcstrings.bak', 'w') as f:
    json.dump(xcstrings, f, indent=2)

# If the backup is successful, replace the original file
os.rename('Nos/Assets/Localization/ImagePicker.xcstrings.bak', 'Nos/Assets/Localization/ImagePicker.xcstrings')

print("Successfully added Swahili translations to ImagePicker.xcstrings")