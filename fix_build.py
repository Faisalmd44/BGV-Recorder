import os

print("🛠️ Fixing pubspec.yaml and main.dart...")

# 1. Fix pubspec.yaml
pubspec_path = "pubspec.yaml"
if os.path.exists(pubspec_path):
    with open(pubspec_path, "r", encoding="utf-8") as f:
        content = f.read()

    required_deps = [
        "  shared_preferences: ^2.5.3",
        "  intl: ^0.19.0",
        "  path_provider: ^2.1.2",
        "  permission_handler: ^11.4.0",
        "  video_player: ^2.10.0",
        "  video_trimmer: ^3.0.1",
        "  workmanager: ^0.5.2"
    ]

    if "video_trimmer:" not in content:
        dep_block = "dependencies:\n  flutter:\n    sdk: flutter\n" + "\n".join(required_deps) + "\n"
        content = content.replace("dependencies:\n  flutter:\n    sdk: flutter", dep_block)
        with open(pubspec_path, "w", encoding="utf-8") as f:
            f.write(content)
        print("✅ pubspec.yaml updated with all dependencies!")

# 2. Fix lib/main.dart for proper navigation and screen integration
main_path = "lib/main.dart"
if os.path.exists(main_path):
    with open(main_path, "r", encoding="utf-8") as f:
        main_content = f.read()

    # Replace ContactScreen with CutEditScreen in navigation and tabs
    main_content = main_content.replace("ContactScreen()", "CutEditScreen()")
    main_content = main_content.replace("contact_screen.dart", "cut_edit_screen.dart")
    main_content = main_content.replace("label: 'Contact'", "label: 'Cut & Edit'")
    main_content = main_content.replace("label: \"Contact\"", "label: \"Cut & Edit\"")
    main_content = main_content.replace("Icons.contacts", "Icons.cut")
    main_content = main_content.replace("Icons.person", "Icons.cut")

    with open(main_path, "w", encoding="utf-8") as f:
        f.write(main_content)
    print("✅ lib/main.dart navigation updated!")

print("🎉 All build fixes applied successfully!")
