# Firebase Setup for Produce Perfect

## Prerequisites
- Firebase project created in [Firebase Console](https://console.firebase.google.com/)
- Google Console account set up

## Setup Instructions

### 1. Firebase Project Configuration

1. Go to your Firebase Console
2. Select your project
3. Click on "Project Settings" (gear icon)
4. Scroll down to "Your apps" section
5. Click on "Add app" and select Android
6. Register your app with package name: `com.produceperfect.app.produce_perfect`

### 2. Download Configuration File

1. Download the `google-services.json` file
2. Place it in the `android/app/` directory of your Flutter project

### 3. Update Firebase Configuration

1. Open `lib/services/firebase_options.dart`
2. Replace the placeholder values with your actual Firebase configuration:
   - `apiKey`: Your API key from Firebase
   - `appId`: Your app ID from Firebase
   - `messagingSenderId`: Your messaging sender ID
   - `projectId`: Your project ID
   - `storageBucket`: Your storage bucket URL

### 4. Enable Authentication

1. Go to Firebase Console > Authentication
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Email/Password" authentication
5. Optionally enable Google and Facebook sign-in

### 5. Set up Firestore Database

1. Go to Firebase Console > Firestore Database
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select your preferred location

### 6. Security Rules (Important!)

Update your Firestore security rules to:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Add more rules as you expand the app
  }
}
```

### 7. Build and Test

After setting up Firebase:

1. Run `flutter clean`
2. Run `flutter pub get`
3. Run `flutter run` to test the app

## Features Implemented

- ✅ Email/Password Authentication
- ✅ User Registration with role selection (Farmer, Rider, Customer)
- ✅ Password Reset functionality
- ✅ Modern UI with animations
- ✅ Form validation
- ✅ User profile creation in Firestore

## Next Steps

To complete the app, you'll need to:

1. Set up actual Firebase configuration
2. Implement home screens for each user type
3. Add produce listing functionality for farmers
4. Add delivery management for riders
5. Add shopping functionality for customers
6. Implement real-time notifications
7. Add payment integration

## Troubleshooting

### Build Errors
- Ensure `google-services.json` is in the correct location
- Check that all Firebase configuration values are correct
- Run `flutter clean` and `flutter pub get`

### Authentication Issues
- Verify Firebase Authentication is enabled
- Check that email/password sign-in method is enabled
- Ensure your app's package name matches Firebase configuration

## Support

For Firebase-specific issues, refer to the [Firebase Documentation](https://firebase.google.com/docs).
