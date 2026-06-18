import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  bool _initialized = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get initialized => _initialized;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser != null) {
        _user = await _authService.getUserById(firebaseUser.uid);
      } else {
        _user = null;
      }
      _initialized = true;
      notifyListeners();
    });
  }

  /// Waits until Firebase has resolved the auth state (first event received)
  Future<void> waitForInit() async {
    if (_initialized) return;
    // Poll until initialized (Firebase auth state fires quickly)
    while (!_initialized) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String username,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      _user = await _authService.register(
        email: email,
        password: password,
        username: username,
      );
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapFirebaseError(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Registration failed';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      _user = await _authService.login(email: email, password: password);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapFirebaseError(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Login failed';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    final uid = _user?.uid;
    if (uid != null) {
      await _authService.logout(uid);
    }
    _user = null;
    notifyListeners();
  }

  Future<bool> updateUsername(String username) async {
    if (_user == null) return false;
    _setLoading(true);
    try {
      await _authService.updateProfile(uid: _user!.uid, username: username);
      _user = _user!.copyWith(username: username);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Avatar update removed — avatars are now letter-based only

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email already in use';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak (min 6 chars)';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'too-many-requests':
        return 'Too many attempts. Try later';
      case 'network-request-failed':
        return 'No internet connection';
      default:
        return 'Authentication error ($code)';
    }
  }
}
