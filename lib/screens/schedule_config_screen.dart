import 'screens/cut_edit_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScheduleManager {
  static Timer? _timer;
  static const MethodChannel _channel = MethodChannel('com.example.bgv_recorder/recorder');

  static Future<void> initScheduler() async {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      await _checkAndTrigger();
    });
  }

  static Future<void> _checkAndTrigger() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('schedule_enabled') ?? false;
    if (!enabled) return;

    final startMs = prefs.getInt('schedule_start_ms') ?? 0;
    final endMs = prefs.getInt('schedule_end_ms') ?? 0;
    final camera = prefs.getString('schedule_camera') ?? 'back';
    final isTriggered = prefs.getBool('schedule_triggered') ?? false;

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    if (nowMs >= startMs && nowMs < endMs && !isTriggered) {
      await prefs.setBool('schedule_triggered', true);
      try {
        await _channel.invokeMethod('startRecording', {
          'camera': camera,
          'quality': '1080p',
        });
      } catch (_) {}
    } else if (nowMs >= endMs && isTriggered) {
      await prefs.setBool('schedule_triggered', false);
      await prefs.setBool('schedule_enabled', false);
      try {
        await _channel.invokeMethod('stopRecording');
      } catch (_) {}
    }
  }
}

class ScheduleConfigScreen extends StatefulWidget {
  const ScheduleConfigScreen({super.key});

  @override
  State<ScheduleConfigScreen> createState() => _ScheduleConfigScreenState();
}

class _ScheduleConfigScreenState extends State<ScheduleConfigScreen> {
  bool _isEnabled = false;
  DateTime _startDateTime = DateTime.now().add(const Duration(minutes: 5));
  DateTime _endDateTime = DateTime.now().add(const Duration(minutes: 35));
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
      final startMs = prefs.getInt('schedule_start_ms');
      final endMs = prefs.getInt('schedule_end_ms');
      if (startMs != null && startMs > DateTime.now().millisecondsSinceEpoch) {
        _startDateTime = DateTime.fromMillisecondsSinceEpoch(startMs);
      }
      if (endMs != null && endMs > DateTime.now().millisecondsSinceEpoch) {
        _endDateTime = DateTime.fromMillisecondsSinceEpoch(endMs);
      }
    });
  }

  Future<void> _pickDateTime(bool isStart) async {
    final initial = isStart ? _startDateTime : _endDateTime;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    final selected = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startDateTime = selected;
        if (_endDateTime.isBefore(_startDateTime)) {
          _endDateTime = _startDateTime.add(const Duration(minutes: 30));
        }
      } else {
        _endDateTime = selected;
      }
    });
  }

  Future<void> _saveSchedule() async {
    if (_endDateTime.isBefore(_startDateTime) || _endDateTime.isAtSameMomentAs(_startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End time must be after Start time!")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('schedule_enabled', _isEnabled);
    await prefs.setString('schedule_camera', _cameraFacing);
    await prefs.setInt('schedule_start_ms', _startDateTime.millisecondsSinceEpoch);
    await prefs.setInt('schedule_end_ms', _endDateTime.millisecondsSinceEpoch);
    await prefs.setBool('schedule_triggered', false);

    await ScheduleManager.initScheduler();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEnabled ? "Schedule Saved & Active!" : "Schedule Disabled"),
      ),
    );
    Navigator.pop(context, true);
  }

  Future<void> _cancelSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('schedule_enabled', false);
    await prefs.setBool('schedule_triggered', false);
    setState(() => _isEnabled = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Schedule Cancelled")),
    );
    Navigator.pop(context, true);
  }

  String _formatDt(DateTime dt) {
    final d = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
    final t = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    return "$d  $t";
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scheduled Recording"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: SwitchListTile(
              secondary: Icon(Icons.alarm_on, color: cs.primary),
              title: const Text("Enable Scheduled Recording", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(_isEnabled ? "Active - Will record automatically" : "Currently disabled"),
              value: _isEnabled,
              onChanged: (val) => setState(() => _isEnabled = val),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: const Text("Start Date & Time"),
                  subtitle: Text(_formatDt(_startDateTime), style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () => _pickDateTime(true),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.stop_circle_outlined),
                  title: const Text("End Date & Time"),
                  subtitle: Text(_formatDt(_endDateTime), style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () => _pickDateTime(false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text("Select Camera", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text("Back Camera")),
                  selected: _cameraFacing == 'back',
                  onSelected: (_) => setState(() => _cameraFacing = 'back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text("Front Camera")),
                  selected: _cameraFacing == 'front',
                  onSelected: (_) => setState(() => _cameraFacing = 'front'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _saveSchedule,
            icon: const Icon(Icons.save),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text("Save Schedule", style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _cancelSchedule,
            icon: const Icon(Icons.cancel_outlined),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text("Cancel Schedule"),
            ),
          ),
        ],
      ),
    );
  }
}
