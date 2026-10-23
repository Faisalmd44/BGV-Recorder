import os

# 1. Update android/app/build.gradle.kts
gradle_path = "android/app/build.gradle.kts"
clean_gradle = """plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.background_video_recorder"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.background_video_recorder"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86_64"))
        }
    }

    packaging {
        resources {
            excludes += listOf(
                "/META-INF/{AL2.0,LGPL2.1}",
                "/META-INF/*.version"
            )
        }
        jniLibs {
            pickFirsts += listOf(
                "**/libc++_shared.so",
                "**/libffmpegkit.so",
                "**/libffmpegkit_abidetect.so",
                "**/*.so"
            )
            keepDebugSymbols += listOf(
                "**/*.so"
            )
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
"""

with open(gradle_path, "w", encoding="utf-8") as f:
    f.write(clean_gradle)
print("✅ android/app/build.gradle.kts updated cleanly without useLegacyPackaging!")

# 2. Update .github/workflows/android.yml to verbose build and release APK artifact
workflow_path = ".github/workflows/android.yml"
if os.path.exists(workflow_path):
    with open(workflow_path, "r", encoding="utf-8") as f:
        wf = f.read()

    # Ensure verbose flag so any gradle detail is shown
    if "flutter build apk --release --no-pub" in wf and "-v" not in wf:
        wf = wf.replace("flutter build apk --release --no-pub", "flutter build apk --release --no-pub -v")
    elif "flutter build apk --release" in wf and "-v" not in wf:
        wf = wf.replace("flutter build apk --release", "flutter build apk --release -v")

    # Ensure artifact is app-release.apk
    wf = wf.replace("app-debug.apk", "app-release.apk")

    with open(workflow_path, "w", encoding="utf-8") as f:
        f.write(wf)
    print("✅ .github/workflows/android.yml updated with verbose release build!")

# 3. Ensure gradle.properties has AndroidX & Jetifier
prop_path = "android/gradle.properties"
if os.path.exists(prop_path):
    with open(prop_path, "r", encoding="utf-8") as f:
        prop = f.read()
    if "android.enableJetifier" not in prop:
        prop += "\nandroid.useAndroidX=true\nandroid.enableJetifier=true\n"
        with open(prop_path, "w", encoding="utf-8") as f:
            f.write(prop)
        print("✅ android/gradle.properties updated with AndroidX & Jetifier!")

print("🎉 Setup completely patched!")
