# Developer Setup Guide - Aurora AI Therapy App

## 📋 Prerequisites

### Required Software
1. **Flutter SDK** (version 3.32.6 or higher)
   - Download from: https://flutter.dev/docs/get-started/install
   - Add to system PATH

2. **Android Studio** (latest version)
   - Download from: https://developer.android.com/studio
   - Install Android SDK (API 23-36)
   - Create at least one Android Virtual Device (AVD)

3. **Node.js** (version 16 or higher)
   - Download from: https://nodejs.org/
   - Includes npm package manager

4. **Java Development Kit (JDK)**
   - JDK 11 or higher required for Android development

5. **Git** (for version control)
   - Download from: https://git-scm.com/

6. **Visual Studio Code** (recommended)
   - With Flutter and Dart extensions

### System Configuration
- **Windows**: Version 10/11 (64-bit)
- **RAM**: Minimum 8GB (16GB recommended for smooth emulator performance)
- **Storage**: At least 10GB free space

## 🔧 Installation Steps

### 1. Clone the Repository
```bash
git clone https://github.com/ProyectoUno1/AI_Therapy_Teteocan.git
cd AI_Therapy_Teteocan
```

### 2. Flutter Setup
```bash
# Check Flutter installation
flutter doctor

# Install Flutter dependencies
flutter pub get

# Enable desktop and web support (optional)
flutter config --enable-windows-desktop
flutter config --enable-web
```

### 3. Firebase Setup
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase (requires Google account)
firebase login

# Navigate to backend directory
cd backend

# Install backend dependencies
npm install

# Install development dependencies
npm install --save-dev nodemon
```

### 4. Android Development Setup
```bash
# Check Android toolchain
flutter doctor

# Create Android Virtual Device (if not exists)
flutter emulators --create

# List available emulators
flutter emulators
```

## 🔐 Required Secrets & Configuration

### 1. Firebase Configuration
- **File**: `android/app/google-services.json`
- **Source**: Firebase Console → Project Settings → General → Your apps → Android app
- **Required**: This file contains Firebase project configuration and is essential for authentication

### 2. Database Configuration
- **File**: `backend/config/db.js`
- **Required Environment Variables**:
  ```
  DATABASE_URL=postgresql://username:password@localhost:5432/aurora_db
  ```

### 3. Firebase Admin SDK
- **File**: `backend/config/firebase/aurora-ai-therapy-firebase-adminsdk.json`
- **Source**: Firebase Console → Project Settings → Service accounts → Generate new private key
- **Required**: For backend Firebase Admin operations

### 4. Environment Variables
Create `.env` file in `backend/` directory:
```env
# Database
DATABASE_URL=postgresql://username:password@localhost:5432/aurora_db

# Firebase
FIREBASE_ADMIN_SDK_PATH=./config/firebase/aurora-ai-therapy-firebase-adminsdk.json

# Server
PORT=3000
NODE_ENV=development
```

## 📱 Package Name Configuration

### Important: Package Name Alignment
The app uses package name `aurora.android_app` which must match the Firebase configuration:

1. **Android Configuration**: Already configured in:
   - `android/app/build.gradle.kts` (applicationId and namespace)
   - `android/app/src/main/kotlin/aurora/android_app/MainActivity.kt`

2. **Firebase Configuration**: 
   - `google-services.json` must contain `aurora.android_app` as package name
   - SHA-1 fingerprint must match development certificate

### Generate SHA-1 Fingerprint (if needed)
```bash
# Navigate to android directory
cd android

# Generate debug SHA-1
./gradlew signingReport

# Look for SHA1 fingerprint in the output
```

## 🚀 Running the Application

### 1. Start Firebase Emulator
```bash
cd backend
firebase emulators:start
```

### 2. Start Backend Server
```bash
# In another terminal
cd backend
npm run dev
```

### 3. Start Android Emulator
```bash
# Check available emulators
flutter emulators

# Start specific emulator
flutter emulators --launch <emulator_name>
```

### 4. Run Flutter App
```bash
# Run on Android emulator
flutter run

# Or specify device
flutter run -d emulator-5554
```

## 🔍 Verification Steps

### Check Installation
```bash
# Flutter environment
flutter doctor -v

# Node.js and npm
node --version
npm --version

# Firebase CLI
firebase --version

# Android SDK
flutter devices
```

### Test Authentication Flow
1. **Firebase Emulator**: Should be accessible at http://localhost:4000
2. **Backend Server**: Should respond at http://localhost:3000
3. **App Features**:
   - ✅ Email Registration
   - ✅ Email Login
   - ✅ Auto-Navigation
   - ✅ Database Sync
   - ✅ Logout
   - ⚠️ Google Sign-In (needs SHA-1 configuration)

## 🐛 Common Issues & Solutions

### Issue: "google-services.json not found"
**Solution**: 
1. Download from Firebase Console
2. Place in `android/app/` directory
3. Ensure package name matches `aurora.android_app`

### Issue: "Firebase emulator connection failed"
**Solution**:
1. Check if emulator is running on port 9099
2. Verify network security config allows cleartext traffic
3. Ensure `useEmulator = true` in `lib/main.dart`

### Issue: "Android build failed"
**Solution**:
1. Check Java version (JDK 11+ required)
2. Verify Android SDK installation
3. Clean and rebuild: `flutter clean && flutter pub get`

### Issue: "Database connection failed"
**Solution**:
1. Install PostgreSQL locally
2. Create database named `aurora_db`
3. Update connection string in `backend/config/db.js`

### Issue: "Google Sign-In failed"
**Solution**:
1. Ensure SHA-1 fingerprint is added to Firebase Console
2. Verify package name matches in all configurations
3. Check if Google Sign-In is enabled in Firebase Console

## 📞 Support

For additional support:
1. Check Flutter documentation: https://flutter.dev/docs
2. Firebase documentation: https://firebase.google.com/docs
3. Android development: https://developer.android.com/docs

## 🔄 Development Workflow

### Daily Development
1. Start Firebase emulator: `firebase emulators:start`
2. Start backend server: `npm run dev`
3. Start Android emulator
4. Run Flutter app: `flutter run`
5. Use hot reload (`r`) for quick development iterations

### Before Committing
1. Run tests: `flutter test`
2. Check code formatting: `dart format .`
3. Analyze code: `flutter analyze`
4. Ensure all authentication flows work

### Production Deployment
1. Change `useEmulator = false` in `lib/main.dart`
2. Update Firebase configuration for production
3. Build release APK: `flutter build apk --release`
4. Deploy backend to production server
5. Update database connection strings
