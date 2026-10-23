import os

print("🔍 Searching for Gradle configuration files in android/...")

target_files = []
for root, dirs, files in os.walk("android"):
    for file in files:
        if "build.gradle" in file:
            target_files.append(os.path.join(root, file))

if not target_files:
    print("❌ No build.gradle files found in android/ folder!")
    exit(1)

for file_path in target_files:
    print(f"🎯 Patching: {file_path}")
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Update minSdk to 24
    content = content.replace("minSdkVersion flutter.minSdkVersion", "minSdk = 24")
    content = content.replace("minSdkVersion flutter.minSdkVersion", "minSdk 24")
    content = content.replace("minSdk 21", "minSdk 24")
    content = content.replace("minSdkVersion 21", "minSdk 24")

    # Add packaging block for native .so libraries merging
    packaging_block = """
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
        resources {
            excludes += '/META-INF/{AL2.0,LGPL2.1}'
        }
    }
"""

    if "packaging {" not in content and "packagingOptions {" not in content:
        if "defaultConfig {" in content:
            content = content.replace("defaultConfig {", packaging_block + "\n    defaultConfig {")
            print(f"✅ Added packaging block to {file_path}")

    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)

print("🎉 All Gradle files patched successfully!")
