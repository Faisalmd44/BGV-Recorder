import 'dart:io';
import 'package:flutter/material.dart';

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
    if (!mounted) return;
    setState(() => _loading = true);

    final List<File> found = [];
    final dir = Directory('/storage/emulated/0/Movies/BackgroundVideoRecorder');
    try {
      if (dir.existsSync()) {
        final files = dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.toLowerCase().endsWith('.mp4'))
            .toList();
        found.addAll(files);
      }
    } catch (_) {}

    found.sort((a, b) {
      try {
        return b.lastModifiedSync().compareTo(a.lastModifiedSync());
      } catch (_) {
        return 0;
      }
    });

    if (!mounted) return;
    setState(() {
      _videos = found;
      _loading = false;
    });
  }

  void _showTrimmingPendingDialog(File file) {
    final fileName = file.path.split('/').last;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.construction_outlined, size: 36),
        title: const Text('Video Trimming Coming Soon'),
        content: Text(
          'Selected recording: $fileName\n\n'
          'Native lossless MP4 trimming is not implemented yet. '
          'Your original video remains safely stored in Movies/BackgroundVideoRecorder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cut & Edit'),
        actions: [
          IconButton(
            tooltip: 'Refresh recordings',
            icon: const Icon(Icons.refresh),
            onPressed: _loadVideos,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: cs.secondaryContainer.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: cs.onSecondaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Video Trimming Under Development',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: cs.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Direct MP4 trimming and saving are not enabled yet. '
                          'You can view your recorded files below; use the History tab for playback and deletion.',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_videos.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.video_library_outlined, size: 56, color: cs.outline),
                    const SizedBox(height: 12),
                    const Text(
                      'No recordings found in Movies/BackgroundVideoRecorder',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ..._videos.map((file) {
              final name = file.path.split('/').last;
              double sizeMb = 0;
              try {
                sizeMb = file.lengthSync() / (1024 * 1024);
              } catch (_) {}
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.movie_outlined),
                  ),
                  title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${sizeMb.toStringAsFixed(2)} MB'),
                  trailing: OutlinedButton.icon(
                    icon: const Icon(Icons.content_cut, size: 18),
                    label: const Text('Trim'),
                    onPressed: () => _showTrimmingPendingDialog(file),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
