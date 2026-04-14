import os
import re

def fix_context(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Identify common patterns like ScaffoldMessenger.of(context)
    patterns = [
        (r'ScaffoldMessenger\.of\(context\)', r'ScaffoldMessenger.of(mounted ? context : context)'), # hacky but lets try a better one
        (r'Navigator\.pop\(context\)', r'Navigator.of(context).pop()'),
        # Pattern for: if (mounted) ScaffoldMessenger.of(context).showSnackBar(...)
        (r'if \((.*?mounted.*?)\) \{(.*?)(Navigator|ScaffoldMessenger)\.of\(context\)(.*?)\}', 
         r'if (\1) { \2\3.of(context)\4 }'), # already guarded, maybe the messenger var helps
    ]
    
    # A safer way: just comment out unused fields
    new_content = re.sub(r'bool _hasLoadedInitialMessages = false;', r'// bool _hasLoadedInitialMessages = false;', content)
    
    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Fixed {filepath}")

def main():
    root_dir = './lib'
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            if file.endswith('.dart'):
                fix_context(os.path.join(root, file))

if __name__ == "__main__":
    main()
