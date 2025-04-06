#!/usr/bin/env python3

import json
import os

# Load the Swahili translations
with open('swahili_moderation_translations.json', 'r') as f:
    translations = json.load(f)

# Load the Moderation.xcstrings file
with open('Nos/Assets/Localization/Moderation.xcstrings', 'r') as f:
    xcstrings = json.load(f)

# Add Swahili translations to each string key
for key, translation in translations.items():
    # Check if the key exists in the xcstrings file
    if key in xcstrings["strings"]:
        # Add the Swahili translation
        xcstrings["strings"][key]["localizations"]["sw"] = {
            "stringUnit": {
                "state": "translated",
                "value": translation
            }
        }

# Save the updated Moderation.xcstrings file
with open('Nos/Assets/Localization/Moderation.xcstrings.bak', 'w') as f:
    json.dump(xcstrings, f, indent=2)

# If the backup is successful, replace the original file
os.rename('Nos/Assets/Localization/Moderation.xcstrings.bak', 'Nos/Assets/Localization/Moderation.xcstrings')

print("Successfully added Swahili translations to Moderation.xcstrings")