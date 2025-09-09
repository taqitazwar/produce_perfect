# GOOGLE MAPS API SETUP

## 1. GET API KEYS

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing
3. Enable these APIs:
   - **Maps SDK for Android**
   - **Maps SDK for iOS** 
   - **Places API**
   - **Distance Matrix API**
   - **Directions API**
   - **Geocoding API**

4. Create API Key:
   - Go to Credentials → Create Credentials → API Key
   - Copy the API key
   - Restrict the API key (recommended for production)

## 2. UPDATE CODE WITH API KEYS

Replace `YOUR_GOOGLE_MAPS_API_KEY` and `YOUR_GOOGLE_PLACES_API_KEY` in these files:

**lib/services/maps_service.dart:**
```dart
static const String _apiKey = 'YOUR_ACTUAL_API_KEY_HERE';
```

**lib/widgets/address_picker.dart:**
```dart
googleAPIKey: "YOUR_ACTUAL_API_KEY_HERE",
```

## 3. ANDROID CONFIGURATION

**android/app/src/main/AndroidManifest.xml:**
```xml
<application>
    <!-- Add inside <application> tag -->
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="YOUR_ACTUAL_API_KEY_HERE"/>
</application>

<!-- Add these permissions before <application> -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

## 4. iOS CONFIGURATION

**ios/Runner/AppDelegate.swift:**
```swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

**ios/Runner/Info.plist:**
```xml
<dict>
    <!-- Add these permissions -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>This app needs location access to calculate delivery distances and provide navigation.</string>
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>This app needs location access to calculate delivery distances and provide navigation.</string>
</dict>
```

## 5. TESTING LOCATIONS

For testing, you can use these sample coordinates:

**New York City Area:**
- Farmer 1: 40.7128, -74.0060 (Manhattan)
- Farmer 2: 40.6782, -73.9442 (Brooklyn) 
- Customer: 40.7589, -73.9851 (Upper West Side)

**Distance Calculation Test:**
- Manhattan to Brooklyn ≈ 8km
- Delivery fee = 8km × 2 × $2 = $32

## 6. PRODUCTION CONSIDERATIONS

1. **API Key Security:**
   - Use different API keys for development/production
   - Restrict API keys to specific apps/domains
   - Monitor API usage in Google Cloud Console

2. **Rate Limiting:**
   - Google Maps APIs have quotas
   - Implement caching for frequent requests
   - Consider upgrading to paid tier for production

3. **Offline Handling:**
   - Implement fallback distance calculations
   - Cache frequently used locations
   - Show appropriate error messages
