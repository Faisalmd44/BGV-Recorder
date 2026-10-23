import os

gradle_path = "android/app/build.gradle"
if not os.path.exists(gradle_path):
    print("❌ android/app/build.gradle not found!")
    exit(1)

with open(gradle_path, "r", encoding="utf-8") as f:
    content = f.read()

# Check if defaultConfig has minSdk >= 24 (video_trimmer requires minSdk 24)
content = content.replace("minSdkVersion flutter.minSdkVersion", "minSdk 24")
content = content.replace("minSdk 21", "minSdk 24")

# Add packagingOptions / packaging block inside android { ... } to merge conflicting native libraries smoothly
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
    # Inject before the last closing brace of android { ... }
    # Let's find 'defaultConfig {' or insert inside android block
    if "defaultConfig {" in content:
        content = content.replace("defaultConfig {", packaging_block + "\n    defaultConfig {")
        print("✅ Added packaging block to android/app/build.gradle")

with open(gradle_path, "w", encoding="utf-8") as f:
    f.write(content)

print("✅ android/app/build.gradle successfully patched!")
