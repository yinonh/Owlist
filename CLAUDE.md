# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is "Owlist" - a Flutter Todo/Goal management app that helps users create lists of goals or tasks with deadlines, progress tracking, notifications, and statistics. The app supports both Hebrew and English languages and includes features like custom themes, Google Mobile Ads integration, and local notifications.

## Development Commands

### Flutter Commands
- `flutter run` - Run the app in development mode
- `flutter build apk` - Build Android APK
- `flutter build appbundle` - Build Android App Bundle for Play Store
- `flutter build ios` - Build iOS app
- `flutter test` - Run unit tests
- `flutter analyze` - Run static analysis (linting)
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade dependencies
- `flutter clean` - Clean build artifacts

### Testing and Quality
- Use `flutter analyze` to check for linting issues
- The project uses `flutter_lints` package for code quality
- Test files are located in the `test/` directory

## Architecture

### Directory Structure
- `lib/main.dart` - App entry point with MultiProvider setup
- `lib/Models/` - Data models (ToDoItem, ToDoList, Notification)
- `lib/Providers/` - State management using Provider pattern
  - `ItemProvider` - Manages todo items
  - `ListsProvider` - Manages todo lists
  - `NotificationProvider` - Handles notifications
- `lib/Screens/` - Main app screens
  - `HomePage` - Main dashboard
  - `SingleListScreen` - Individual list view
  - `ContentScreen` - Item content view
  - `StatisticsScreen` - Progress statistics
- `lib/Widgets/` - Reusable UI components
- `lib/Utils/` - Utilities, helpers, themes, and localization
- `Assets/` - Images, icons, and language files

### State Management
The app uses Provider pattern for state management with three main providers:
1. `NotificationProvider` - Manages local notifications and scheduling
2. `ListsProvider` - Handles todo list CRUD operations and data persistence
3. `ItemProvider` - Manages individual todo items within lists

### Key Dependencies
- `provider` - State management
- `sqflite` - Local SQLite database
- `flutter_local_notifications` - Push notifications
- `google_mobile_ads` - Advertisement integration
- `flutter_localization` - Multi-language support
- `shared_preferences` - Local storage for settings
- `fl_chart` - Statistics charts
- `showcaseview` - Feature onboarding

### Database
Uses SQLite via `sqflite` for local data persistence. Database operations are handled through the Provider classes.

### Localization
Supports Hebrew and English with localization files in `Assets/languages/`. Uses `flutter_localization` package and custom localizations in `lib/Utils/l10n/`.

### Theming
Supports light/dark themes and system theme. Theme configurations are in `lib/Utils/themes.dart`.

### Notifications
Local notifications are implemented using `flutter_local_notifications` with custom scheduling and payload handling for navigation.

## Configuration Files

### Environment
- `.env` file contains environment variables (loaded with `flutter_dotenv`)
- Environment variables should not be committed to git

### Build Configuration
- `android/app/build.gradle` - Android build settings
- `pubspec.yaml` - Dependencies and app metadata
- Current version: 1.2.12+22

## Development Notes

- The app enforces portrait orientation only
- Uses Material Design with custom themes
- Implements showcase/onboarding flow for new users
- Integrates feedback system for user reports
- Ad integration requires proper environment setup
- The app name in code is "OwlistApp" while package is "to_do"