# VetCare Mobile 🐾

[![Mobile CI](https://github.com/santy123371/VetCare-Mobile/actions/workflows/ci.yml/badge.svg)](https://github.com/santy123371/VetCare-Mobile/actions/workflows/ci.yml)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.50.1-02569B?logo=flutter)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.14.0-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

VetCare Mobile is the official Flutter client for the VetCare veterinary management system. It provides an intuitive, secure, and modern mobile interface for pet owners, veterinarians, and clinic administrators to manage pets, appointments, medical records, and digital attendance.

---

## Features

- **Pet Profile Management**: Full CRUD for pets with live species styling, species emojis, medical attributes, and multi-owner assignments for clinic staff.
- **Secure Image Upload**: Camera and gallery image picker with runtime permission handling. All uploads are processed and sanitized by the backend `ImageValidator` (magic bytes verification, GD recoding, and EXIF metadata stripping).
- **Authentication & Security**:
  - JWT token exchange with automatic background refresh rotation.
  - Secure credential and token storage backed by Android Keystore (`flutter_secure_storage`).
  - Biometric authentication (Fingerprint / Face ID via `local_auth`).
  - Automatic session timeout via inactivity detection.
  - Optional SSL/TLS certificate pinning for zero-trust API communication.
- **Appointments & Records**: Quick consultation of upcoming clinical appointments and vaccination records.
- **QR Code Attendance**: Built-in camera scanner (`mobile_scanner`) for clinic check-ins.

---

## Tech Stack & Architecture

- **Framework**: Flutter 3.50+ / Dart 3.14+
- **State Management**: [Riverpod](https://riverpod.dev) (Annotations & Code Generation)
- **Networking**: [Dio](https://pub.dev/packages/dio) with interceptors and certificate validation adapters
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Device Features**: [image_picker](https://pub.dev/packages/image_picker), [permission_handler](https://pub.dev/packages/permission_handler), [mobile_scanner](https://pub.dev/packages/mobile_scanner), [local_auth](https://pub.dev/packages/local_auth)

---

## Project Structure

```text
lib/
├── core/
│   ├── api/          # Dio client, certificate pinning, and interceptors
│   ├── auth/         # Riverpod auth providers, inactivity detector
│   ├── router/       # GoRouter declarative navigation routes
│   ├── storage/      # Secure storage wrappers (JWT & refresh tokens)
│   └── theme/        # App color palettes, dark mode, typography
├── features/
│   ├── appointments/ # Appointments view and status tracking
│   ├── auth/         # Login screen, biometric unlock
│   ├── dashboard/    # Metric cards, upcoming schedules
│   ├── pets/         # Pet listing, filters, and dynamic pet form with image upload
│   └── qr/           # Scanner and attendance validation
├── shared/
│   ├── models/       # Data transfer objects (Pet, User, ClientOwner)
│   └── widgets/      # Reusable UI components
└── main.dart         # App entry point, environment loading, i18n
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `>= 3.22.0` (Recommended: `3.50.1`)
- [Android Studio](https://developer.android.com/studio) with Android SDK API 34+ and command-line tools
- Java 17 (JDK)

### Setup & Configuration

1. **Clone the repository**:
   ```bash
   git clone https://github.com/santy123371/VetCare-Mobile.git
   cd VetCare-Mobile
   ```

2. **Configure environment variables**:
   Copy `.env.example` to `.env` and configure your API URL:
   ```bash
   cp .env.example .env
   ```

   Inside `.env`:
   ```properties
   # Android emulator loopback to host XAMPP/Apache:
   API_BASE_URL=http://10.0.2.2/veterinaria_php/api/v1

   # For real device testing across local network:
   # API_BASE_URL=http://192.168.80.100:1005/api/v1

   # Optional SSL Certificate Pin (SHA256 digest in lowercase):
   # SSL_PIN_SHA256=your_pin_here
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

---

## Running & Building

### Development Mode

Run on a connected Android device or emulator:
```bash
flutter run
```

### Build APK

Generate a debug build for testing:
```bash
flutter build apk --debug
```

Or a release build:
```bash
flutter build apk --release
```

Install via ADB:
```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

---

## Testing & Quality

Run analyzer:
```bash
flutter analyze --no-fatal-infos
```

Run test suite:
```bash
flutter test
```

Generate test coverage:
```bash
flutter test --coverage
```

---

## Continuous Integration (CI/CD)

GitHub Actions workflows are located in `.github/workflows/`:
- **Mobile CI (`ci.yml`)**: Automates `flutter analyze`, unit tests with code coverage, dependency audit, `.env` leak prevention, and Android APK compilation.
- **Security Scan (`security.yml`)**: Scheduled and PR scanning for hardcoded secrets (TruffleHog) and vulnerable dependencies.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
