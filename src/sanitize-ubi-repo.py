import re
import argparse

# Function to process the INI file manually (handling duplicates, adding suffixes, and ensuring only one blank line between sections)
def process_ini_file(input_file):
    print(f"Processing file: {input_file}")

    # Read the input file
    with open(input_file, 'r') as file:
        content = file.read()
    print(f"File content loaded successfully, length: {len(content)} characters.")

    # Split the content into sections based on section headers
    sections = re.split(r'(\[.*?\])', content)
    print(f"Content split into {len(sections)//2} sections.")

    # Track sections we've seen
    seen_sections = set()

    # Temporary list to hold the cleaned content
    cleaned_content = []

    # Iterate over the sections and process them
    for i in range(1, len(sections), 2):  # Sections are at odd indices
        section_header = sections[i].strip()
        section_name = section_header[1:-1]  # Remove the '[' and ']'
        
        print()
        print(f"Processing section: {section_name}")

        # Add '-rpms' suffix if not already there
        if not section_name.endswith('-rpms'):
            print(f"Suffix '-rpms' added to section: {section_name}")
            section_name = f"{section_name}-rpms"
        else:
            print(f"Section '{section_name}' already has the '-rpms' suffix.")

        # If we've already seen this section, skip it
        if section_name in seen_sections:
            print(f"Duplicate section '{section_name}' found. Skipping...")
            continue

        # Add section header to cleaned content
        cleaned_content.append(f"[{section_name}]")
        print(f"Section header '[{section_name}]' added to cleaned content.")

        # Add the section content (keys/values) to cleaned content
        cleaned_content.append(sections[i + 1])
        print(f"Section content added for '[{section_name}]'.")

        # Mark the section as seen
        seen_sections.add(section_name)
        print(f"Section '{section_name}' marked as processed.")

    # Write the cleaned content back to the file
    with open(input_file, 'w') as file:
        file.write(''.join(cleaned_content))
    print("\nFile processing complete!")

# Command-line argument parsing
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Sanitize ubi.repo file.")
    parser.add_argument('input_file', type=str, help="Path to the ubi.repo file.")
    args = parser.parse_args()

    # Process the file
    process_ini_file(args.input_file)
