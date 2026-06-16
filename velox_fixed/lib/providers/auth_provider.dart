import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

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
      notifyListeners();
    });
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

  Future<bool> updateAvatar(File imageFile) async {
    if (_user == null) return false;
    _setLoading(true);
    try {
      final url = await _storageService.uploadAvatar(
        uid: _user!.uid,
        imageFile: imageFile,
      );
      await _authService.updateProfile(uid: _user!.uid, avatarUrl: url);
      _user = _user!.copyWith(avatarUrl: url);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update avatar';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

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
