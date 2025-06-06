import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

class CompassScreen extends StatefulWidget {
  final String userName;
  final double targetLatitude;
  final double targetLongitude;

  const CompassScreen({
    super.key,
    required this.userName,
    required this.targetLatitude,
    required this.targetLongitude,
  });

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  double? _direction;
  Position? _currentPosition;
  double? _distance;
  double? _bearing;
  StreamSubscription<CompassEvent>? _compassSubscription;
  String? _targetAddress;
  bool _isLoadingAddress = true;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCompass();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeCompass() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error =
              'Location services are disabled. Please enable location services.';
          _isLoading = false;
        });
        return;
      }

      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error =
                'Location permission denied. Please grant location permission to use the compass.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error =
              'Location permissions are permanently denied. Please enable them in your device settings.';
          _isLoading = false;
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      setState(() => _currentPosition = position);

      // Start compass updates
      _compassSubscription = FlutterCompass.events?.listen((event) {
        if (!mounted) return;
        setState(() {
          _direction = event.heading;
          _updateDistanceAndBearing();
          _isLoading = false;
        });
      });

      // Get target address
      _getTargetAddress();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error initializing compass: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _getTargetAddress() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        widget.targetLatitude,
        widget.targetLongitude,
      );

      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _targetAddress = [
            if (place.street?.isNotEmpty == true) place.street,
            if (place.subLocality?.isNotEmpty == true) place.subLocality,
            if (place.locality?.isNotEmpty == true) place.locality,
            if (place.subAdministrativeArea?.isNotEmpty == true)
              place.subAdministrativeArea,
          ].where((e) => e != null).join(', ');
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _targetAddress = 'Address not found';
        _isLoadingAddress = false;
      });
    }
  }

  void _updateDistanceAndBearing() {
    if (_currentPosition == null) return;

    // Calculate distance
    _distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      widget.targetLatitude,
      widget.targetLongitude,
    );

    // Calculate bearing
    final lat1 = _currentPosition!.latitude * math.pi / 180;
    final lon1 = _currentPosition!.longitude * math.pi / 180;
    final lat2 = widget.targetLatitude * math.pi / 180;
    final lon2 = widget.targetLongitude * math.pi / 180;

    final dLon = lon2 - lon1;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final bearing = math.atan2(y, x);
    _bearing = (bearing * 180 / math.pi + 360) % 360;
  }

  Future<void> _retryInitialization() async {
    setState(() {
      _error = null;
      _isLoading = true;
    });
    await _initializeCompass();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Compass to ${widget.userName}'),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_off,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _retryInitialization,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.blue.withOpacity(0.2),
                        Colors.white,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_direction != null && _bearing != null)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Transform.rotate(
                              angle: ((_direction! - _bearing!) *
                                  (math.pi / 180) *
                                  -1),
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 180,
                                      height: 180,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.blue, width: 2),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const Align(
                                      alignment: Alignment.topCenter,
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 20),
                                        child: Icon(
                                          Icons.arrow_upward,
                                          color: Colors.red,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                    ...List.generate(4, (index) {
                                      final angle = index * 90.0;
                                      final label = ['N', 'E', 'S', 'W'][index];
                                      return Transform.rotate(
                                        angle: angle * (math.pi / 180),
                                        child: Align(
                                          alignment: Alignment.topCenter,
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.only(top: 5),
                                            child: Text(
                                              label,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          const CircularProgressIndicator(),
                        const SizedBox(height: 32),
                        Card(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        color: Colors.red),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.userName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (_isLoadingAddress)
                                            const Padding(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 4),
                                              child: SizedBox(
                                                height: 14,
                                                width: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            )
                                          else
                                            Text(
                                              _targetAddress ??
                                                  'Address not found',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                if (_distance != null)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.directions_walk,
                                          color: Colors.blue),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Distance: ${(_distance! / 1000).toStringAsFixed(2)} km',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (_direction != null) ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.explore,
                                          color: Colors.blue),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Heading: ${_direction!.toStringAsFixed(1)}°',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ],
                                if (_bearing != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.navigation,
                                          color: Colors.blue),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Target bearing: ${_bearing!.toStringAsFixed(1)}°',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _retryInitialization,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
