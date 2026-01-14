import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _busIdController = TextEditingController();
  final _routeIdController = TextEditingController();
  final _service = FlutterBackgroundService();

  bool _isLoggedIn = false;
  bool _tripActive = false;
  String? _tripId;
  String _status = 'Not logged in';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _busIdController.dispose();
    _routeIdController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _status = 'Signing in...');
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      setState(() {
        _isLoggedIn = true;
        _status = 'Logged in';
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _status = e.message ?? 'Login failed');
    }
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _status = 'Location services disabled');
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => _status = 'Location permission denied');
      return false;
    }
    return true;
  }

  Future<void> _startTrip() async {
    if (!_isLoggedIn) {
      setState(() => _status = 'Login required');
      return;
    }
    if (_busIdController.text.isEmpty || _routeIdController.text.isEmpty) {
      setState(() => _status = 'Enter bus & route ID');
      return;
    }
    final allowed = await _ensureLocationPermission();
    if (!allowed) return;

    _tripId = _uuid.v4();
    await _service.startService();
    _service.invoke('startTrip', {
      'busId': _busIdController.text.trim(),
      'routeId': _routeIdController.text.trim(),
      'tripId': _tripId,
    });

    setState(() {
      _tripActive = true;
      _status = 'Trip started';
    });
  }

  Future<void> _endTrip() async {
    _service.invoke('endTrip');
    setState(() {
      _tripActive = false;
      _status = 'Trip ended';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Mode')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_status, style: const TextStyle(color: Colors.blueGrey)),
            const SizedBox(height: 16),
            if (!_isLoggedIn) ...[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _login,
                child: const Text('Login'),
              ),
              const Divider(height: 32),
            ],
            TextField(
              controller: _busIdController,
              decoration: const InputDecoration(labelText: 'Bus ID'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _routeIdController,
              decoration: const InputDecoration(labelText: 'Route ID'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Trip'),
              onPressed: _tripActive ? null : _startTrip,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.stop),
              label: const Text('End Trip'),
              onPressed: _tripActive ? _endTrip : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _tripId == null ? 'No active trip' : 'Trip ID: $_tripId',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            const Text(
              'Keep this phone plugged in during routes. The app keeps a '
              'foreground service running to improve reliability on low-end '
              'Android phones.',
            ),
          ],
        ),
      ),
    );
  }
}
