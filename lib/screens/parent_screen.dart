import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class ParentScreen extends StatefulWidget {
  const ParentScreen({super.key});

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  final _busIdController = TextEditingController();
  GoogleMapController? _mapController;
  StreamSubscription<DatabaseEvent>? _liveSub;

  bool _isSignedIn = false;
  Map<String, dynamic>? _liveData;
  String _status = 'Not signed in';

  @override
  void dispose() {
    _busIdController.dispose();
    _liveSub?.cancel();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _status = 'Signing in...');
    await FirebaseAuth.instance.signInAnonymously();
    setState(() {
      _isSignedIn = true;
      _status = 'Signed in';
    });
  }

  Future<void> _startListening() async {
    if (!_isSignedIn) {
      setState(() => _status = 'Sign in first');
      return;
    }
    if (_busIdController.text.trim().isEmpty) {
      setState(() => _status = 'Enter a bus ID');
      return;
    }
    await _liveSub?.cancel();
    final busId = _busIdController.text.trim();
    final ref = FirebaseDatabase.instance.ref('buses/$busId/live');
    _liveSub = ref.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        setState(() {
          _liveData = Map<String, dynamic>.from(data);
          _status = 'Live';
        });
        final lat = (_liveData?['lat'] as num?)?.toDouble();
        final lng = (_liveData?['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(LatLng(lat, lng)),
          );
        }
      } else {
        setState(() => _status = 'No live data yet');
      }
    });
  }

  String _formatUpdatedAt() {
    final raw = _liveData?['updatedAt'];
    if (raw is int) {
      final dt = DateTime.fromMillisecondsSinceEpoch(raw);
      return DateFormat('hh:mm a, dd MMM').format(dt);
    }
    return 'Unknown';
  }

  bool _isStale() {
    final raw = _liveData?['updatedAt'];
    if (raw is int) {
      final updated = DateTime.fromMillisecondsSinceEpoch(raw);
      return DateTime.now().difference(updated).inMinutes > 2;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final lat = (_liveData?['lat'] as num?)?.toDouble();
    final lng = (_liveData?['lng'] as num?)?.toDouble();
    final isActive = _liveData?['isActive'] == true;
    final marker = lat != null && lng != null
        ? {
            Marker(
              markerId: const MarkerId('bus'),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(title: isActive ? 'Bus Active' : 'Inactive'),
            ),
          }
        : <Marker>{};

    return Scaffold(
      appBar: AppBar(title: const Text('Parent Mode')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_status, style: const TextStyle(color: Colors.blueGrey)),
                const SizedBox(height: 8),
                if (!_isSignedIn)
                  ElevatedButton(
                    onPressed: _signIn,
                    child: const Text('Sign in anonymously'),
                  ),
                const SizedBox(height: 8),
                TextField(
                  controller: _busIdController,
                  decoration: const InputDecoration(labelText: 'Bus ID'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _startListening,
                  child: const Text('Track Bus'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(
                      label: Text(isActive ? 'Active' : 'Inactive'),
                      backgroundColor:
                          isActive ? Colors.green.shade100 : Colors.grey.shade200,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Last updated: ${_formatUpdatedAt()}',
                      style: TextStyle(
                        color: _isStale() ? Colors.red : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(19.0760, 72.8777),
                zoom: 12,
              ),
              markers: marker,
              myLocationButtonEnabled: false,
              onMapCreated: (controller) => _mapController = controller,
            ),
          ),
        ],
      ),
    );
  }
}
