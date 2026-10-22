import 'package:flutter/material.dart';
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
