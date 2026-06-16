import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import 'chat_screen.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openChat(UserModel otherUser) async {
    final currentUser = context.read<AuthProvider>().user!;
    final chatProvider = context.read<ChatProvider>();
    final chat = await chatProvider.openChat(
      currentUser: currentUser,
      otherUser: otherUser,
    );
    if (!mounted || chat == null) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(chatId: chat.id, otherUser: otherUser),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Search username...',
            hintStyle: TextStyle(color: AppTheme.textMuted),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          onChanged: (q) => chatProvider.searchUsers(q),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            chatProvider.clearSearch();
            Navigator.pop(context);
          },
        ),
      ),
      body: chatProvider.isSearching
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : chatProvider.searchResults.isEmpty
              ? const Center(
                  child: Text(
                    'Search for cyclists by username',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                )
              : ListView.separated(
                  itemCount: chatProvider.searchResults.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 70),
                  itemBuilder: (_, i) {
                    final user = chatProvider.searchResults[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: _buildAvatar(user),
                      title: Text(
                        user.username,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        user.email,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () => _openChat(user),
                    );
                  },
                ),
    );
  }

  Widget _buildAvatar(UserModel user) {
    if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: CachedNetworkImageProvider(user.avatarUrl!),
      );
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppTheme.card,
      child: Text(
        user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
        style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700),
      ),
    );
  }
}
