import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PlantProfileScreen extends StatefulWidget {
  const PlantProfileScreen({super.key});

  @override
  State<PlantProfileScreen> createState() => _PlantProfileScreenState();
}

class _PlantProfileScreenState extends State<PlantProfileScreen> {
  final DatabaseReference _profileRef =
      FirebaseDatabase.instance.ref('plants/plant1/profile');

  final _plantNameController = TextEditingController();
  final _minMoistureController = TextEditingController(text: '30');
  final _maxMoistureController = TextEditingController(text: '70');
  bool _isSaving = false;

  Future<void> _loadProfile() async {
    final snapshot = await _profileRef.get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      _plantNameController.text = data['plantName']?.toString() ?? '';
      _minMoistureController.text = data['minMoisture']?.toString() ?? '30';
      _maxMoistureController.text = data['maxMoisture']?.toString() ?? '70';
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await _profileRef.set({
        'plantName': _plantNameController.text.trim(),
        'minMoisture': int.tryParse(_minMoistureController.text) ?? 30,
        'maxMoisture': int.tryParse(_maxMoistureController.text) ?? 70,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plant profile saved.')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plant Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _plantNameController,
              decoration: const InputDecoration(
                labelText: 'Plant Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _minMoistureController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minimum Soil Moisture (%)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _maxMoistureController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Maximum Soil Moisture (%)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
