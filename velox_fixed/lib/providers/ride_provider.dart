import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/ride_model.dart';
import '../services/ride_service.dart';

enum RideStatus { idle, active, paused, finished }

class RideProvider extends ChangeNotifier {
  final RideService _rideService = RideService();

  RideStatus _status = RideStatus.idle;
  List<LatLng> _track = [];
  double _distanceMeters = 0;
  double _currentSpeedMs = 0;
  double _maxSpeedMs = 0;
  double _totalSpeedSum = 0;
  int _speedReadings = 0;
  DateTime? _startTime;
  DateTime? _pauseTime;
  Duration _pausedDuration = Duration.zero;
  Duration _elapsed = Duration.zero;
  LatLng? _currentPosition;
  List<RideModel> _rideHistory = [];
  bool _isLoadingHistory = false;

  StreamSubscription<Position>? _positionSub;
  Timer? _elapsedTimer;

  // Getters
  RideStatus get status => _status;
  List<LatLng> get track => List.unmodifiable(_track);
  double get distanceMeters => _distanceMeters;
  double get currentSpeedKmh => _currentSpeedMs * 3.6;
  double get avgSpeedKmh =>
      _speedReadings > 0 ? (_totalSpeedSum / _speedReadings) * 3.6 : 0;
  double get maxSpeedKmh => _maxSpeedMs * 3.6;
  Duration get elapsed => _elapsed;
  LatLng? get currentPosition => _currentPosition;
  List<RideModel> get rideHistory => List.unmodifiable(_rideHistory);
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isRiding => _status == RideStatus.active;

  Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<LatLng?> getCurrentLocation() async {
    final granted = await requestLocationPermission();
    if (!granted) return null;

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _currentPosition = LatLng(pos.latitude, pos.longitude);
      notifyListeners();
      return _currentPosition;
    } catch (_) {
      return null;
    }
  }

  void startRide() {
    _status = RideStatus.active;
    _track = [];
    _distanceMeters = 0;
    _currentSpeedMs = 0;
    _maxSpeedMs = 0;
    _totalSpeedSum = 0;
    _speedReadings = 0;
    _startTime = DateTime.now();
    _pausedDuration = Duration.zero;
    _elapsed = Duration.zero;

    _startPositionStream();
    _startElapsedTimer();
    notifyListeners();
  }

  void pauseRide() {
    if (_status != RideStatus.active) return;
    _status = RideStatus.paused;
    _pauseTime = DateTime.now();
    _currentSpeedMs = 0;
    _positionSub?.pause();
    _elapsedTimer?.cancel();
    notifyListeners();
  }

  void resumeRide() {
    if (_status != RideStatus.paused) return;
    _status = RideStatus.active;
    if (_pauseTime != null) {
      _pausedDuration += DateTime.now().difference(_pauseTime!);
      _pauseTime = null;
    }
    _positionSub?.resume();
    _startElapsedTimer();
    notifyListeners();
  }

  Future<RideModel?> finishRide(String userId) async {
    if (_status == RideStatus.idle) return null;
    _status = RideStatus.finished;
    _positionSub?.cancel();
    _positionSub = null;
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    _currentSpeedMs = 0;

    final ride = RideModel(
      id: '',
      userId: userId,
      startTime: _startTime ?? DateTime.now(),
      endTime: DateTime.now(),
      duration: _elapsed,
      distanceMeters: _distanceMeters,
      avgSpeedMs: _speedReadings > 0 ? _totalSpeedSum / _speedReadings : 0,
      maxSpeedMs: _maxSpeedMs,
      trackPoints: List.from(_track),
    );

    notifyListeners();
    return ride;
  }

  Future<void> saveRide(RideModel ride) async {
    final saved = await _rideService.saveRide(ride);
    _rideHistory.insert(0, saved);
    notifyListeners();
  }

  void resetRide() {
    _status = RideStatus.idle;
    _track = [];
    _distanceMeters = 0;
    _currentSpeedMs = 0;
    _maxSpeedMs = 0;
    _totalSpeedSum = 0;
    _speedReadings = 0;
    _elapsed = Duration.zero;
    notifyListeners();
  }

  Future<void> loadRideHistory(String userId) async {
    _isLoadingHistory = true;
    notifyListeners();
    try {
      _rideHistory = await _rideService.getUserRides(userId);
    } catch (e) {
      debugPrint('loadRideHistory error: $e');
    }
    _isLoadingHistory = false;
    notifyListeners();
  }

  void _startPositionStream() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionSub =
        Geolocator.getPositionStream(locationSettings: settings).listen(
      (pos) {
        if (_status != RideStatus.active) return;

        final newPoint = LatLng(pos.latitude, pos.longitude);

        // FIX: correct Distance API usage — call instance method, not constructor
        if (_track.isNotEmpty) {
          final dist = const Distance().as(
            LengthUnit.Meter,
            _track.last,
            newPoint,
          );
          _distanceMeters += dist;
        }

        _track.add(newPoint);
        _currentPosition = newPoint;

        // FIX: GPS speed can be negative on some devices; clamp to 0
        final speed = (pos.speed > 0) ? pos.speed : 0.0;
        _currentSpeedMs = speed;

        // Only count speed readings when actually moving (> 0.5 m/s)
        if (speed > 0.5) {
          _totalSpeedSum += speed;
          _speedReadings++;
        }
        if (speed > _maxSpeedMs) _maxSpeedMs = speed;

        notifyListeners();
      },
      onError: (e) => debugPrint('Position stream error: $e'),
    );
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime != null && _status == RideStatus.active) {
        _elapsed = DateTime.now().difference(_startTime!) - _pausedDuration;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }
}
