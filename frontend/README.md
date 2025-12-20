# LFG Connect Frontend

Flutter app for the LFG Connect application.

## Setup

1. Ensure Flutter is installed: https://flutter.dev/docs/get-started/install
2. Install dependencies:

```bash
flutter pub get
```

## Running the App

```bash
flutter run
```

For web:
```bash
flutter run -d chrome
```

## Project Structure

- `lib/main.dart` - App entry point
- `lib/screens/` - UI screens
- `lib/models/` - Data models
- `lib/services/` - API service
- `lib/providers/` - State management with Provider
- `lib/widgets/` - Reusable widgets

## API Configuration

Update the `baseUrl` in `lib/services/api_service.dart` to match your backend URL.

## Features

- User Authentication (Register/Login)
- Game Collection Management
- Friend Management
- Local Multiplayer Session Scheduling
- RSVP System
- Attendance Tracking
