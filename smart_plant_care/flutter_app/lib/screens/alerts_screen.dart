import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../plant_controller.dart';
import '../plant_status.dart';

/// FR-06: Automated Alerts - shows the history of push notifications sent.
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final plantId = PlantScope.maybeOf(context)?.selectedPlantId;
    if (plantId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alerts')),
        body: const Center(child: Text('Select or create a plant first.')),
      );
    }

    final alertsQuery = FirebaseFirestore.instance
        .collection('plants')
        .doc(plantId)
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .limit(50);

    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: StreamBuilder<QuerySnapshot>(
        stream: alertsQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Could not load alerts: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No alerts yet. You\'ll see a notification here whenever a reading '
                  'crosses the threshold set in your Plant Profile.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final ts = data['timestamp'] as Timestamp?;
              final timeStr = ts != null ? DateFormat('MMM d, y — h:mm a').format(ts.toDate()) : '';
              final rawLevel = (data['level'] ?? 'warning').toString();
              final level = rawLevel == 'critical' ? PlantLevel.critical : PlantLevel.warning;
              final color = plantLevelColor(level);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    level == PlantLevel.critical ? Icons.error : Icons.warning_amber_rounded,
                    color: color,
                  ),
                  title: Text(data['message'] ?? ''),
                  subtitle: Text(
                    '${plantLevelLabel(level)}  $timeStr',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
