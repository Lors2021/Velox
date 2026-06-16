# Firebase Setup — Velox

## 1. Создай проект в Firebase Console

1. Открой https://console.firebase.google.com
2. Нажми **Add project** → введи имя `Velox`
3. Google Analytics — можно отключить
4. Нажми **Create project**

---

## 2. Добавь Android приложение

1. На главной странице проекта нажми **Android** иконку
2. Заполни:
   - **Android package name:** `com.velox.velox`
   - **App nickname:** Velox
3. Нажми **Register app**
4. Скачай файл **google-services.json**

---

## 3. Куда положить google-services.json

```
velox/
  android/
    app/
      google-services.json   ← СЮДА
      build.gradle
      src/
```

**Важно:** файл должен быть именно в папке `android/app/`, НЕ в корне проекта.

---

## 4. Включи сервисы Firebase

### Authentication
1. Firebase Console → **Authentication** → **Get started**
2. Вкладка **Sign-in method** → включи **Email/Password**

### Firestore Database
1. Firebase Console → **Firestore Database** → **Create database**
2. Выбери **Start in test mode** (для разработки)
3. Выбери регион — например `eur3 (europe-west)`

**Правила Firestore (потом настрой по-нормальному):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Firebase Storage
1. Firebase Console → **Storage** → **Get started**
2. Выбери **Start in test mode**

**Правила Storage:**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Firebase Messaging (FCM)
Работает автоматически после добавления `google-services.json`.
Никакой дополнительной настройки не нужно для базовых уведомлений.

---

## 5. Индексы Firestore

Некоторые запросы требуют составных индексов. Firebase сам предложит создать их при первом запросе — просто нажми на ссылку в логах.

Основные индексы которые понадобятся:
- Коллекция `rides`: поля `userId` (ASC) + `startTime` (DESC)
- Коллекция `chats`: поле `participantIds` (array-contains) + `lastMessageTime` (DESC)

---

## 6. Запуск проекта

```bash
# Установи зависимости
flutter pub get

# Запусти на подключённом Android устройстве/эмуляторе
flutter run
```

**Требования:**
- Flutter stable (3.x+)
- Android SDK API 21+
- google-services.json в `android/app/`
- Реальное устройство или эмулятор с Google Play Services (для FCM)

---

## 7. Структура шрифтов

Добавь шрифты SpaceMono (или замени на любые другие):

```
velox/
  assets/
    fonts/
      SpaceMono-Regular.ttf
      SpaceMono-Bold.ttf
    images/
      (placeholder)
```

Скачать SpaceMono: https://fonts.google.com/specimen/Space+Mono

Или измени `fontFamily` в `lib/utils/app_theme.dart` на `null` чтобы использовать системный шрифт.
