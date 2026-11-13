# Mom&Baby (EXE201)

[![Flutter](https://img.shields.io/badge/Flutter-App-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%5E3.7.2-0175C2?logo=dart&logoColor=white)](https://dart.dev)
![State Management](https://img.shields.io/badge/State%20Management-Provider-6A5ACD)
![API](https://img.shields.io/badge/API-REST-2E8B57)
![Real-time](https://img.shields.io/badge/Real--time-SignalR-512BD4)

Mom&Baby is a Flutter mobile application designed to support parents during pregnancy and early parenthood. It brings doctor discovery and appointment services together with pregnancy journaling and helpful articles in one place.

## Features

- Create an account and sign in; manage your profile and account settings.
- Browse doctors, view doctor profiles, and book appointments.
- Chat with doctors and review appointment information.
- Read maternal and baby-care articles.
- Create, edit, and delete journal entries, and keep track of pregnancy milestones.
- Browse service or membership packages and manage payment methods.
- Register and manage an expert account, including appointments and articles.

> Mom&Baby is an informational and appointment-support app. It does not replace professional medical advice, diagnosis, or treatment.

## Tech stack

- Flutter and Dart
- Provider for app state
- REST APIs for accounts, doctors, appointments, journals, articles, and packages
- SignalR for real-time communication
- Secure storage for authentication data

## Requirements

- Flutter SDK with Dart `^3.7.2` or a compatible newer version
- Android Studio or VS Code with the Flutter and Dart extensions
- Access to the Mom&Baby backend for features that require server data

Check your local Flutter setup with:

```bash
flutter doctor
```

## Run locally

1. Clone or extract this project, then open the Flutter app directory (`exe_201`).
2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Check the API base URL in `lib/config.dart`. The app currently uses the configured Mom&Baby backend; update this value if you are using another backend.
4. Start an emulator or connect a device, then run:

   ```bash
   flutter run
   ```

## Tests

Run the Flutter tests with:

```bash
flutter test
```

## Project structure

```text
lib/
  api/        API clients
  auth/       Sign-in, registration, and password recovery
  blog/       Articles and article details
  chat/       User and doctor chat screens
  doctor/     Doctor profiles and appointment flows
  expert/     Expert tools and appointment management
  journal/    Journal entries, calendar, and milestones
  nav/        Main navigation and user-facing pages
  payment/    Packages and payment screens
  profile/    Profile and account settings
  service/    Real-time communication services
```
