import re

file_path = "/home/abubakar/kflkiosk/.github/workflows/auto-build-installers.yml"
with open(file_path, "r") as f:
    content = f.read()

# Make sure we use the new export options for iOS
ios_build_pattern = r'          flutter build ipa --release -t \$ENTRY_FILE --export-options-plist=.*'
ios_build_replacement = r'          flutter build ipa --release -t $ENTRY_FILE --export-options-plist=ios/export_options/${{ matrix.flavor }}.plist'

if re.search(ios_build_pattern, content):
    content = re.sub(ios_build_pattern, ios_build_replacement, content)
else:
    # If the exact pattern isn't found, just find the `flutter build ipa` line
    general_ipa_pattern = r'          flutter build ipa --release -t \$ENTRY_FILE\n'
    general_ipa_replacement = r'          flutter build ipa --release -t $ENTRY_FILE --export-options-plist=ios/export_options/${{ matrix.flavor }}.plist\n'
    content = re.sub(general_ipa_pattern, general_ipa_replacement, content)

with open(file_path, "w") as f:
    f.write(content)

print("iOS export options updated in workflow.")
