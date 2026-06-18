import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  List<UserModel> _searchResults = [];
  bool _isSearching = false;
  String? _error;

  List<UserModel> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String? get error => _error;

  Stream<List<ChatModel>> getUserChats(String uid) =>
      _chatService.getUserChats(uid);

  Stream<List<MessageModel>> getChatMessages(String chatId) =>
      _chatService.getChatMessages(chatId);

  Future<ChatModel?> openChat({
    required UserModel currentUser,
    required UserModel otherUser,
  }) async {
    try {
      return await _chatService.getOrCreateChat(
        currentUid: currentUser.uid,
        currentUsername: currentUser.username,
        otherUid: otherUser.uid,
        otherUsername: otherUser.username,
      );
    } catch (e) {
      _error = 'Could not open chat';
      notifyListeners();
      return null;
    }
  }

  Future<void> sendText({
    required String chatId,
    required String senderId,
    required String senderUsername,
    required String text,
  }) async {
    try {
      await _chatService.sendTextMessage(
        chatId: chatId,
        senderId: senderId,
        senderUsername: senderUsername,
        text: text,
      );
    } catch (e) {
      _error = 'Failed to send message';
      notifyListeners();
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _isSearching = true;
    notifyListeners();
    try {
      _searchResults = await _authService.searchUsers(query.trim());
    } catch (_) {
      _searchResults = [];
    }
    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }
}
