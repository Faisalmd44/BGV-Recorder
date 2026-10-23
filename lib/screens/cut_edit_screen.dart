import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'video_trimmer_screen.dart';

class CutEditScreen extends StatefulWidget {
  const CutEditScreen({super.key});

  @override
  State<CutEditScreen> createState() => _CutEditScreenState();
}

class _CutEditScreenState extends State<CutEditScreen> {
  List<File> _videos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() => _loading = true);
    await Permission.storage.request();
    await Permission.videos.request();

    final List<File> found = [];
    final dirs = [
      Directory('/storage/emulated/0/Movies/BackgroundVideoRecorder'),
      Directory('/storage/emulated/0/Movies'),
    ];

    for (final d in dirs) {
      try {
        if (d.existsSync()) {
          final files = d
              .listSync()
              .whereType<File>()
              .where((f) => f.path.toLowerCase().endsWith('.mp4'))
              .toList();
          found.addAll(files);
        }
      } catch (_) {}
    }

    found.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    if (!mounted) return;
    setState(() {
      _videos = found;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cut & Edit Videos"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVideos,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _videos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text("No recorded videos found in Movies/BackgroundVideoRecorder"),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _loadVideos,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Refresh"),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _videos.length,
                  itemBuilder: (context, index) {
                    final file = _videos[index];
                    final name = file.path.split('/').last;
                    final sizeMb = (file.lengthSync() / (1024 * 1024)).toStringAsFixed(2);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.movie_creation_outlined),
                        ),
                        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text("$sizeMb MB"),
                        trailing: FilledButton.tonalIcon(
                          icon: const Icon(Icons.content_cut, size: 18),
                          label: const Text("Trim"),
                          onPressed: () async {
                            final res = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VideoTrimmerScreen(videoFile: file),
                              ),
                            );
                            if (res == true) {
                              _loadVideos();
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
