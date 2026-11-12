import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../app_config.dart';
import '../plant_controller.dart';

/// FR-07 / FR-08: AI-Based Recommendation System + Watering Prediction.
class AiPredictionScreen extends StatefulWidget {
  const AiPredictionScreen({super.key});

  @override
  State<AiPredictionScreen> createState() => _AiPredictionScreenState();
}

class _AiPredictionScreenState extends State<AiPredictionScreen> {
  static const String functionsBaseUrl = kFunctionsBaseUrl;

  bool _isLoading = false;
  Map<String, dynamic>? _result;
  String? _error;
  String? _plantId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = PlantScope.maybeOf(context)?.selectedPlantId;
    if (id != _plantId) {
      _plantId = id;
      if (id != null) {
        _fetchPrediction();
      } else {
        setState(() {
          _isLoading = false;
          _result = null;
          _error = 'Select or create a plant first.';
        });
      }
    }
  }

  Future<void> _fetchPrediction() async {
    final plantId = _plantId;
    if (plantId == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http.get(
        Uri.parse('$functionsBaseUrl/getPrediction?plantId=$plantId'),
      );
      if (response.statusCode == 200) {
        setState(() => _result = jsonDecode(response.body));
      } else {
        setState(() => _error = 'Prediction service returned an error.');
      }
    } catch (e) {
      setState(() => _error = 'Could not reach prediction service: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plantId = PlantScope.maybeOf(context)?.selectedPlantId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Watering Prediction'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchPrediction),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : _buildResult(plantId),
    );
  }

  Widget _buildResult(String? plantId) {
    final available = _result?['available'] == true;
    if (!available) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _result?['message'] ?? 'Not enough history yet to make a prediction.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final prediction = _result?['prediction'];
    final message = _result?['message'] ?? '';
    final currentMoisture = _result?['currentMoisture'];

    String predictedText = 'No urgent prediction';
    if (prediction != null) {
      try {
        final dt = DateTime.parse(prediction);
        predictedText = DateFormat('MMM d, h:mm a').format(dt.toLocal());
      } catch (_) {
        predictedText = prediction.toString();
      }
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.psychology, size: 72, color: Colors.purple),
        const SizedBox(height: 16),
        if (currentMoisture != null)
          Text('Current soil moisture: ${currentMoisture.toStringAsFixed(0)}%',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 12),
        const Text('Predicted next watering time',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(predictedText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 24),
        if (plantId != null) _IdealRangeCard(plantId: plantId),
      ],
    );
  }
}

class _IdealRangeCard extends StatelessWidget {
  final String plantId;
  const _IdealRangeCard({required this.plantId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('plants').doc(plantId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        if (data == null) return const SizedBox.shrink();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Recommended safe ranges (FR-07)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Soil moisture: ${data['minMoisture'] ?? 30}% – ${data['maxMoisture'] ?? 70}%'),
                Text('Temperature: ${data['minTemp'] ?? 15}°C – ${data['maxTemp'] ?? 32}°C'),
                Text('Light: ${data['minLight'] ?? 20}% – ${data['maxLight'] ?? 90}%'),
              ],
            ),
          ),
        );
      },
    );
  }
}
