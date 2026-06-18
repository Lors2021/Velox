import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import 'chat_screen.dart';
import 'user_search_screen.dart';

class ChatsListScreen extends StatelessWidget {
  const ChatsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final uid = auth.user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('MESSAGES'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppTheme.textPrimary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserSearchScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<ChatModel>>(
        stream: context.read<ChatProvider>().getUserChats(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.accent));
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppTheme.textMuted, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Error loading chats\n${snap.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            );
          }
          final chats = snap.data ?? [];
          if (chats.isEmpty) {
            return _emptyState(context);
          }
          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 70),
            itemBuilder: (_, i) {
              final chat = chats[i];
              final otherUid =
                  chat.participantIds.firstWhere((id) => id != uid,
                      orElse: () => '');
              final otherName =
                  chat.participantNames[otherUid] ?? 'Unknown';
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: _LetterAvatar(name: otherName),
                title: Text(
                  otherName,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  chat.lastMessage.isEmpty ? 'No messages yet' : chat.lastMessage,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  timeago.format(chat.lastMessageTime, locale: 'en_short'),
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
                onTap: () {
                  final otherUser = UserModel(
                    uid: otherUid,
                    email: '',
                    username: otherName,
                    createdAt: DateTime.now(),
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: chat.id,
                        otherUser: otherUser,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.black,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserSearchScreen()),
        ),
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded,
              size: 64, color: AppTheme.textMuted),
          const SizedBox(height: 16),
          const Text(
            'No chats yet',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserSearchScreen()),
            ),
            child: const Text(
              'Find cyclists',
              style: TextStyle(color: AppTheme.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _LetterAvatar extends StatelessWidget {
  final String name;
  const _LetterAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppTheme.card,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppTheme.accent,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }
}
