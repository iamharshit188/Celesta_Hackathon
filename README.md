# Fake News & Deepfake Detection App

A multi-modal, cross-platform application for detecting fake news and deepfakes, built with Flutter frontend and Python backend using UV for fast dependency management.

## ✨ Features

- **Multi-Modal Verification**: Text, voice, URL, and video input support
- **AI-Powered Detection**: BERT for text, MediaPipe for deepfakes, VOSK for speech
- **Modern UI**: Perplexity-inspired dark theme with smooth animations
- **Real-time Results**: Confidence scores and explanatory verdicts
- **Fact-Checking**: Integrated source verification and fact-check search
- **Cross-Platform**: Flutter app for iOS, Android, and Web

## 🛠 Tech Stack

| Component | Technology |
|-----------|------------|
| Frontend | Flutter with Provider |
| Backend | Python FastAPI |
| Package Manager | UV (fast Python packaging) |
| Text Detection | BERT (HuggingFace), Groq API, Gemini API |
| Speech-to-Text | Groq API (Whisper model) |
| Web Crawling | newspaper3k, BeautifulSoup |
| Deepfake Detection | MediaPipe, OpenCV |
| TTS | Flutter TTS plugin |

## 🚀 Quick Start

### Prerequisites
- [UV](https://github.com/astral-sh/uv) - Fast Python package installer
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable)
- Python 3.8+

### Installation

1. **Clone and setup:**
   ```bash
   git clone <repository-url>
   cd fake_news_detector
   chmod +x setup.sh
   ./setup.sh
   ```

2. **Configure API keys:**
   ```bash
   cd backend
   cp .env.example .env
   # Edit .env with your API keys
   ```

3. **Start the backend:**
   ```bash
   cd backend
   uv run python main.py     # Basic server
   # or
   uv run uvicorn main:app --reload    # Development with hot reload
   ```

   **Note**: AI models will be installed separately when needed:
   ```bash
   uv sync --extra ml    # Install ML dependencies (PyTorch, etc.)
   ```

4. **Start the frontend:**
   ```bash
   cd frontend
   flutter run
   ```

## 🔧 Development Commands

### Backend (with UV)
```bash
cd backend

# Development server with hot reload
uv run scripts.py dev

# Production server
uv run scripts.py prod

# Run tests
uv run scripts.py test

# Format code
uv run scripts.py format

# Lint code
uv run scripts.py lint

# Type checking
uv run scripts.py typecheck

# Install AI models
uv run scripts.py install-models
```

### Frontend
```bash
cd frontend

# Install dependencies
flutter pub get

# Run on all platforms
flutter run

# Build for production
flutter build apk --release    # Android
flutter build ios --release    # iOS
flutter build web              # Web
```

## 📋 API Endpoints

### Verification
- `POST /api/v1/verify/text` - Text verification
- `POST /api/v1/verify/voice` - Voice input processing
- `POST /api/v1/verify/url` - URL content verification
- `POST /api/v1/verify/video` - Video deepfake detection

### News Discovery
- `GET /api/v1/news/feed` - Get categorized news feed
- `POST /api/v1/news/search` - Search news articles
- `GET /api/v1/news/categories` - Available categories
- `GET /api/v1/news/trending` - Trending topics

### System
- `GET /health` - Health check with model status
- `GET /docs` - Interactive API documentation

## 🏗 Project Structure

```
fake_news_detector/
├── frontend/                 # Flutter mobile app
│   ├── lib/
│   │   ├── screens/         # UI screens
│   │   ├── widgets/         # Reusable components
│   │   ├── services/        # API and business logic
│   │   ├── models/          # Data models
│   │   └── utils/           # Utilities and themes
│   └── pubspec.yaml
├── backend/                  # Python FastAPI server
│   ├── app/
│   │   ├── api/            # API endpoints
│   │   ├── services/       # AI/ML services
│   │   ├── models/         # Pydantic schemas
│   │   └── utils/          # Configuration
│   ├── pyproject.toml      # UV dependencies
│   ├── scripts.py          # Development scripts
│   └── main.py             # Application entry
├── docs/                    # Documentation
└── setup.sh                # Automated setup
```

## 🤖 AI Models

### Text Detection
- **Model**: `hamzab/roberta-fake-news-classification`
- **Purpose**: Classify text as real/fake news
- **Input**: Plain text (max 5000 characters)
- **Output**: Verdict with confidence score

### Deepfake Detection
- **Model**: MediaPipe Face Mesh + Custom Analysis
- **Purpose**: Detect video manipulation and deepfakes
- **Input**: Video files (MP4, AVI, MOV, MKV)
- **Output**: Authenticity analysis with explanation

### Speech Processing
- **Model**: Groq API (Whisper model)
- **Purpose**: Convert speech to text for analysis
- **Input**: Audio data (WAV, 16kHz mono preferred)
- **Output**: Transcribed text

## ⚙️ Configuration

### Backend Environment Variables
```bash
# Server
HOST=127.0.0.1
PORT=8000
DEBUG=true

# API Keys (recommended for enhanced features)
GROQ_API_KEY=your_groq_api_key_here           # For text analysis and speech-to-text
GEMINI_API_KEY=your_gemini_api_key_here       # For text analysis
PERPLEXITY_API_KEY=your_perplexity_api_key    # For fact-checking
GOOGLE_SEARCH_API_KEY=your_key_here           # For fact-checking
GOOGLE_SEARCH_ENGINE_ID=your_engine_id        # For fact-checking
NEWS_API_KEY=your_news_api_key                # For news feed

# Model Settings
MAX_FILE_SIZE=52428800  # 50MB
MAX_TEXT_LENGTH=5000
HIGH_CONFIDENCE_THRESHOLD=0.8
```

## 🔒 Security Features

- Input validation and sanitization
- File size and type restrictions
- Temporary file cleanup
- CORS protection
- Rate limiting ready (implement for production)

## 🧪 Testing

```bash
# Backend tests
cd backend
uv run scripts.py test

# Frontend tests
cd frontend
flutter test

# Integration tests
# Run backend, then frontend tests with live API
```

## 📱 Platform Support

- **iOS**: Native app with full feature support
- **Android**: Native app with full feature support  
- **Web**: Progressive web app (limited camera access)
- **Desktop**: Flutter desktop support (experimental)

## 🚀 Deployment

### Backend Production
```bash
# Using UV
uv run scripts.py prod

# Direct uvicorn
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4

# Docker (create Dockerfile)
FROM python:3.11-slim
COPY . /app
WORKDIR /app
RUN pip install uv && uv sync
CMD ["uv", "run", "scripts.py", "prod"]
```

### Frontend Production
```bash
# Mobile apps
flutter build apk --release
flutter build ios --release

# Web deployment
flutter build web
# Deploy to Firebase, Netlify, or Vercel
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make changes following the code standards
4. Test your changes: `uv run scripts.py test && flutter test`
5. Format code: `uv run scripts.py format`
6. Submit a pull request

### Code Standards
- **Python**: PEP 8, type hints, minimal comments
- **Flutter**: Dart style guide, clean architecture
- **No emojis** in source code
- **Clean commits** with clear messages

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: Check `/docs` directory
- **Issues**: Create GitHub issues for bugs
- **Discussions**: Use GitHub discussions for questions
- **API Docs**: Visit `http://localhost:8000/docs` when running

## 🎯 Roadmap

- [ ] User authentication and profiles
- [ ] Advanced deepfake detection models
- [ ] Multi-language support
- [ ] Real-time fact-checking streams
- [ ] Browser extension
- [ ] Mobile-specific optimizations
- [ ] Advanced analytics dashboard

---

Built with ❤️ using UV, Flutter, and FastAPI
