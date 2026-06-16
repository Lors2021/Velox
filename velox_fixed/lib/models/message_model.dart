import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image }

class MessageModel {
  final String id;
  final String senderId;
  final String senderUsername;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.senderUsername,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] as String? ?? '',
      senderUsername: map['senderUsername'] as String? ?? '',
      content: map['content'] as String? ?? '',
      type: map['type'] == 'image' ? MessageType.image : MessageType.text,
      // FIX: serverTimestamp() can be null briefly on local write
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderUsername': senderUsername,
      'content': content,
      'type': type == MessageType.image ? 'image' : 'text',
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }
}

class ChatModel {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String?> participantAvatars;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  const ChatModel({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    required this.participantAvatars,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory ChatModel.fromMap(Map<String, dynamic> map, String id) {
    // FIX: participantAvatars values can be null — handle properly
    final rawAvatars = map['participantAvatars'] as Map<String, dynamic>? ?? {};
    final avatars = rawAvatars.map(
      (k, v) => MapEntry(k, v as String?),
    );
    return ChatModel(
      id: id,
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantNames:
          Map<String, String>.from(map['participantNames'] ?? {}),
      participantAvatars: avatars,
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageTime: map['lastMessageTime'] != null
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : DateTime.now(),
      unreadCount: (map['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantAvatars': participantAvatars,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
    };
  }
}
