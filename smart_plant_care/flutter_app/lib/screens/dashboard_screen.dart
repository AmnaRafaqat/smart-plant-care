import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Matches the path used in the ESP32 firmware: plants/plant1/sensorData
  final DatabaseReference _sensorRef =
      FirebaseDatabase.instance.ref('plants/plant1/sensorData');

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Plant Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Plant Profile',
            onPressed: () => Navigator.pushNamed(context, '/plant-profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _sensorRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('No sensor data yet. Check your ESP32 device.'));
          }

          final data = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );

          final soilMoisture = data['soilMoisture'] ?? 0;
          final light = data['light'] ?? 0;
          final temperature = data['temperature'] ?? 0.0;
          final humidity = data['humidity'] ?? 0.0;

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SensorCard(
                  icon: Icons.water_drop,
                  label: 'Soil Moisture',
                  value: '$soilMoisture%',
                  color: Colors.blue,
                ),
                _SensorCard(
                  icon: Icons.thermostat,
                  label: 'Temperature',
                  value: '${temperature.toStringAsFixed(1)} °C',
                  color: Colors.orange,
                ),
                _SensorCard(
                  icon: Icons.opacity,
                  label: 'Humidity',
                  value: '${humidity.toStringAsFixed(1)} %',
                  color: Colors.teal,
                ),
                _SensorCard(
                  icon: Icons.wb_sunny,
                  label: 'Light Level',
                  value: '$light%',
                  color: Colors.amber,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SensorCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
