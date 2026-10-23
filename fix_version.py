import os

pubspec_path = "pubspec.yaml"
if not os.path.exists(pubspec_path):
    print("❌ pubspec.yaml not found!")
    exit(1)

with open(pubspec_path, "r", encoding="utf-8") as f:
    content = f.read()

# Check if dependency_overrides already exists
if "dependency_overrides:" not in content:
    override_block = "\ndependency_overrides:\n  intl: ^0.19.0\n"
    content += override_block
    print("✅ Added dependency_overrides for intl.")
else:
    # Ensure intl override is present
    if "intl:" not in content.split("dependency_overrides:")[1]:
        content = content.replace("dependency_overrides:", "dependency_overrides:\n  intl: ^0.19.0")
        print("✅ Updated dependency_overrides.")

with open(pubspec_path, "w", encoding="utf-8") as f:
    f.write(content)

print("🎉 pubspec.yaml version conflict resolved!")
