import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ride_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _usernameCtrl = TextEditingController();
  bool _editingUsername = false;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final xFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xFile == null || !mounted) return;

    final ok =
        await context.read<AuthProvider>().updateAvatar(File(xFile.path));
    if (mounted && !ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update avatar')),
      );
    }
  }

  Future<void> _saveUsername() async {
    final newName = _usernameCtrl.text.trim();
    if (newName.isEmpty) return;
    final ok = await context.read<AuthProvider>().updateUsername(newName);
    if (mounted) {
      setState(() => _editingUsername = false);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update username')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Sign out?',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('You will be signed out of Velox.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out',
                style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final rides = context.watch<RideProvider>().rideHistory;
    final user = auth.user;
    if (user == null) return const SizedBox();

    final totalDist = rides.fold<double>(0, (s, r) => s + r.distanceMeters);
    final totalTime =
        rides.fold<Duration>(Duration.zero, (s, r) => s + r.duration);
    final avgSpeedKmh = rides.isEmpty
        ? 0.0
        : rides.fold<double>(0, (s, r) => s + r.avgSpeedMs) /
            rides.length *
            3.6;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('PROFILE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 32),

            // Avatar
            GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  auth.isLoading
                      ? const CircleAvatar(
                          radius: 54,
                          backgroundColor: AppTheme.card,
                          child: CircularProgressIndicator(
                              color: AppTheme.accent, strokeWidth: 2),
                        )
                      : (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                          ? CircleAvatar(
                              radius: 54,
                              backgroundImage:
                                  CachedNetworkImageProvider(user.avatarUrl!),
                            )
                          : CircleAvatar(
                              radius: 54,
                              backgroundColor: AppTheme.card,
                              child: Text(
                                user.username.isNotEmpty
                                    ? user.username[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppTheme.accent,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.black, size: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Online indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('online',
                    style: TextStyle(
                        color: AppTheme.accent,
                        fontSize: 12,
                        letterSpacing: 0.5)),
              ],
            ),

            const SizedBox(height: 12),

            // Username
            if (_editingUsername)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _usernameCtrl,
                        autofocus: true,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                            hintText: 'New username'),
                        onSubmitted: (_) => _saveUsername(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_rounded,
                          color: AppTheme.accent),
                      onPressed: _saveUsername,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppTheme.textSecondary),
                      onPressed: () =>
                          setState(() => _editingUsername = false),
                    ),
                  ],
                ),
              )
            else
              GestureDetector(
                onTap: () {
                  _usernameCtrl.text = user.username;
                  setState(() => _editingUsername = true);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.username,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.edit_outlined,
                        color: AppTheme.textMuted, size: 17),
                  ],
                ),
              ),

            const SizedBox(height: 6),
            Text(user.email,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13)),

            const SizedBox(height: 32),

            // Stats card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LIFETIME STATS',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat('${rides.length}', 'RIDES'),
                      _vDivider(),
                      _stat(Formatters.formatDistance(totalDist), 'TOTAL'),
                      _vDivider(),
                      _stat(Formatters.formatDuration(totalTime), 'TIME'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppTheme.border),
                  const SizedBox(height: 16),
                  Center(
                    child: _stat(
                      '${avgSpeedKmh.toStringAsFixed(1)} km/h',
                      'AVG SPEED',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            )),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              letterSpacing: 1.5,
            )),
      ],
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 36, color: AppTheme.border);
}
