import 'dart:io';
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
