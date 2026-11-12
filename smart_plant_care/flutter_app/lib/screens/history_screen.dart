import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../plant_controller.dart';

/// FR-10: Data History and Visualization - line and bar charts over time.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _rangeDays = 7; // 7 or 30

  Query? _readingsQuery(String? plantId) {
    if (plantId == null) return null;
    final cutoff = DateTime.now().subtract(Duration(days: _rangeDays));
    return FirebaseFirestore.instance
        .collection('plants')
        .doc(plantId)
        .collection('readings')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoff))
        .orderBy('timestamp');
  }

  @override
  Widget build(BuildContext context) {
    final plantId = PlantScope.maybeOf(context)?.selectedPlantId;
    final query = _readingsQuery(plantId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History & Trends'),
        actions: [
          PopupMenuButton<int>(
            initialValue: _rangeDays,
            onSelected: (val) => setState(() => _rangeDays = val),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 7, child: Text('Last 7 days')),
              PopupMenuItem(value: 30, child: Text('Last 30 days')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: query == null
          ? const Center(child: Text('Select or create a plant first.'))
          : StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Could not load history: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No readings in this range yet.'));
                }

                final readings = docs.map((d) => d.data() as Map<String, dynamic>).toList();

                final moistureSpots = <FlSpot>[];
                final tempSpots = <FlSpot>[];
                final lightBars = <BarChartGroupData>[];
                for (var i = 0; i < readings.length; i++) {
                  moistureSpots.add(FlSpot(i.toDouble(), (readings[i]['soilMoisture'] ?? 0).toDouble()));
                  tempSpots.add(FlSpot(i.toDouble(), (readings[i]['temperature'] ?? 0).toDouble()));
                  lightBars.add(
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: (readings[i]['light'] ?? 0).toDouble(),
                          color: Colors.amber,
                          width: 8,
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('Soil Moisture (%)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    _LineChartCard(spots: moistureSpots, color: Colors.blue, minY: 0, maxY: 100),
                    const SizedBox(height: 24),
                    const Text('Temperature (°C)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    _LineChartCard(spots: tempSpots, color: Colors.orange, minY: 0, maxY: 50),
                    const SizedBox(height: 24),
                    const Text('Light (%) — bar chart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    _BarChartCard(groups: lightBars),
                    const SizedBox(height: 24),
                    _ReadingsTable(readings: readings),
                  ],
                );
              },
            ),
    );
  }
}

class _LineChartCard extends StatelessWidget {
  final List<FlSpot> spots;
  final Color color;
  final double minY;
  final double maxY;

  const _LineChartCard({required this.spots, required this.color, required this.minY, required this.maxY});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              gridData: const FlGridData(show: true),
              titlesData: const FlTitlesData(
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: color,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: color.withOpacity(0.15)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BarChartCard extends StatelessWidget {
  final List<BarChartGroupData> groups;
  const _BarChartCard({required this.groups});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: 100,
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: true),
              titlesData: const FlTitlesData(
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
              ),
              barGroups: groups,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReadingsTable extends StatelessWidget {
  final List<Map<String, dynamic>> readings;

  const _ReadingsTable({required this.readings});

  @override
  Widget build(BuildContext context) {
    final recent = readings.reversed.take(15).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Readings', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...recent.map((r) {
              final ts = r['timestamp'] as Timestamp?;
              final timeStr = ts != null ? DateFormat('MMM d, h:mm a').format(ts.toDate()) : '—';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '$timeStr — Soil: ${r['soilMoisture']}%, Temp: ${r['temperature']}°C, Hum: ${r['humidity']}%, Light: ${r['light']}%',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
