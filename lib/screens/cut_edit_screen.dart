import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class CutEditScreen extends StatefulWidget {
  const CutEditScreen({super.key});

  @override
  State<CutEditScreen> createState() => _CutEditScreenState();
}

class _CutEditScreenState extends State<CutEditScreen> {
  static const MethodChannel _channel = MethodChannel('bvr/channel');
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  Future<void> _loadRecordings() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('listRecordings') ?? [];
      final mapped = raw
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
      if (!mounted) return;
      setState(() {
        _items = mapped;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openEditor(Map<String, dynamic> item) async {
    final savedName = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => VideoTrimEditorPage(recording: item),
      ),
    );
    if (savedName != null && mounted) {
      await _loadRecordings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved trimmed video: $savedName')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cut & Edit'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecordings,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.video_library_outlined, size: 56, color: cs.outline),
                        const SizedBox(height: 12),
                        const Text(
                          'No recordings found in Movies/BackgroundVideoRecorder',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _loadRecordings,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final name = (item['name'] as String?) ?? 'Video';
                    final sizeBytes = (item['size'] as num?)?.toDouble() ?? 0.0;
                    final sizeMb = (sizeBytes / (1024 * 1024)).toStringAsFixed(2);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cs.primaryContainer,
                          child: Icon(Icons.movie_outlined, color: cs.onPrimaryContainer),
                        ),
                        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('$sizeMb MB'),
                        trailing: FilledButton.tonalIcon(
                          icon: const Icon(Icons.content_cut, size: 18),
                          label: const Text('Trim'),
                          onPressed: () => _openEditor(item),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class VideoTrimEditorPage extends StatefulWidget {
  final Map<String, dynamic> recording;
  const VideoTrimEditorPage({super.key, required this.recording});

  @override
  State<VideoTrimEditorPage> createState() => _VideoTrimEditorPageState();
}

class _VideoTrimEditorPageState extends State<VideoTrimEditorPage> {
  static const MethodChannel _channel = MethodChannel('bvr/channel');
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _isSaving = false;
  String? _errorMsg;
  double _durationMs = 1000.0;
  RangeValues _rangeMs = const RangeValues(0.0, 1000.0);

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final uriStr = widget.recording['uri'] as String?;
      final pathStr = widget.recording['path'] as String?;
      final VideoPlayerController ctrl;
      if (uriStr != null && uriStr.isNotEmpty) {
        ctrl = VideoPlayerController.contentUri(Uri.parse(uriStr));
      } else if (pathStr != null && pathStr.isNotEmpty) {
        ctrl = VideoPlayerController.file(File(pathStr));
      } else {
        setState(() => _errorMsg = 'Invalid video source');
        return;
      }

      _controller = ctrl;
      await ctrl.initialize();
      ctrl.addListener(_onTick);

      if (!mounted) return;
      final totalMs = ctrl.value.duration.inMilliseconds.toDouble();
      final maxMs = totalMs > 100.0 ? totalMs : 1000.0;
      setState(() {
        _initialized = true;
        _durationMs = maxMs;
        _rangeMs = RangeValues(0.0, maxMs);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = 'Could not load video: $e');
    }
  }

  void _onTick() {
    final ctrl = _controller;
    if (!mounted || ctrl == null || !_initialized) return;
    if (ctrl.value.isPlaying) {
      final posMs = ctrl.value.position.inMilliseconds.toDouble();
      if (posMs >= _rangeMs.end) {
        ctrl.pause();
        ctrl.seekTo(Duration(milliseconds: _rangeMs.start.round()));
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  String _formatMs(double ms) {
    final d = Duration(milliseconds: ms.round());
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final tenths = (d.inMilliseconds.remainder(1000) ~/ 100).toString();
    return '$m:$s.$tenths';
  }

  Future<void> _saveTrimmed() async {
    final startMs = _rangeMs.start.round();
    final endMs = _rangeMs.end.round();
    if (endMs - startMs < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 0.5 seconds to trim.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _controller?.pause();
      final savedName = await _channel.invokeMethod<String>('trimVideo', {
        'uri': widget.recording['uri'],
        'path': widget.recording['path'],
        'startMs': startMs,
        'endMs': endMs,
      });

      if (!mounted) return;
      setState(() => _isSaving = false);
      if (savedName != null) {
        Navigator.of(context).pop(savedName);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to trim video: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller;
    final name = (widget.recording['name'] as String?) ?? 'Trim Video';
    final clipMs = (_rangeMs.end - _rangeMs.start).clamp(0.0, _durationMs);

    return Scaffold(
      appBar: AppBar(
        title: Text(name, style: const TextStyle(fontSize: 16)),
      ),
      body: _errorMsg != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_errorMsg!)))
          : (!_initialized || ctrl == null)
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AspectRatio(
                              aspectRatio: ctrl.value.aspectRatio > 0
                                  ? ctrl.value.aspectRatio
                                  : 16 / 9,
                              child: VideoPlayer(ctrl),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Start: ${_formatMs(_rangeMs.start)}'),
                          Text(
                            'Length: ${_formatMs(clipMs)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('End: ${_formatMs(_rangeMs.end)}'),
                        ],
                      ),
                      RangeSlider(
                        values: _rangeMs,
                        min: 0.0,
                        max: _durationMs,
                        onChanged: (values) {
                          setState(() => _rangeMs = values);
                          ctrl.seekTo(Duration(milliseconds: values.start.round()));
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton.filledTonal(
                            iconSize: 32,
                            icon: Icon(
                              ctrl.value.isPlaying ? Icons.pause : Icons.play_arrow,
                            ),
                            onPressed: () {
                              setState(() {
                                if (ctrl.value.isPlaying) {
                                  ctrl.pause();
                                } else {
                                  ctrl.seekTo(
                                    Duration(milliseconds: _rangeMs.start.round()),
                                  );
                                  ctrl.play();
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
                          onPressed: _isSaving ? null : _saveTrimmed,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.content_cut),
                          label: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              _isSaving ? 'Trimming & Saving...' : 'Save Trimmed Video',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
