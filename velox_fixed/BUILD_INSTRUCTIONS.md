# Velox — Build Instructions

## Requirements
- Flutter 3.22+ (stable channel)
- Android Studio or VS Code
- Android SDK 35 (API 34+ target)
- Java 17 (set JAVA_HOME)
- Physical device or emulator with Google Play Services (for FCM)

## Setup

### 1. Download SpaceMono font
https://fonts.google.com/specimen/Space+Mono

Place files:
```
assets/fonts/SpaceMono-Regular.ttf
assets/fonts/SpaceMono-Bold.ttf
```

Alternatively, remove the `fonts:` block from `pubspec.yaml` to use the system font.

### 2. google-services.json
Already placed at:
```
android/app/google-services.json
```

### 3. Firebase Console — enable services
- Authentication → Email/Password ✓
- Firestore Database → Create (test mode) ✓
- Storage → Create (test mode) ✓
- Messaging → automatic ✓

### 4. Firestore indexes (create manually or via link in logs)
```
Collection: rides
  userId ASC + startTime DESC

Collection: chats
  participantIds ARRAY_CONTAINS + lastMessageTime DESC
```

### 5. Firestore security rules (production)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == uid;
    }
    match /rides/{rideId} {
      allow read, write: if request.auth.uid == resource.data.userId;
      allow create: if request.auth != null;
    }
    match /chats/{chatId} {
      allow read, write: if request.auth.uid in resource.data.participantIds;
      allow create: if request.auth != null;
      match /messages/{msgId} {
        allow read, write: if request.auth != null;
      }
    }
  }
}
```

### 6. Storage rules (production)
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /avatars/{uid}.jpg {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == uid;
    }
    match /chat_images/{chatId}/{imageId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Run & Build

```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Build debug APK
flutter build apk --debug

# Build release APK (unsigned)
flutter build apk --release

# APK location after build:
# build/app/outputs/flutter-apk/app-release.apk
```

## Troubleshooting

**"Gradle build failed"**
→ Make sure Java 17 is active: `java -version`
→ Run: `flutter clean && flutter pub get`

**"No Firebase App"**
→ Check google-services.json is in android/app/

**"Permission denied" on GPS**
→ Test on real device, not emulator

**"Index not found" in Firestore**
→ Open the link from the error log, click Create Index
