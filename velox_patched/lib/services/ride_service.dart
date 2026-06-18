import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ride_model.dart';
import '../utils/constants.dart';

class RideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Saves ride and returns it with assigned Firestore id
  Future<RideModel> saveRide(RideModel ride) async {
    final docRef = await _firestore
        .collection(AppConstants.ridesCollection)
        .add(ride.toMap());
    return RideModel(
      id: docRef.id,
      userId: ride.userId,
      startTime: ride.startTime,
      endTime: ride.endTime,
      duration: ride.duration,
      distanceMeters: ride.distanceMeters,
      avgSpeedMs: ride.avgSpeedMs,
      maxSpeedMs: ride.maxSpeedMs,
      trackPoints: ride.trackPoints,
    );
  }

  Future<List<RideModel>> getUserRides(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.ridesCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RideModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      // Index not ready yet — fallback without ordering
      final snapshot = await _firestore
          .collection(AppConstants.ridesCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final rides = snapshot.docs
          .map((doc) => RideModel.fromMap(doc.data(), doc.id))
          .toList();
      rides.sort((a, b) => b.startTime.compareTo(a.startTime));
      return rides;
    }
  }

  Future<void> deleteRide(String rideId) async {
    await _firestore
        .collection(AppConstants.ridesCollection)
        .doc(rideId)
        .delete();
  }
}
