# System Requirements & Dependencies

## 📋 Critical Files Needed

### 1. Firebase Configuration Files
- **`android/app/google-services.json`** 
  - Source: Firebase Console → Project Settings → Your apps → Android app
  - Contains: Package name `aurora.android_app`, API keys, OAuth client IDs
  - Required for: Authentication, Google Sign-In

- **`backend/config/firebase/firebase_secret_key.json`**
  - Source: Firebase Console → Service accounts → Generate new private key
  - Contains: Admin SDK credentials for backend operations
  - Required for: User verification, token validation

### 2. Environment Variables
  - Source: GitHub → AI_Therapy_Teteocan → Setings → Secrets and variables → Actions → Variables → BACKEND_ENV

## 🚀 Quick Start Commands

### Initial Setup (One-time)
```bash
# Install Flutter dependencies
flutter pub get

# Install backend dependencies
cd backend
npm install

# Install Firebase CLI globally
npm install -g firebase-tools

# Login to Firebase
firebase login

### Daily Development
```bash
# Terminal 1: Start Firebase emulator
cd backend
firebase emulators:start

# Terminal 2: Start backend server
cd backend
npm run dev

# Terminal 3: Start Android emulator and run app
flutter emulators --launch Medium_Phone_API_36.0  # or your emulator name
flutter run
```
## 🔍 Environment Verification

### Check Flutter Setup
```bash
flutter doctor -v
flutter devices
flutter --version
```

### Check Node.js Setup
```bash
node --version
npm --version
firebase --version
```

### Check Firebase Emulator
```bash
curl http://localhost:4000  # Should return Firebase emulator UI
curl http://localhost:9099  # Should return Firebase Auth emulator
```

## 🔧 Required Software Versions

### Android Development
- **Android Studio**: 2025.1.1 or later
- **Android SDK**: API levels 23-36
- **Java JDK**: 11 or higher
- **Gradle**: 8.0+

### Backend Development
- **Node.js**: 16.0+ (18.0+ recommended)
- **npm**: 8.0+ (comes with Node.js)
- **PostgreSQL**: 12+ (for database)

### Firebase
- **Firebase CLI**: 13.0+ (`npm install -g firebase-tools`)
- **Firebase Admin SDK**: 11.0+ (installed via npm)