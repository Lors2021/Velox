import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final UserModel otherUser;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker = ImagePicker();
  bool _sending = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _textCtrl.clear();
    setState(() => _sending = true);
    final user = context.read<AuthProvider>().user!;
    await context.read<ChatProvider>().sendText(
          chatId: widget.chatId,
          senderId: user.uid,
          senderUsername: user.username,
          text: text,
        );
    if (mounted) setState(() => _sending = false);
    _scrollToBottom();
  }

  Future<void> _sendImage() async {
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (xFile == null || !mounted) return;
    setState(() => _sending = true);
    final user = context.read<AuthProvider>().user!;
    await context.read<ChatProvider>().sendImage(
          chatId: widget.chatId,
          senderId: user.uid,
          senderUsername: user.username,
          imageFile: File(xFile.path),
        );
    if (mounted) setState(() => _sending = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.read<AuthProvider>().user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            _SmallAvatar(
                url: widget.otherUser.avatarUrl,
                name: widget.otherUser.username),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.username,
                    style: const TextStyle(fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.otherUser.isOnline)
                    const Text(
                      'online',
                      style: TextStyle(
                          color: AppTheme.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.normal),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: context
                  .read<ChatProvider>()
                  .getChatMessages(widget.chatId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.accent));
                }
                final messages = snap.data ?? [];
                if (messages.isNotEmpty) _scrollToBottom();
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Say hello! 👋',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 15),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == currentUid;
                    final showDate = i == 0 ||
                        messages[i].timestamp.day !=
                            messages[i - 1].timestamp.day;
                    return Column(
                      children: [
                        if (showDate) _DateDivider(dt: msg.timestamp),
                        _MessageBubble(msg: msg, isMe: isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (_sending)
            const LinearProgressIndicator(
              color: AppTheme.accent,
              backgroundColor: AppTheme.border,
              minHeight: 2,
            ),
          _InputBar(
            controller: _textCtrl,
            onSend: _sendText,
            onImage: _sendImage,
            enabled: !_sending,
          ),
        ],
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  final DateTime dt;
  const _DateDivider({required this.dt});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      label = 'Today';
    } else if (dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day - 1) {
      label = 'Yesterday';
    } else {
      label = '${dt.day}.${dt.month}.${dt.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Text(label,
              style:
                  const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe;

  const _MessageBubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.accent : AppTheme.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe ? null : Border.all(color: AppTheme.border),
        ),
        child: msg.type == MessageType.image
            ? _ImageBubble(url: msg.content, isMe: isMe)
            : Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      msg.content,
                      style: TextStyle(
                        color: isMe ? Colors.black : AppTheme.textPrimary,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: isMe
                            ? Colors.black54
                            : AppTheme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ImageBubble extends StatelessWidget {
  final String url;
  final bool isMe;
  const _ImageBubble({required this.url, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _FullScreenImage(url: url),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          width: 220,
          placeholder: (_, __) => Container(
            width: 220,
            height: 160,
            color: AppTheme.border,
            child: const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.accent, strokeWidth: 2),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            width: 220,
            height: 100,
            color: AppTheme.border,
            child: const Icon(Icons.broken_image_outlined,
                color: AppTheme.textMuted),
          ),
        ),
      ),
    );
  }
}

class _FullScreenImage extends StatelessWidget {
  final String url;
  const _FullScreenImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(imageUrl: url),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onImage;
  final bool enabled;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onImage,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            8,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.image_outlined,
                color: AppTheme.textSecondary),
            onPressed: enabled ? onImage : null,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              style:
                  const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
              maxLines: 5,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Message...',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.card,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide:
                      const BorderSide(color: AppTheme.accent, width: 1.5),
                ),
              ),
              onSubmitted: enabled ? (_) => onSend() : null,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: enabled ? onSend : null,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: enabled ? AppTheme.accent : AppTheme.border,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  final String? url;
  final String name;
  const _SmallAvatar({this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
          radius: 17,
          backgroundImage: CachedNetworkImageProvider(url!));
    }
    return CircleAvatar(
      radius: 17,
      backgroundColor: AppTheme.card,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            color: AppTheme.accent,
            fontSize: 13,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}
