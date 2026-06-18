class AppConstants {
  static const String appName = 'VELOX';
  static const String mapUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String mapStoreKey = 'mapStore';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String ridesCollection = 'rides';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';

  // Storage paths
  static const String avatarStoragePath = 'avatars';
  static const String chatImagesPath = 'chat_images';
}
