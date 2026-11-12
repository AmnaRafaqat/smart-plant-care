import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const int kMaxPlantsPerUser = 10;

Map<String, dynamic> defaultPlantFields(String ownerId, {String name = 'My Plant'}) {
  return {
    'name': name,
    'type': '',
    'minMoisture': 30,
    'maxMoisture': 70,
    'minTemp': 15,
    'maxTemp': 32,
    'minLight': 20,
    'maxLight': 90,
    'pumpEnabled': false,
    'pumpOn': false,
    'pumpCommand': false,
    'ownerId': ownerId,
  };
}

class PlantController extends ChangeNotifier {
  PlantController(this.uid);

  final String uid;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> plants = [];
  String? selectedPlantId;
  bool loading = true;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  CollectionReference<Map<String, dynamic>> get _plants =>
      FirebaseFirestore.instance.collection('plants');

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  String? get selectedPlantName {
    for (final doc in plants) {
      if (doc.id == selectedPlantId) {
        return (doc.data()['name'] as String?)?.trim().isNotEmpty == true
            ? doc.data()['name'] as String
            : doc.id;
      }
    }
    return null;
  }

  Future<void> start() async {
    final userSnap = await _userDoc.get();
    selectedPlantId = userSnap.data()?['selectedPlantId'] as String?;

    _sub = _plants.where('ownerId', isEqualTo: uid).snapshots().listen((snap) async {
      plants = snap.docs;
      loading = false;
      if (plants.isEmpty) {
        selectedPlantId = null;
      } else if (selectedPlantId == null ||
          !plants.any((p) => p.id == selectedPlantId)) {
        selectedPlantId = plants.first.id;
        await _persistSelection();
      }
      notifyListeners();
    }, onError: (_) {
      loading = false;
      notifyListeners();
    });
  }

  Future<void> selectPlant(String plantId) async {
    selectedPlantId = plantId;
    notifyListeners();
    await _persistSelection();
  }

  Future<void> _persistSelection() async {
    if (selectedPlantId == null) return;
    try {
      await _userDoc.set({'selectedPlantId': selectedPlantId}, SetOptions(merge: true));
    } catch (_) {
      // Offline or rules: selection still works in-memory.
    }
  }

  Future<String> createPlant({String name = 'My Plant'}) async {
    if (plants.length >= kMaxPlantsPerUser) {
      throw StateError('Maximum of $kMaxPlantsPerUser plants per user.');
    }
    final data = defaultPlantFields(uid, name: name);

    // Keep ESP32 demo compatibility: first plant can use plant1 if unused.
    if (plants.isEmpty) {
      final legacy = _plants.doc('plant1');
      final legacySnap = await legacy.get();
      if (!legacySnap.exists) {
        await legacy.set(data);
        await selectPlant('plant1');
        return 'plant1';
      }
    }

    final ref = await _plants.add(data);
    await selectPlant(ref.id);
    return ref.id;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

class PlantScope extends InheritedNotifier<PlantController> {
  const PlantScope({
    super.key,
    required PlantController controller,
    required super.child,
  }) : super(notifier: controller);

  static PlantController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PlantScope>()?.notifier;
  }

  static PlantController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'PlantScope not found');
    return controller!;
  }
}

class AuthPlantBinder extends StatefulWidget {
  const AuthPlantBinder({super.key, required this.child});

  final Widget child;

  @override
  State<AuthPlantBinder> createState() => _AuthPlantBinderState();
}

class _AuthPlantBinderState extends State<AuthPlantBinder> {
  StreamSubscription<User?>? _authSub;
  PlantController? _controller;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      _controller?.dispose();
      if (user == null) {
        setState(() => _controller = null);
        return;
      }
      final next = PlantController(user.uid);
      setState(() => _controller = next);
      next.start();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return widget.child;
    return PlantScope(controller: controller, child: widget.child);
  }
}
