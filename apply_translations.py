#!/usr/bin/env python3
import json
import os
import sys
import shutil
import tempfile
import re

# Check if arguments are provided
if len(sys.argv) < 3:
    print("Usage: python apply_translations.py <language_code> <translations_file> [<target_xcstrings_file>]")
    print("Example: python apply_translations.py nl dutch_translations.txt")
    print("Example with target file: python apply_translations.py tr turkish_translations_reply.json Nos/Assets/Localization/Reply.xcstrings")
    sys.exit(1)

target_language = sys.argv[1]
translations_file = sys.argv[2]
xcstrings_file = '/Users/rabble/code/verse/nos/Nos/Assets/Localization/Localizable.xcstrings'  # Default

# Use custom xcstrings file if provided
if len(sys.argv) >= 4:
    xcstrings_file = sys.argv[3]
    if not xcstrings_file.startswith('/'):  # If not absolute path
        xcstrings_file = os.path.join('/Users/rabble/code/verse/nos', xcstrings_file)

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

# Validate language code
if target_language not in supported_languages:
    print(f"Error: Language '{target_language}' not supported. Supported languages are: {', '.join(supported_languages)}")
    sys.exit(1)

# Validate translations file exists
if not os.path.exists(translations_file):
    print(f"Error: Translations file '{translations_file}' does not exist.")
    sys.exit(1)

# Validate xcstrings file exists
if not os.path.exists(xcstrings_file):
    print(f"Error: xcstrings file not found at '{xcstrings_file}'")
    sys.exit(1)

# Create a backup of the original file
backup_file = f"{xcstrings_file}.{target_language}.bak"
try:
    shutil.copy2(xcstrings_file, backup_file)
    print(f"Created backup at {backup_file}")
except Exception as e:
    print(f"Warning: Could not create backup: {e}")

# Load the translations file with special handling for various formats
try:
    with open(translations_file, 'r', encoding='utf-8') as f:
        content = f.read()
        
        # Try different parsing approaches
        try:
            # First try as is - normal JSON
            translations = json.loads(content)
        except json.JSONDecodeError:
            # Remove trailing commas which are invalid in JSON
            content = re.sub(r',\s*}', '}', content)
            content = re.sub(r',\s*]', ']', content)
            
            try:
                # Try with fixed commas
                translations = json.loads(content)
            except json.JSONDecodeError:
                # Try adding surrounding braces if they're missing
                try:
                    if not content.strip().startswith('{'):
                        content = '{' + content
                    if not content.strip().endswith('}'):
                        content = content + '}'
                    translations = json.loads(content)
                except json.JSONDecodeError:
                    print(f"Error: The translations file '{translations_file}' is not valid JSON.")
                    print("Please check its format and make sure it follows JSON syntax.")
                    sys.exit(1)
except Exception as e:
    print(f"Error reading translations file: {e}")
    sys.exit(1)

# Load the xcstrings file
try:
    with open(xcstrings_file, 'r', encoding='utf-8') as f:
        xcstrings_data = json.load(f)
except Exception as e:
    print(f"Error reading xcstrings file: {e}")
    sys.exit(1)

# Apply the translations
added_count = 0
updated_count = 0
skipped_count = 0

for key, translation in translations.items():
    # Check if the key exists in the xcstrings file
    if key not in xcstrings_data["strings"]:
        print(f"Warning: Key '{key}' not found in the xcstrings file. Skipping.")
        skipped_count += 1
        continue
    
    # Get the string data
    string_data = xcstrings_data["strings"][key]
    
    # Initialize localizations if it doesn't exist
    if "localizations" not in string_data:
        string_data["localizations"] = {}
    
    # Check if the language already has a translation
    if target_language in string_data["localizations"]:
        # First check the structure
        if "stringUnit" in string_data["localizations"][target_language]:
            # Update the existing translation with the standard structure
            string_data["localizations"][target_language]["stringUnit"]["value"] = translation
            updated_count += 1
        else:
            # If structure is different, recreate it
            string_data["localizations"][target_language] = {
                "stringUnit": {
                    "state": "translated",
                    "value": translation
                }
            }
            updated_count += 1
    else:
        # Add a new translation
        string_data["localizations"][target_language] = {
            "stringUnit": {
                "state": "translated",
                "value": translation
            }
        }
        added_count += 1

# Write the updated file
try:
    with tempfile.NamedTemporaryFile('w', encoding='utf-8', delete=False) as temp:
        json.dump(xcstrings_data, temp, ensure_ascii=False, indent=2)
        temp_name = temp.name
    
    # Replace the original file with the updated one
    shutil.move(temp_name, xcstrings_file)
    print(f"Successfully updated the xcstrings file.")
except Exception as e:
    print(f"Error writing to xcstrings file: {e}")
    sys.exit(1)

# Print summary
print(f"\nTranslation Summary for {target_language}:")
print(f"  Added: {added_count}")
print(f"  Updated: {updated_count}")
print(f"  Skipped: {skipped_count}")
print(f"  Total processed: {added_count + updated_count + skipped_count}")
print(f"\nOriginal file backed up at {backup_file}")