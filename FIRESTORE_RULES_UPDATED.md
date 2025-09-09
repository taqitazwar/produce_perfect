# Updated Firestore Security Rules

## Current Error:
```
Listen for Query(users/[userId]) failed: Status{code=PERMISSION_DENIED, description=Missing or insufficient permissions.}
```

## Updated Rules for Firebase Console:

Go to **Firestore Database** → **Rules** tab and replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection - allow users to read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      // Allow other authenticated users to read basic profile info (for orders)
      allow read: if request.auth != null;
    }
    
    // Products collection - farmers can manage their products, everyone can read
    match /products/{productId} {
      allow read: if request.auth != null;
      allow create, update, delete: if request.auth != null && 
        request.auth.uid == resource.data.farmerId;
    }
    
    // Orders collection - customers and riders can access their orders
    match /orders/{orderId} {
      allow read, write: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
    }
    
    // Carts collection - users can manage their own cart
    match /carts/{userId} {
      allow read, write, create, update, delete: if request.auth != null && 
        request.auth.uid == userId;
    }
  }
}
```

## Key Changes:

1. **Users Collection**: 
   - Users can read/write their own profile
   - **NEW**: Other authenticated users can read profiles (needed for order processing)

2. **Orders Collection**:
   - **Simplified**: All authenticated users can read/write orders
   - **Reason**: Riders need to see all available orders, customers need to see their orders

3. **Products Collection**: 
   - Everyone can read (for browsing)
   - Only farmers can manage their own products

4. **Carts Collection**:
   - Users can only access their own cart

## Apply These Rules:

1. **Firebase Console** → **Firestore Database** → **Rules**
2. **Replace** existing rules with the above
3. **Click "Publish"**
4. **Wait 1-2 minutes** for rules to take effect

## Why This Fixes the Error:

The error occurs because riders need to read user profiles to get farmer addresses for orders, but the current rules don't allow cross-user profile reading. The updated rules allow authenticated users to read other user profiles while still protecting write access.
