# 🔑 Google Places API Key Fix

## **PROBLEM:**
```
Invalid API key error when selecting delivery address
```

## **SOLUTION:**

### **Step 1: Enable Places API**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Go to **APIs & Services** → **Library**
4. Search for **"Places API"**
5. Click **"Places API"** and click **"Enable"**

### **Step 2: Enable Additional APIs**
Also enable these APIs for full functionality:
- **Places API (New)** ✅
- **Maps SDK for Android** ✅ 
- **Maps SDK for iOS** ✅
- **Geocoding API** ✅
- **Distance Matrix API** ✅
- **Directions API** ✅

### **Step 3: Check API Key Restrictions**
1. Go to **APIs & Services** → **Credentials**
2. Click on your API key: `AIzaSyDW7fSRAERAoO91N3-nyeKrrBBWEwYkR4Q`
3. Under **API restrictions**:
   - Select **"Restrict key"**
   - Check all the APIs listed above
4. Under **Application restrictions**:
   - Select **"Android apps"**
   - Add your package name: `com.produceperfect.app.produce_perfect`
   - Add your SHA-1 fingerprint

### **Step 4: Test the Fix**
1. **Wait 5-10 minutes** for changes to propagate
2. **Restart your app** 
3. **Try selecting an address** - should work without errors

## **ALTERNATIVE: Create New API Key**

If issues persist, create a new API key:

1. Go to **APIs & Services** → **Credentials**
2. Click **"+ CREATE CREDENTIALS"** → **"API key"**
3. Copy the new key
4. Replace in code:
   - `lib/services/maps_service.dart` line 6
   - `lib/widgets/address_picker.dart` line 103
   - `android/app/src/main/AndroidManifest.xml`

## **QUICK TEST:**
After enabling APIs, try the address picker - it should show suggestions as you type!

---

**The most common issue is that Places API is not enabled for your project. Enable it and wait 5-10 minutes! 🔑**
