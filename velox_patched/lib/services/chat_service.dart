import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../utils/constants.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String getChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<ChatModel?> getOrCreateChat({
    required String currentUid,
    required String currentUsername,
    required String otherUid,
    required String otherUsername,
  }) async {
    final chatId = getChatId(currentUid, otherUid);
    final docRef =
        _firestore.collection(AppConstants.chatsCollection).doc(chatId);
    final doc = await docRef.get();

    if (!doc.exists) {
      final now = DateTime.now();
      await docRef.set({
        'participantIds': [currentUid, otherUid],
        'participantNames': {
          currentUid: currentUsername,
          otherUid: otherUsername,
        },
        'lastMessage': '',
        // Use actual DateTime so the doc is immediately readable locally
        'lastMessageTime': Timestamp.fromDate(now),
        'unreadCount': 0,
      });
      final newDoc = await docRef.get();
      return ChatModel.fromMap(newDoc.data()!, chatId);
    }

    return ChatModel.fromMap(doc.data()!, doc.id);
  }

  Stream<List<ChatModel>> getUserChats(String uid) {
    return _firestore
        .collection(AppConstants.chatsCollection)
        .where('participantIds', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChatModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<MessageModel>> getChatMessages(String chatId) {
    return _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MessageModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> sendTextMessage({
    required String chatId,
    required String senderId,
    required String senderUsername,
    required String text,
  }) async {
    final batch = _firestore.batch();
    final msgRef = _firestore
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .doc();
    final chatRef =
        _firestore.collection(AppConstants.chatsCollection).doc(chatId);

    batch.set(msgRef, {
      'senderId': senderId,
      'senderUsername': senderUsername,
      'content': text,
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    batch.update(chatRef, {
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
