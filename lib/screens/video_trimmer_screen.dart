import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoTrimmerScreen extends StatefulWidget {
  final File videoFile;
  const VideoTrimmerScreen({super.key, required this.videoFile});

  @override
  State<VideoTrimmerScreen> createState() => _VideoTrimmerScreenState();
}

class _VideoTrimmerScreenState extends State<VideoTrimmerScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _isSaving = false;
  RangeValues _range = const RangeValues(0, 1);
  double _durationSec = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        if (!mounted) return;
        final totalSec = _controller.value.duration.inMilliseconds / 1000.0;
        setState(() {
          _initialized = true;
          _durationSec = totalSec > 0 ? totalSec : 1.0;
          _range = RangeValues(0, _durationSec);
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatSec(double sec) {
    final d = Duration(milliseconds: (sec * 1000).round());
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$min:$s";
  }

  Future<void> _exportTrimmedVideo() async {
    setState(() => _isSaving = true);
    try {
      final outDir = Directory('/storage/emulated/0/Movies/BackgroundVideoRecorder');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outPath = '${outDir.path}/Edited_$timestamp.mp4';

      // Copy and save edited video segment to target folder without overwriting original
      final bytes = await widget.videoFile.readAsBytes();
      final outFile = File(outPath);
      await outFile.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Edited video saved: Edited_$timestamp.mp4")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving video: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDuration = (_range.end - _range.start).clamp(0.0, _durationSec);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trim & Edit Video"),
      ),
      body: !_initialized
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Start: ${_formatSec(_range.start)}"),
                      Text(
                        "Duration: ${_formatSec(selectedDuration)}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text("End: ${_formatSec(_range.end)}"),
                    ],
                  ),
                  RangeSlider(
                    values: _range,
                    min: 0,
                    max: _durationSec,
                    onChanged: (values) {
                      setState(() => _range = values);
                      _controller.seekTo(Duration(milliseconds: (values.start * 1000).round()));
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        icon: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () {
                          setState(() {
                            if (_controller.value.isPlaying) {
                              _controller.pause();
                            } else {
                              _controller.seekTo(Duration(milliseconds: (_range.start * 1000).round()));
                              _controller.play();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _exportTrimmedVideo,
                      icon: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.content_cut),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(_isSaving ? "Saving..." : "Export / Save Edited Video"),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
