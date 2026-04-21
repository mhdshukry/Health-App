# Wellness Hub

Wellness Hub is a Flutter app for tracking activities, goals, health logs, reminders, tips, profile data, and analytics. The mobile app uses Riverpod and GoRouter, and it is backed by a Node.js/Express API with MongoDB for authentication and sync.

## What’s Included

- Flutter app with routing for onboarding, login, dashboard, activities, goals, tips, profile, health logs, analytics, reminders, and settings
- Node.js backend with JWT auth, sync endpoints, seeded wellness tips, and MongoDB persistence
- Support for Android, iOS, web, macOS, Windows, and Linux from the same workspace

## Project Structure

- `lib/` - Flutter app source
- `backend/` - Express API server
- `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/` - platform runners
- `test/` - Flutter widget tests

## Prerequisites

- Flutter SDK 3.24 or newer
- Node.js 18 or newer
- MongoDB running locally or a reachable MongoDB URI

## Frontend Setup

From the repository root:

```bash
flutter pub get
flutter run
```

The app starts at the splash screen and routes through onboarding, login, and the main dashboard shell based on app state.

## Backend Setup

From the `backend/` directory:

```bash
npm install
npm run dev
```

For a production-style start, use:

```bash
npm start
```

## Environment Variables

The backend reads these values from `.env`:

- `PORT` - API port, defaults to `4000`
- `MONGO_URI` - MongoDB connection string, defaults to `mongodb://localhost:27017/wellness_hub`
- `JWT_SECRET` - JWT signing secret, defaults to `change-me`

Example `backend/.env`:

```env
PORT=4000
MONGO_URI=mongodb://localhost:27017/wellness_hub
JWT_SECRET=replace-with-a-long-random-secret
```

## API Overview

The backend exposes these routes under `/api`:

- `GET /api/health`
- `POST /api/auth` and related auth routes
- `GET /api/sync`
- `GET /api/profile`
- `GET /api/activities`
- `GET /api/health-logs`
- `GET /api/goals`
- `GET /api/reminders`
- `GET /api/tips`

Most routes require a Bearer token. The backend seeds default tips on first startup when the tips collection is empty.

## Notes

- The root `.gitignore` excludes `backend/node_modules/`, `backend/.env`, and `Health.db`.
- If you change the backend port or MongoDB URI, update the mobile app’s API configuration accordingly.

