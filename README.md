# Amora - Modern Dating App 💕

A beautiful, modern dating app built with Flutter featuring Tinder-style swiping, real-time chat, and glassmorphism design.

## ✨ Features

- **Modern UI/UX**: Glassmorphism design with smooth animations
- **Tinder-style Swiping**: Card-based profile discovery
- **Real-time Chat**: Instant messaging with matches
- **Photo Management**: Upload photos via Telegram Bot API
- **Location-based Matching**: Find people nearby
- **Profile Customization**: Rich profiles with interests and bio
- **Match System**: Smart matching algorithm
- **Cross-platform**: iOS, Android, and Web support

## 🎨 Design System

### Color Palette
- **Primary**: Sunset Rose (#E91E63) to Deep Lavender (#9C27B0)
- **Secondary**: Warm Gold (#FFB300)
- **Accent**: Sunset Orange (#FF6B35)
- **Background**: Off-white (#F9F9F9) with gradients
- **Dark Mode**: Deep Midnight (#1A1A2E)

### Design Elements
- **Glassmorphism**: Transparent cards with blur effects
- **Rounded Corners**: 24-30px border radius
- **Soft Shadows**: Subtle elevation effects
- **Smooth Animations**: 600-800ms duration with elastic curves

## 🏗️ Architecture

```
Amora/
├── frontend/           # Flutter app
│   ├── lib/
│   │   ├── core/      # Services, theme, constants
│   │   ├── features/  # Feature modules (auth, swipe, chat, profile)
│   │   └── shared/    # Shared widgets and models
├── backend/           # Backend services (future PocketBase integration)
└── .github/          # CI/CD workflows
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.16.0+)
- Dart SDK (3.0.0+)
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/Amora.git
cd Amora/frontend
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Generate code**
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

4. **Configure Telegram Bot (for image uploads)**
   - Create a Telegram bot via @BotFather
   - Get your bot token and chat ID
   - Update `lib/core/services/telegram_service.dart`:
   ```dart
   static const String botToken = 'YOUR_BOT_TOKEN_HERE';
   static const String chatId = 'YOUR_CHAT_ID_HERE';
   ```

5. **Run the app**
```bash
flutter run
```

## 📱 Supported Platforms

- ✅ Android (API 21+)
- ✅ iOS (12.0+)
- ✅ Web (Chrome, Safari, Firefox)
- 🔄 Desktop (Coming soon)

## 🛠️ Development

### Local Development
The app uses SQLite (Hive) for local development and testing:
- Fast offline development
- Real-world data testing
- Easy debugging

### Production
For production, the app will integrate with:
- **PocketBase**: Backend database and API
- **Telegram Bot API**: Image hosting and storage
- **Firebase**: Push notifications (optional)

### Building

**Android APK:**
```bash
flutter build apk --release
```

**iOS IPA:**
```bash
flutter build ios --release
```

**Web:**
```bash
flutter build web --release
```

## 🔄 CI/CD

GitHub Actions automatically builds the app for all platforms:
- **Android**: APK and AAB files
- **iOS**: IPA file (unsigned)
- **Web**: Static files for deployment

Artifacts are available in the Actions tab after each build.

## 🎯 Roadmap

### Phase 1 (Current)
- ✅ Core UI/UX implementation
- ✅ Authentication system
- ✅ Profile management
- ✅ Swipe functionality
- ✅ Basic chat interface

### Phase 2 (Next)
- 🔄 PocketBase integration
- 🔄 Real-time messaging
- 🔄 Push notifications
- 🔄 Advanced matching algorithm
- 🔄 Video calls

### Phase 3 (Future)
- 📋 Premium features
- 📋 Social media integration
- 📋 AI-powered recommendations
- 📋 Events and meetups
- 📋 Safety features

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Material Design for design inspiration
- Telegram for free image hosting API
- PocketBase for the backend solution

## 📞 Support

For support, email support@amora.app or join our Discord community.

---

Made with ❤️ by the Amora team