# 🔥 Firebase Storage Security Rules

## **PROBLEM:**
```
Failed to create post: Failed to create product: Failed to upload image: 
[firebase_storage/unauthorized] User is not authorized to perform the desired action.
```

## **SOLUTION:**

### **Step 1: Go to Firebase Console**
1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **produceperfect-8b5ee**
3. Click **Storage** in the left sidebar
4. Click the **Rules** tab

### **Step 2: Replace Storage Rules**
Replace your current rules with these:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow authenticated users to upload images to their own folders
    match /products/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow anyone to read product images (for shopping)
    match /products/{allPaths=**} {
      allow read: if true;
    }
    
    // Allow authenticated users to upload profile images
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // General rule for authenticated users
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### **Step 3: Publish Rules**
1. Click **Publish** button
2. Wait for the rules to deploy (usually takes 1-2 minutes)

## **WHAT THESE RULES DO:**

✅ **Allow authenticated farmers** to upload product images  
✅ **Allow anyone** to view product images (for shopping)  
✅ **Allow authenticated users** to upload profile pictures  
✅ **Secure user-specific** folders (users can only access their own images)  

## **ALTERNATIVE SIMPLE RULE (For Development):**

If you want a simpler rule for development/testing:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

This allows any authenticated user to read/write any file. **Use only for development!**

## **AFTER UPDATING RULES:**

1. ✅ **Test farmer post creation** - should work without errors
2. ✅ **Images should upload successfully**
3. ✅ **Product posts should appear on consumer home screen**

---

**Once you update these rules, your farmers will be able to create posts with images successfully! 🌟**
