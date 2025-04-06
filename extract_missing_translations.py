#!/usr/bin/env python3
import json
import sys
from collections import defaultdict

# Path to the Localizable.xcstrings file
file_path = '/Users/rabble/code/verse/nos/Nos/Assets/Localization/Localizable.xcstrings'

# Open and read the file
try:
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
except Exception as e:
    print(f"Error reading file: {e}")
    sys.exit(1)

# All supported languages
supported_languages = [
    "ar",     # Arabic
    "de",     # German
    "en",     # English (source)
    "es",     # Spanish
    "fa",     # Persian
    "fr",     # French
    "ja",     # Japanese
    "ko",     # Korean
    "nl",     # Dutch
    "pt-BR",  # Brazilian Portuguese
    "sv",     # Swedish
    "sw",     # Swahili
    "th",     # Thai
    "tr",     # Turkish
    "zh-Hans", # Simplified Chinese
    "zh-Hant"  # Traditional Chinese
]

# Check if language is provided as argument
if len(sys.argv) > 1:
    target_language = sys.argv[1]
    if target_language not in supported_languages:
        print(f"Error: Language '{target_language}' not supported. Supported languages are: {', '.join(supported_languages)}")
        sys.exit(1)
else:
    print(f"Please specify a target language code. Supported languages: {', '.join(supported_languages)}")
    print("Usage: python extract_missing_translations.py <language_code>")
    sys.exit(1)

# Statistics tracking
stats = {
    "total_strings": 0,
    "strings_with_translation": 0,
    "strings_missing_translation": 0
}

# Initialize the string collection
missing_strings = {}

# Function to safely get English text
def get_english_text(localization):
    # First try the expected structure
    if "stringUnit" in localization and "value" in localization["stringUnit"]:
        return localization["stringUnit"]["value"]
    # Alternative structure
    elif "value" in localization:
        return localization["value"]
    else:
        # Return a placeholder if we can't find the text
        return "[No English text found]"

# Find all English strings that are missing the target language translation
for key, value in data["strings"].items():
    stats["total_strings"] += 1
    
    # Skip if no localizations or no English translation
    if "localizations" not in value or "en" not in value["localizations"]:
        continue
    
    # Get the English text
    try:
        english_text = get_english_text(value["localizations"]["en"])
    except Exception as e:
        print(f"Warning: Could not extract English text for key '{key}': {e}")
        continue
    
    # Check if the target language translation exists
    if target_language in value["localizations"]:
        stats["strings_with_translation"] += 1
    else:
        # No translation exists, add to missing strings
        stats["strings_missing_translation"] += 1
        missing_strings[key] = english_text

# Print statistics
print(f"\nTranslation Statistics for {target_language}:")
print(f"  Total strings: {stats['total_strings']}")
print(f"  Strings with translation: {stats['strings_with_translation']}")
print(f"  Strings missing translation: {stats['strings_missing_translation']} ({(stats['strings_missing_translation']/stats['total_strings'])*100:.1f}%)")

# Create the output file
output_file = f"missing_{target_language}_translations.txt"
with open(output_file, 'w', encoding='utf-8') as f:
    f.write("{\n")
    for key, value in missing_strings.items():
        # Escape any double quotes
        value = value.replace('"', '\\"')
        f.write(f'  "{key}": "{value}",\n')
    f.write("}\n")

print(f"\nMissing strings written to {output_file}")
print(f"You can now translate the content of '{output_file}' and use apply_translations.py to add them to the app.")
print(f"Example: python apply_translations.py {target_language} {output_file}")