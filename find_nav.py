import os

print("🔍 Searching for Bottom Navigation in project...")
lib_dir = "lib"
found_files = []

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith(".dart"):
            filepath = os.path.join(root, file)
            try:
                with open(filepath, "r", encoding="utf-8") as f:
                    content = f.read()
                if "BottomNavigationBar" in content or "bottomNavigationBar" in content or "BottomNavigationBarItem" in content:
                    found_files.append(filepath)
                    print(f"🎯 Mil gaya! File: {filepath}")
            except Exception as e:
                pass

if not found_files:
    print("❌ Kisi bhi file mein BottomNavigationBar nahi mila. Shayad app ka structure alag hai.")
else:
    print(f"\nTotal {len(found_files)} file(s) mein navigation mila hai. Aap inhi files ko edit karke 'Cut & Edit' tab add kar sakte hain.")

