import os

main_path = "lib/main.dart"
if not os.path.exists(main_path):
    print("❌ lib/main.dart not found!")
    exit(1)

with open(main_path, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Add imports if not present
imports = []
if "cut_edit_screen.dart" not in content:
    imports.append("import 'screens/cut_edit_screen.dart';")
if "schedule_config_screen.dart" not in content:
    imports.append("import 'screens/schedule_config_screen.dart';")

if imports:
    content = "\n".join(imports) + "\n" + content
    print("✅ Added necessary screen imports.")

# 2. Replace Contact tab / screen references with CutEditScreen
replacements = [
    ("ContactScreen()", "CutEditScreen()"),
    ("contact_screen.dart", "cut_edit_screen.dart"),
    ("BottomNavigationBarItem(icon: Icon(Icons.contacts", "BottomNavigationBarItem(icon: Icon(Icons.cut"),
    ("label: 'Contact'", "label: 'Cut & Edit'"),
    ("label: \"Contact\"", "label: \"Cut & Edit\""),
    ("Icons.person", "Icons.cut"),
]

for old, new in replacements:
    if old in content:
        content = content.replace(old, new)
        print(f"🔄 Replaced '{old}' with '{new}'")

# 3. Add Scheduled Recording card into Home screen if not present
card_snippet = """
// Scheduled Recording Card Added
Container(
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: const Color(0xFF1E1E2C),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.3)),
  ),
  child: Row(
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.deepPurple.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.alarm, color: Colors.deepPurpleAccent, size: 24),
      ),
      const SizedBox(width: 16),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Scheduled Recording", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            SizedBox(height: 2),
            Text("Tap to configure timer & camera", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      IconButton(
        icon: const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScheduleConfigScreen()),
          );
        },
      ),
    ],
  ),
),
"""

if "Scheduled Recording" not in content:
    # Try to inject inside ListView or Column in Home screen
    if "ListView(" in content:
        content = content.replace("ListView(", "ListView(\nchildren: [\n" + card_snippet + "\n", 1)
        print("✅ Added Scheduled Recording card to ListView.")
    elif "Column(" in content:
        content = content.replace("Column(", "Column(\nchildren: [\n" + card_snippet + "\n", 1)
        print("✅ Added Scheduled Recording card to Column.")

with open(main_path, "w", encoding="utf-8") as f:
    f.write(content)

print("🎉 lib/main.dart successfully patched with Scheduled Recording & Cut & Edit tab!")
