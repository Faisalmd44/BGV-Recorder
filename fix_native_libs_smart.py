import os

print("🔍 Searching for android/app/build.gradle...")
gradle_path = None

for root, dirs, files in os.walk("."):
    if "build.gradle" in files and "app" in root:
        path = os.path.join(root, "build.gradle")
        if "android" in path:
            gradle_path = path
            break

if not gradle_path and os.path.exists("android/app/build.gradle"):
    gradle_path = "android/app/build.gradle"

if not gradle_path:
    print("❌ Error: build.gradle not found anywhere in project folders!")
    exit(1)

print(f"🎯 Found build.gradle at: {gradle_path}")

with open(gradle_path, "r", encoding="utf-8") as f:
    content = f.read()

# Update minSdk to 24 (required by video_trimmer / ffmpeg)
content = content.replace("minSdkVersion flutter.minSdkVersion", "minSdk 24")
content = content.replace("minSdk 21", "minSdk 24")
content = content.replace("minSdkVersion 21", "minSdk 24")

# Add packaging block for native .so libraries merging conflict
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
        print("✅ Added packaging block successfully.")

with open(gradle_path, "w", encoding="utf-8") as f:
    f.write(content)

print("✅ build.gradle successfully patched!")
