# Firestore Security Rules

Copy and paste these rules into your Firebase Console → Firestore Database → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read and write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Products can be read by anyone, written by authenticated farmers
    match /products/{productId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Orders can be read and written by authenticated users
    match /orders/{orderId} {
      allow read, write: if request.auth != null;
    }
    
    // Carts collection - users can only access their own cart
    match /carts/{userId} {
      allow read, write, create, update, delete: if request.auth != null && request.auth.uid == userId;
    }
    
    // Categories can be read by anyone
    match /categories/{categoryId} {
      allow read: if true;
      allow write: if false; // Only admins can write categories
    }
  }
}
```

## How to Apply:

1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your project
3. Go to **Firestore Database** → **Rules**
4. Replace the existing rules with the rules above
5. Click **Publish**

These rules allow:
- ✅ Users to create and manage their own profiles
- ✅ Anyone to read products (for shopping)
- ✅ Authenticated users to create products and orders
- ✅ Public access to categories

This should fix the Firestore permission issues you might be experiencing.
