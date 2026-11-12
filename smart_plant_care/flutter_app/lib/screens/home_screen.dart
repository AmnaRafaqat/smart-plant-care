import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../plant_controller.dart';
import '../plant_status.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final plants = PlantScope.maybeOf(context);
    if (plants == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (plants.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final plantId = plants.selectedPlantId;
    final plantRef = plantId == null
        ? null
        : FirebaseFirestore.instance.collection('plants').doc(plantId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Plant Dashboard'),
        actions: [
          if (plants.plants.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: 'Select plant',
              initialValue: plantId,
              onSelected: (id) => plants.selectPlant(id),
              itemBuilder: (context) => plants.plants
                  .map((doc) => PopupMenuItem(
                        value: doc.id,
                        child: Text(
                          (doc.data()['name'] as String?)?.trim().isNotEmpty == true
                              ? doc.data()['name'] as String
                              : doc.id,
                        ),
                      ))
                  .toList(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const Icon(Icons.local_florist),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        plants.selectedPlantName ?? 'Plant',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: plantRef == null
          ? _NoPlantCard(onAdd: () => Navigator.pushNamed(context, '/plant-profile'))
          : StreamBuilder<DocumentSnapshot>(
              stream: plantRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final latest = data?['latestReading'] as Map<String, dynamic>?;
                final overall = (latest != null && data != null)
                    ? overallPlantLevel(latest, data)
                    : null;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (overall != null) _OverallStatusBanner(level: overall),
                    if (latest == null)
                      const _EmptyStateCard()
                    else
                      _LiveReadingGrid(latest: latest, thresholds: data!),
                    const SizedBox(height: 24),
                    _NavTile(
                      icon: Icons.eco,
                      label: 'Plant Profile',
                      subtitle: 'Add / edit plant & thresholds',
                      onTap: () => Navigator.pushNamed(context, '/plant-profile'),
                    ),
                    _NavTile(
                      icon: Icons.show_chart,
                      label: 'History & Charts',
                      subtitle: 'View trends over time (FR-10)',
                      onTap: () => Navigator.pushNamed(context, '/history'),
                    ),
                    _NavTile(
                      icon: Icons.notifications_active,
                      label: 'Alerts',
                      subtitle: 'Threshold breach notifications (FR-06)',
                      onTap: () => Navigator.pushNamed(context, '/alerts'),
                    ),
                    _NavTile(
                      icon: Icons.psychology,
                      label: 'AI Watering Prediction',
                      subtitle: 'When will it need water next? (FR-07/08)',
                      onTap: () => Navigator.pushNamed(context, '/ai-prediction'),
                    ),
                    _NavTile(
                      icon: Icons.water_drop,
                      label: 'Pump Control',
                      subtitle: 'Manually trigger watering (FR-09)',
                      onTap: () => Navigator.pushNamed(context, '/pump-control'),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _NoPlantCard extends StatelessWidget {
  final VoidCallback onAdd;
  const _NoPlantCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No plants yet. Create a plant profile to start monitoring.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onAdd, child: const Text('Add plant')),
          ],
        ),
      ),
    );
  }
}

class _OverallStatusBanner extends StatelessWidget {
  final PlantLevel level;
  const _OverallStatusBanner({required this.level});

  @override
  Widget build(BuildContext context) {
    final color = plantLevelColor(level);
    return Card(
      color: color.withOpacity(0.15),
      child: ListTile(
        leading: Icon(
          level == PlantLevel.safe
              ? Icons.check_circle
              : level == PlantLevel.warning
                  ? Icons.warning_amber_rounded
                  : Icons.error,
          color: color,
        ),
        title: Text('Status: ${plantLevelLabel(level)}'),
        subtitle: Text(
          level == PlantLevel.safe
              ? 'Readings are within the healthy range.'
              : level == PlantLevel.warning
                  ? 'A reading is near the edge of the preferred range.'
                  : 'A reading needs immediate attention.',
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'No sensor data yet. Put this plant\'s ID into the ESP32 firmware '
          '(Plant Profile screen) and make sure the board is on WiFi.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _LiveReadingGrid extends StatelessWidget {
  final Map<String, dynamic> latest;
  final Map<String, dynamic> thresholds;

  const _LiveReadingGrid({required this.latest, required this.thresholds});

  @override
  Widget build(BuildContext context) {
    final soil = (latest['soilMoisture'] ?? 0) as num;
    final light = (latest['light'] ?? 0) as num;
    final temp = (latest['temperature'] ?? 0) as num;
    final hum = (latest['humidity'] ?? 0) as num;

    final soilLevel = levelForValue(soil, thresholds['minMoisture'], thresholds['maxMoisture']);
    final tempLevel = levelForValue(temp, thresholds['minTemp'], thresholds['maxTemp']);
    final lightLevel = levelForValue(light, thresholds['minLight'], thresholds['maxLight']);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: [
        _ReadingCard(
          icon: Icons.water_drop,
          label: 'Soil Moisture',
          value: '$soil%',
          level: soilLevel,
        ),
        _ReadingCard(
          icon: Icons.thermostat,
          label: 'Temperature',
          value: '${temp.toStringAsFixed(1)}°C',
          level: tempLevel,
        ),
        _ReadingCard(
          icon: Icons.opacity,
          label: 'Humidity',
          value: '$hum%',
          level: PlantLevel.safe,
          showStatus: false,
        ),
        _ReadingCard(
          icon: Icons.wb_sunny,
          label: 'Light',
          value: '$light%',
          level: lightLevel,
        ),
      ],
    );
  }
}

class _ReadingCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final PlantLevel level;
  final bool showStatus;

  const _ReadingCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.level,
    this.showStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = showStatus ? plantLevelColor(level) : Colors.teal;
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12)),
            if (showStatus)
              Text(
                plantLevelLabel(level),
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(label),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
