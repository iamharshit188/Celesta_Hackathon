# WP FactCheck

AI-powered fact-checking Flutter application by Team WaterPlane.

## Features

### 🔍 Fact Checking
- **Text Analysis**: Paste any text or claim for instant fact-checking
- **URL Processing**: Extract and analyze content from web URLs
- **Voice Input**: Use speech-to-text for hands-free fact-checking
- **Offline Mode**: Local TFLite model for offline analysis
- **Confidence Scoring**: AI-powered confidence ratings for results

### 📰 News Exploration
- **Curated Feed**: Latest news from trusted Indian sources via NewsAPI
- **Category Filters**: Politics, Tech, Business, Sports, Entertainment
- **Infinite Scroll**: Seamless browsing experience with shimmer loading
- **Offline Reading**: Cached articles for offline access
- **Bookmarking**: Save important articles for later

### 👤 User Experience
- **Onboarding**: Smooth first-time user experience
- **Profile Management**: Personalized user profiles with statistics
- **Theme Support**: Light, dark, and system themes
- **Responsive Design**: Optimized for mobile, tablet, and desktop
- **Accessibility**: VoiceOver/TalkBack support, text scaling up to 200%

## Architecture

- **State Management**: Riverpod for reactive state management
- **Navigation**: GoRouter with bottom navigation and deep linking
- **Security**: Encrypted storage for sensitive data
- **Testing**: Comprehensive widget, unit, and accessibility tests

## 🏗️ Architecture

```
lib/
├── app.dart                    # Main app configuration
├── main.dart                   # App entry point
├── core/                       # Core infrastructure
│   ├── constants/              # App-wide constants
│   ├── database/               # SQLite database helper
│   ├── error/                  # Error handling (failures, exceptions)
│   ├── navigation/             # GoRouter configuration
│   ├── network/                # Connectivity service
│   ├── storage/                # Secure storage & shared preferences
│   ├── theming/                # Material 3 themes
│   └── utils/                  # Extensions, validators, utilities
├── data/                       # Data layer
│   ├── api_clients/            # API clients (News, FactCheck)
│   ├── dto/                    # Data transfer objects
│   ├── models/                 # Data models
│   └── repositories/           # Repository implementations
├── domain/                     # Domain layer
│   ├── entities/               # Business entities
│   ├── repositories/           # Repository interfaces
│   └── use_cases/              # Business logic use cases
└── presentation/               # Presentation layer
    ├── main/                   # Home/Main screen
    ├── explore/                # News exploration screen
    ├── profile/                # Profile & onboarding screens
    └── shared_widgets/         # Reusable UI components
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.9.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / VS Code with Flutter extensions

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd wpfactcheck
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API Keys**
   - Get a NewsAPI key from [newsapi.org](https://newsapi.org)
   - Add your API keys to secure storage or environment variables

4. **Run the app**
   ```bash
   flutter run
   ```

### Development Setup

1. **Enable device preview** (optional)
   ```dart
   // In main.dart, set enabled: true
   DevicePreview(enabled: true, ...)
   ```

2. **Run tests**
   ```bash
   flutter test
   flutter test integration_test/
   ```

3. **Generate golden files**
   ```bash
   flutter test --update-goldens
   ```

## Configuration

### API Endpoints
- **News API**: `https://newsapi.org/v2`
- **Fact Check API**: Configure your backend endpoint
- **Health Check**: `/healthz` endpoint for service monitoring

### Storage Limits
- **Cached Articles**: 50 articles (LRU eviction)
- **Cached Analyses**: 20 results (LRU eviction)
- **Database**: SQLite with automatic cleanup

### Offline Capabilities
- **Local Model**: TFLite RoBERTa for offline fact-checking
- **Cached Content**: News articles and analysis results
- **Connectivity Awareness**: Automatic online/offline detection

## Project Structure

### Core Components
- **Constants**: App-wide configuration and constants
- **Theming**: Material3 light/dark themes with adaptive support
- **Error Handling**: Comprehensive failure and exception management
- **Utilities**: Extensions, validators, and helper functions

### Data Layer
- **Models**: Data models with JSON serialization
- **API Clients**: HTTP clients with retry logic and error handling
- **Repositories**: Implementation of domain repository interfaces
- **Local Storage**: SQLite database and secure storage services

### Domain Layer
- **Entities**: Core business objects
- **Use Cases**: Business logic and application services
- **Repositories**: Abstract interfaces for data access

### Presentation Layer
- **Screens**: Main UI screens (Home, Explore, Profile)
- **Widgets**: Reusable UI components
- **State Management**: Riverpod providers and notifiers

## Testing

### Widget Tests
- Screen rendering and interaction tests
- Accessibility compliance tests
- Text scaling and responsive design tests

### Integration Tests
- End-to-end user workflows
- API integration and offline scenarios
- Navigation and state persistence

### Golden Tests
- Visual regression testing
- Theme consistency across screens
- Responsive layout validation

## Accessibility Features

- **Screen Reader Support**: Full VoiceOver/TalkBack compatibility
- **Text Scaling**: Support up to 200% text scaling
- **High Contrast**: Optimized for high contrast mode
- **Haptic Feedback**: Tactile feedback for interactions
- **Semantic Labels**: Comprehensive semantic annotations

## Performance Optimizations

- **Image Caching**: Cached network images with fallbacks
- **Database Indexing**: Optimized SQLite queries
- **Lazy Loading**: Efficient list rendering with pagination
- **Memory Management**: Proper disposal of resources
- **Network Optimization**: Request batching and retry logic

## Security

- **Secure Storage**: Encrypted storage for sensitive data
- **Input Validation**: Comprehensive input sanitization
- **API Security**: Secure API key management
- **Content Security**: Protection against harmful content

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Team

**Team WaterPlane**
- AI-powered fact-checking solution
- Built with ❤️ for accurate information

