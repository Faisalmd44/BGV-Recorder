import os

file_path = "android/app/build.gradle.kts"
if not os.path.exists(file_path):
    print("❌ android/app/build.gradle.kts not found!")
    exit(1)

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Replace single quotes inside excludes with double quotes for Kotlin DSL syntax
content = content.replace("excludes += '/META-INF/{AL2.0,LGPL2.1}'", 'excludes += "/META-INF/{AL2.0,LGPL2.1}"')
content = content.replace("excludes += \"/META-INF/{AL2.0,LGPL2.1}'", 'excludes += "/META-INF/{AL2.0,LGPL2.1}"')

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("✅ build.gradle.kts syntax fixed with double quotes!")
