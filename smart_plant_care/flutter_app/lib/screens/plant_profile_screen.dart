import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../plant_controller.dart';

/// FR-04: Plant Profile Management - create/edit a plant with custom thresholds.
class PlantProfileScreen extends StatefulWidget {
  const PlantProfileScreen({super.key});

  @override
  State<PlantProfileScreen> createState() => _PlantProfileScreenState();
}

class _PlantProfileScreenState extends State<PlantProfileScreen> {
  final _plantNameController = TextEditingController();
  final _plantTypeController = TextEditingController();
  final _minMoistureController = TextEditingController(text: '30');
  final _maxMoistureController = TextEditingController(text: '70');
  final _minTempController = TextEditingController(text: '15');
  final _maxTempController = TextEditingController(text: '32');
  final _minLightController = TextEditingController(text: '20');
  final _maxLightController = TextEditingController(text: '90');
  bool _pumpEnabled = false;
  bool _isSaving = false;
  bool _isLoading = true;
  String? _loadedPlantId;

  DocumentReference? get _plantRef {
    final id = PlantScope.maybeOf(context)?.selectedPlantId;
    if (id == null) return null;
    return FirebaseFirestore.instance.collection('plants').doc(id);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = PlantScope.maybeOf(context)?.selectedPlantId;
    if (id != _loadedPlantId) {
      _loadedPlantId = id;
      _loadProfile();
    } else if (_isLoading && id == null) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProfile() async {
    final ref = _plantRef;
    if (ref == null) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    final snap = await ref.get();
    if (snap.exists) {
      final data = snap.data() as Map<String, dynamic>;
      _plantNameController.text = data['name']?.toString() ?? '';
      _plantTypeController.text = data['type']?.toString() ?? '';
      _minMoistureController.text = (data['minMoisture'] ?? 30).toString();
      _maxMoistureController.text = (data['maxMoisture'] ?? 70).toString();
      _minTempController.text = (data['minTemp'] ?? 15).toString();
      _maxTempController.text = (data['maxTemp'] ?? 32).toString();
      _minLightController.text = (data['minLight'] ?? 20).toString();
      _maxLightController.text = (data['maxLight'] ?? 90).toString();
      _pumpEnabled = data['pumpEnabled'] ?? false;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    var ref = _plantRef;
    setState(() => _isSaving = true);
    try {
      if (ref == null) {
        final plants = PlantScope.of(context);
        await plants.createPlant(
          name: _plantNameController.text.trim().isEmpty
              ? 'My Plant'
              : _plantNameController.text.trim(),
        );
        ref = _plantRef;
      }
      if (ref == null) return;

      await ref.set({
        'name': _plantNameController.text.trim(),
        'type': _plantTypeController.text.trim(),
        'minMoisture': int.tryParse(_minMoistureController.text) ?? 30,
        'maxMoisture': int.tryParse(_maxMoistureController.text) ?? 70,
        'minTemp': int.tryParse(_minTempController.text) ?? 15,
        'maxTemp': int.tryParse(_maxTempController.text) ?? 32,
        'minLight': int.tryParse(_minLightController.text) ?? 20,
        'maxLight': int.tryParse(_maxLightController.text) ?? 90,
        'pumpEnabled': _pumpEnabled,
        'ownerId': FirebaseAuth.instance.currentUser?.uid,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plant profile saved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _addAnotherPlant() async {
    try {
      await PlantScope.of(context).createPlant(name: 'New Plant');
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New plant added. Edit its details and save.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plantId = PlantScope.maybeOf(context)?.selectedPlantId;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Profile'),
        actions: [
          IconButton(
            tooltip: 'Add another plant',
            icon: const Icon(Icons.add),
            onPressed: _addAnotherPlant,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (plantId != null)
              Card(
                child: ListTile(
                  title: const Text('ESP32 Plant ID'),
                  subtitle: Text(plantId),
                  trailing: const Icon(Icons.copy, size: 18),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _plantNameController,
              decoration: const InputDecoration(labelText: 'Plant Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _plantTypeController,
              decoration: const InputDecoration(labelText: 'Plant Type (e.g. Money Plant)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            const Text('Safe Ranges', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minMoistureController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Min Moisture %', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxMoistureController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max Moisture %', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minTempController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Min Temp °C', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxTempController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max Temp °C', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minLightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Min Light %', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxLightController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max Light %', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Pump Hardware Connected (FR-09)'),
              subtitle: const Text('Enable manual watering from the app'),
              value: _pumpEnabled,
              onChanged: (val) => setState(() => _pumpEnabled = val),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(plantId == null ? 'Create Plant' : 'Save Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
