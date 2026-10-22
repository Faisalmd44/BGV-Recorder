import os

pubspec_path = "pubspec.yaml"
if not os.path.exists(pubspec_path):
    print("❌ pubspec.yaml not found!")
    exit(1)

with open(pubspec_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

new_lines = []
in_dependencies = False
seen_deps = set()

for line in lines:
    stripped = line.strip()
    if stripped == "dependencies:":
        in_dependencies = True
        new_lines.append(line)
        continue
    
    if in_dependencies:
        # If we hit another top-level section
        if line and not line.startswith(" ") and not line.startswith("\t") and stripped.endswith(":"):
            in_dependencies = False
            new_lines.append(line)
            continue
        
        # Check dependency key
        if ":" in stripped and not stripped.startswith("#"):
            key = stripped.split(":")[0].strip()
            if key in seen_deps:
                print(f"🔄 Removing duplicate key: {key}")
                continue
            seen_deps.add(key)
            
    new_lines.append(line)

with open(pubspec_path, "w", encoding="utf-8") as f:
    f.writelines(new_lines)

print("✅ pubspec.yaml duplicates cleaned successfully!")
