import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserModel?> register({
    required String email,
    required String password,
    required String username,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    String? token;
    try {
      token = await FirebaseMessaging.instance.getToken();
    } catch (_) {}

    final user = UserModel(
      uid: uid,
      email: email,
      username: username,
      fcmToken: token,
      createdAt: DateTime.now(),
      isOnline: true,
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(user.toMap());

    return user;
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;
    String? token;
    try {
      token = await FirebaseMessaging.instance.getToken();
    } catch (_) {}

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'fcmToken': token,
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    });

    return await getUserById(uid);
  }

  Future<void> logout(String uid) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'isOnline': false,
      'lastSeen': FieldValue.serverTimestamp(),
    });
    await _auth.signOut();
  }

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();

    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, uid);
  }

  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .where((u) => u.uid != currentUser?.uid)
        .toList();
  }

  Future<void> updateProfile({
    required String uid,
    String? username,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (username != null) updates['username'] = username;
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
    if (updates.isEmpty) return;
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update(updates);
  }
}
