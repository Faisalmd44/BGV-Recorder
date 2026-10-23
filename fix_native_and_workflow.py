import os

# 1. Fix android/app/build.gradle.kts for native libs merging
gradle_path = "android/app/build.gradle.kts"
if os.path.exists(gradle_path):
    with open(gradle_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Enhanced packaging block to resolve native libs merge conflicts
    robust_packaging = """
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
        pickFirsts += listOf(
            "lib/arm64-v8a/libc++_shared.so",
            "lib/armeabi-v7a/libc++_shared.so",
            "lib/x86/libc++_shared.so",
            "lib/x86_64/libc++_shared.so",
            "lib/*/libc++_shared.so"
        )
    }
"""

    if "packaging {" in content:
        # Replace existing packaging block with robust one
        # Let's simple remove old packaging block or insert it cleanly
        import re
        content = re.sub(r'packaging\s*\{[^}]*\}', robust_packaging.strip(), content, flags=re.DOTALL)
    else:
        if "defaultConfig {" in content:
            content = content.replace("defaultConfig {", robust_packaging + "\n    defaultConfig {")

    with open(gradle_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ android/app/build.gradle.kts updated with pickFirsts!")

# 2. Fix .github/workflows/android.yml artifact path
workflow_path = ".github/workflows/android.yml"
if os.path.exists(workflow_path):
    with open(workflow_path, "r", encoding="utf-8") as f:
        wf_content = f.read()

    wf_content = wf_content.replace("app-debug.apk", "app-release.apk")
    
    with open(workflow_path, "w", encoding="utf-8") as f:
        f.write(wf_content)
    print("✅ .github/workflows/android.yml artifact path corrected to release APK!")

print("🎉 All native merge and workflow fixes applied successfully!")
