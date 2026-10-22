import os

print("🚀 Starting BGV-Recorder Automatic Patching...")

# 1. Update pubspec.yaml
pubspec_path = "pubspec.yaml"
if os.path.exists(pubspec_path):
    with open(pubspec_path, "r") as f:
        content = f.read()
    
    deps = [
        "  shared_preferences: ^2.2.3",
        "  intl: ^0.19.0",
        "  path_provider: ^2.1.2",
        "  permission_handler: ^11.3.1",
        "  video_player: ^2.8.6",
        "  video_trimmer: ^3.0.1",
        "  workmanager: ^0.5.2"
    ]
    
    if "shared_preferences" not in content:
        content = content.replace("dependencies:", "dependencies:\n" + "\n".join(deps))
        with open(pubspec_path, "w") as f:
            f.write(content)
        print("✅ pubspec.yaml updated with dependencies.")
    else:
        print("ℹ️ Dependencies already exist in pubspec.yaml.")

# 2. Create Screens Directory
os.makedirs("lib/screens", exist_ok=True)

# 3. Create schedule_config_screen.dart
schedule_code = """import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class ScheduleConfigScreen extends StatefulWidget {
  const ScheduleConfigScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleConfigScreen> createState() => _ScheduleConfigScreenState();
}

class _ScheduleConfigScreenState extends State<ScheduleConfigScreen> {
  bool _isEnabled = false;
  TimeOfDay _startTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 1, minute: 0);
  String _cameraFacing = 'back';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isEnabled = prefs.getBool('schedule_enabled') ?? false;
      _cameraFacing = prefs.getString('schedule_camera') ?? 'back';
      int startH = prefs.getInt('schedule_start_hour') ?? 0;
      int startM = prefs.getInt('schedule_start_min') ?? 0;
      int endH = prefs.getInt('schedule_end_hour') ?? 1;
      int endM = prefs.getInt('schedule_end_min') ?? 0;
      _startTime = TimeOfDay(hour: startH, minute: startM);
      _endTime = TimeOfDay(hour: endH, minute: endM);
    });
  }

  Future<void> _saveAndSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('schedule_enabled', _isEnabled);
    await prefs.setString('schedule_camera', _cameraFacing);
    await prefs.setInt('schedule_start_hour', _startTime.hour);
    await prefs.setInt('schedule_start_min', _startTime.minute);
    await prefs.setInt('schedule_end_hour', _endTime.hour);
    await prefs.setInt('schedule_end_min', _endTime.minute);

    if (_isEnabled) {
      Workmanager().registerPeriodicTask(
        "bgv_scheduled_recording",
        "bgv_recording_task",
        frequency: const Duration(hours: 24),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Recording Schedule Saved & Activated")),
      );
    } else {
      Workmanager().cancelByUniqueName("bgv_scheduled_recording");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Recording Schedule Disabled")),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121218),
      appBar: AppBar(
        title: const Text("Scheduled Recording", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E2C),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            SwitchListTile(
              title: const Text("Enable Schedule", style: TextStyle(color: Colors.white, fontSize: 16)),
              value: _isEnabled,
              activeColor: Colors.deepPurpleAccent,
              onChanged: (val) => setState(() => _isEnabled = val),
            ),
            const Divider(color: Colors.white24),
            ListTile(
              title: const Text("Start Time", style: TextStyle(color: Colors.white70)),
              trailing: Text(_startTime.format(context), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: _startTime);
                if (picked != null) setState(() => _startTime = picked);
              },
            ),
            ListTile(
              title: const Text("End Time", style: TextStyle(color: Colors.white70)),
              trailing: Text(_endTime.format(context), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              onTap: () async {
                final picked = await showTimePicker(context: context, initialTime: _endTime);
                if (picked != null) setState(() => _endTime = picked);
              },
            ),
            const Divider(color: Colors.white24),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text("Camera Selection", style: TextStyle(color: Colors.white70, fontSize: 14)),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Back Camera", style: TextStyle(color: Colors.white)),
                    value: 'back',
                    groupValue: _cameraFacing,
                    activeColor: Colors.deepPurpleAccent,
                    onChanged: (val) => setState(() => _cameraFacing = val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Front Camera", style: TextStyle(color: Colors.white)),
                    value: 'front',
                    groupValue: _cameraFacing,
                    activeColor: Colors.deepPurpleAccent,
                    onChanged: (val) => setState(() => _cameraFacing = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _saveAndSchedule,
              child: const Text("Save Schedule", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
"""

with open("lib/screens/schedule_config_screen.dart", "w") as f:
    f.write(schedule_code)
print("✅ Created lib/screens/schedule_config_screen.dart")

# 4. Create cut_edit_screen.dart
cut_edit_code = """import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'video_trimmer_screen.dart';

class CutEditScreen extends StatefulWidget {
  const CutEditScreen({Key? key}) : super(key: key);

  @override
  State<CutEditScreen> createState() => _CutEditScreenState();
}

class _CutEditScreenState extends State<CutEditScreen> {
  List<File> _recordings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  Future<void> _loadRecordings() async {
    await Permission.storage.request();
    if (Platform.isAndroid) {
      await Permission.videos.request();
    }

    try {
      final directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final moviesDir = Directory('/storage/emulated/0/Movies/BackgroundVideoRecorder');
      
      List<File> files = [];
      if (moviesDir.existsSync()) {
        files.addAll(moviesDir.listSync().whereType<File>().where((f) => f.path.endsWith('.mp4')));
      }
      if (directory.existsSync()) {
        files.addAll(directory.listSync().whereType<File>().where((f) => f.path.endsWith('.mp4')));
      }

      setState(() {
        _recordings = files.toSet().toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121218),
      appBar: AppBar(
        title: const Text("Cut & Edit Videos", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E2C),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent))
          : _recordings.isEmpty
              ? const Center(
                  child: Text(
                    "No recordings found to edit.",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _recordings.length,
                  itemBuilder: (context, index) {
                    final file = _recordings[index];
                    final fileName = file.path.split('/').last;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2C),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.video_file, color: Colors.deepPurpleAccent, size: 36),
                        title: Text(fileName, style: const TextStyle(color: Colors.white, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text("${(file.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB", style: const TextStyle(color: Colors.grey)),
                        trailing: IconButton(
                          icon: const Icon(Icons.cut, color: Colors.white70),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoTrimmerScreen(videoFile: file),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
"""

with open("lib/screens/cut_edit_screen.dart", "w") as f:
    f.write(cut_edit_code)
print("✅ Created lib/screens/cut_edit_screen.dart")

# 5. Create video_trimmer_screen.dart
trimmer_code = """import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_trimmer/video_trimmer.dart';

class VideoTrimmerScreen extends StatefulWidget {
  final File videoFile;
  const VideoTrimmerScreen({Key? key, required this.videoFile}) : super(key: key);

  @override
  State<VideoTrimmerScreen> createState() => _VideoTrimmerScreenState();
}

class _VideoTrimmerScreenState extends State<VideoTrimmerScreen> {
  final Trimmer _trimmer = Trimmer();
  double _startValue = 0.0;
  double _endValue = 0.0;
  bool _isPlaying = false;
  bool _isProgressVisible = false;

  @override
  void initState() {
    super.initState();
    _trimmer.loadVideo(videoFile: widget.videoFile);
  }

  Future<void> _saveVideo() async {
    setState(() => _isProgressVisible = true);

    await _trimmer.saveTrimmedVideo(
      startValue: _startValue,
      endValue: _endValue,
      storageDir: '/storage/emulated/0/Movies/BackgroundVideoRecorder',
      videoFileName: 'Edited_${DateTime.now().millisecondsSinceEpoch}.mp4',
      onSave: (outputPath) {
        setState(() => _isProgressVisible = false);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Edited video saved successfully at: $outputPath")),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121218),
      appBar: AppBar(
        title: const Text("Trim Video", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E2C),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          _isProgressVisible
              ? const Center(child: Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(color: Colors.white)))
              : IconButton(
                  icon: const Icon(Icons.save, color: Colors.greenAccent),
                  onPressed: _saveVideo,
                ),
        ],
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: VideoViewer(trimmer: _trimmer),
              ),
              const SizedBox(height: 16),
              TrimViewer(
                trimmer: _trimmer,
                viewerHeight: 50.0,
                viewerWidth: MediaQuery.of(context).size.width - 32,
                maxVideoLength: const Duration(minutes: 10),
                onChangeStart: (value) => _startValue = value,
                onChangeEnd: (value) => _endValue = value,
                onChangePlaybackState: (value) => setState(() => _isPlaying = value),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: () async {
                  bool playbackState = await _trimmer.videoPlaybackControl(
                    startValue: _startValue,
                    endValue: _endValue,
                  );
                  setState(() => _isPlaying = playbackState);
                },
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
"""

with open("lib/screens/video_trimmer_screen.dart", "w") as f:
    f.write(trimmer_code)
print("✅ Created lib/screens/video_trimmer_screen.dart")

print("✨ Patching script completed successfully!")

