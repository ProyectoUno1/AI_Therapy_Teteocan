# System Requirements & Dependencies

## 📋 Critical Files Needed

### 1. Firebase Configuration Files
- **`android/app/google-services.json`** 
  - Source: Firebase Console → Project Settings → Your apps → Android app
  - Contains: Package name `aurora.android_app`, API keys, OAuth client IDs
  - Required for: Authentication, Google Sign-In

- **`backend/config/firebase/aurora-ai-therapy-firebase-adminsdk.json`**
  - Source: Firebase Console → Service accounts → Generate new private key
  - Contains: Admin SDK credentials for backend operations
  - Required for: User verification, token validation

### 2. Database Configuration
- **PostgreSQL Database**
  - Version: 12 or higher
  - Database name: `aurora_db`
  - Connection string in `backend/config/db.js`

### 3. Environment Variables
Create `backend/.env`:
```env
DATABASE_URL=postgresql://username:password@localhost:5432/aurora_db
FIREBASE_ADMIN_SDK_PATH=./config/firebase/aurora-ai-therapy-firebase-adminsdk.json
PORT=3000
NODE_ENV=development
```

## 🔧 Required Software Versions

### Flutter & Dart
- **Flutter SDK**: 3.32.6 (stable)
- **Dart SDK**: 3.8.7 (included with Flutter)

### Android Development
- **Android Studio**: 2025.1.1 or later
- **Android SDK**: API levels 23-36
- **Java JDK**: 11 or higher
- **Gradle**: 8.0+ (managed by Flutter)

### Backend Development
- **Node.js**: 16.0+ (18.0+ recommended)
- **npm**: 8.0+ (comes with Node.js)
- **PostgreSQL**: 12+ (for database)

### Firebase
- **Firebase CLI**: 13.0+ (`npm install -g firebase-tools`)
- **Firebase Admin SDK**: 11.0+ (installed via npm)

## 🔐 Security & Access Requirements

### Firebase Project Access
Developers need:
1. **Google Account** with access to Firebase project
2. **Firebase Console Access** (Owner/Editor role)
3. **Ability to download**:
   - `google-services.json` (Android config)
   - Service account private key (Admin SDK)

### Database Access
- **PostgreSQL credentials** for local development
- **Database creation permissions**
- **Connection to development database**

### Google Sign-In Configuration
- **SHA-1 fingerprint** from development machine
- **Added to Firebase Console** under Project Settings → SHA certificate fingerprints
- **Google Sign-In enabled** in Firebase Authentication methods

## 🚀 Quick Start Commands

### Initial Setup (One-time)
```bash
# Clone repository
git clone https://github.com/ProyectoUno1/AI_Therapy_Teteocan.git
cd AI_Therapy_Teteocan

# Install Flutter dependencies
flutter pub get

# Install backend dependencies
cd backend
npm install

# Install Firebase CLI globally
npm install -g firebase-tools

# Login to Firebase
firebase login

# Start PostgreSQL and create database
createdb aurora_db
```

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

### Check Database Connection
```bash
psql -U username -d aurora_db -c "SELECT version();"
```

### Check Firebase Emulator
```bash
curl http://localhost:4000  # Should return Firebase emulator UI
curl http://localhost:9099  # Should return Firebase Auth emulator
```

## 🎯 Testing Authentication Features

### What Works ✅
- Email registration and login
- Auto-navigation to home screen
- Database synchronization
- User logout
- Firebase emulator integration

### What Needs Configuration ⚠️
- **Google Sign-In**: Requires SHA-1 fingerprint configuration
- **Production Firebase**: Requires production environment setup
- **Database migrations**: May need schema updates

## 📞 Developer Onboarding Checklist

### Before Starting Development
- [ ] Flutter SDK installed and configured
- [ ] Android Studio with Android SDK
- [ ] Node.js and npm installed
- [ ] PostgreSQL database running
- [ ] Firebase CLI installed
- [ ] Access to Firebase project
- [ ] `google-services.json` file obtained
- [ ] Firebase Admin SDK key obtained
- [ ] Environment variables configured
- [ ] SHA-1 fingerprint generated and added to Firebase

### Verify Everything Works
- [ ] `flutter doctor` shows no errors
- [ ] Firebase emulator starts successfully
- [ ] Backend server starts without errors
- [ ] Android emulator launches
- [ ] Flutter app builds and runs
- [ ] Email authentication works
- [ ] Database operations work
- [ ] App navigation works properly

## 🔄 Maintenance & Updates

### Regular Updates
- Keep Flutter SDK updated: `flutter upgrade`
- Update dependencies: `flutter pub upgrade`
- Update npm packages: `npm update`
- Monitor Firebase SDK updates

### Security Considerations
- Rotate Firebase service account keys regularly
- Keep database credentials secure
- Monitor Firebase authentication logs
- Update Android SDK and security patches
