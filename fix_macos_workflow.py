import re

file_path = "/home/abubakar/kflkiosk/.github/workflows/auto-build-installers.yml"
with open(file_path, "r") as f:
    content = f.read()

macos_build_pattern = r'          flutter build macos --release -t \$ENTRY_FILE\n'
macos_build_replacement = r'          flutter build macos --release -t $ENTRY_FILE --export-options-plist=macos/export_options/${{ matrix.flavor }}.plist\n'

content = re.sub(macos_build_pattern, macos_build_replacement, content)

with open(file_path, "w") as f:
    f.write(content)

print("macOS export options updated in workflow.")
