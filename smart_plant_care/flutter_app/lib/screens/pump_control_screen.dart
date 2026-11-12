import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../app_config.dart';
import '../plant_controller.dart';

/// FR-09: Manual Override / Water Pump Control (Optional).
/// ON/OFF holds the relay; Water Now pulses the pump for 3 seconds.
class PumpControlScreen extends StatefulWidget {
  const PumpControlScreen({super.key});

  @override
  State<PumpControlScreen> createState() => _PumpControlScreenState();
}

class _PumpControlScreenState extends State<PumpControlScreen> {
  static const String functionsBaseUrl = kFunctionsBaseUrl;

  bool _busy = false;

  String? get _plantId => PlantScope.maybeOf(context)?.selectedPlantId;

  Future<void> _sendPump({String mode = 'pulse'}) async {
    final plantId = _plantId;
    if (plantId == null) return;
    setState(() => _busy = true);
    try {
      final response = await http.post(
        Uri.parse('$functionsBaseUrl/triggerPump'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'plantId': plantId, 'mode': mode}),
      );

      if (mounted) {
        final ok = response.statusCode == 200;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok
                ? (mode == 'pulse'
                    ? 'Water Now command sent to the ESP32.'
                    : 'Pump ${mode == 'on' ? 'ON' : 'OFF'} command sent.')
                : 'Could not reach the pump service. The physical pump is not confirmed.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pump command failed (hardware may be offline): $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plantId = _plantId;
    if (plantId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pump Control')),
        body: const Center(child: Text('Select or create a plant first.')),
      );
    }

    final plantRef = FirebaseFirestore.instance.collection('plants').doc(plantId);

    return Scaffold(
      appBar: AppBar(title: const Text('Pump Control')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: plantRef.snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final pumpEnabled = data?['pumpEnabled'] ?? false;
          final pumpOn = data?['pumpOn'] ?? false;
          final pulsePending = data?['pumpCommand'] ?? false;
          final lastWatered = data?['lastWatered'] as Timestamp?;

          if (!pumpEnabled) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Pump hardware is not enabled for this plant.\n\n'
                  'Go to Plant Profile and turn on "Pump Hardware Connected" '
                  'once your relay + water pump are wired to the ESP32 (FR-09, optional feature).',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    pumpOn ? Icons.water_drop : Icons.water_drop_outlined,
                    size: 80,
                    color: pumpOn ? Colors.blue : Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pumpOn
                        ? 'Requested state: ON'
                        : pulsePending
                            ? 'Water Now pulse pending'
                            : 'Requested state: OFF',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This is the command sent to the ESP32. The physical pump '
                    'only runs if hardware is wired and the board is online.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (lastWatered != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Last watered: ${lastWatered.toDate()}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Pump ON / OFF'),
                    subtitle: const Text('Hold the relay on until turned off'),
                    value: pumpOn == true,
                    onChanged: _busy
                        ? null
                        : (on) => _sendPump(mode: on ? 'on' : 'off'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _busy ? null : () => _sendPump(mode: 'pulse'),
                    icon: _busy
                        ? const SizedBox(
                            height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.play_arrow),
                    label: const Text('Water Now'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Water Now runs the pump for about 3 seconds. '
                    'ON keeps it requested on until you switch OFF.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
