import os

trimmer_path = "lib/screens/video_trimmer_screen.dart"
if not os.path.exists(trimmer_path):
    print("❌ lib/screens/video_trimmer_screen.dart not found!")
    exit(1)

new_code = """import 'dart:io';
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
      onSave: (outputPath) {
        setState(() => _isProgressVisible = false);
        if (outputPath != null) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Edited video saved successfully at: $outputPath")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to save trimmed video")),
          );
        }
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

with open(trimmer_path, "w", encoding="utf-8") as f:
    f.write(new_code)

print("✅ video_trimmer_screen.dart fixed successfully!")
