# FIRESTORE SECURITY RULES

Copy these rules to your Firestore Database → Rules section:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users can read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      // Allow other authenticated users to read basic profile info (for orders)
      allow read: if request.auth != null && 
        resource.data.keys().hasAll(['name', 'userType', 'address']);
    }
    
    // Products - farmers can CRUD their own, others can read available ones
    match /products/{productId} {
      allow read: if request.auth != null && resource.data.isAvailable == true;
      allow create, update, delete: if request.auth != null && 
        request.auth.uid == resource.data.farmerId;
    }
    
    // Orders - complex rules for different user types
    match /orders/{orderId} {
      // Customers can read/create their own orders
      allow read, create: if request.auth != null && 
        request.auth.uid == resource.data.customerId;
      
      // Farmers can read orders for their products
      allow read: if request.auth != null && 
        request.auth.uid == resource.data.farmerId;
      
      // Riders can read unassigned orders and their assigned orders
      allow read: if request.auth != null && (
        resource.data.riderId == null || 
        request.auth.uid == resource.data.riderId
      );
      
      // Riders can update orders to accept them or change status
      allow update: if request.auth != null && (
        // Accepting an order (setting riderId)
        (resource.data.riderId == null && 
         request.data.riderId == request.auth.uid) ||
        // Updating status of assigned order
        (resource.data.riderId == request.auth.uid)
      );
    }
    
    // Carts - users can only access their own cart
    match /carts/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Real-time notifications (optional)
    match /notifications/{notificationId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
  }
}
```

## FIRESTORE INDEXES

You'll need to create these composite indexes in Firestore:

1. **Orders Collection:**
   - Fields: `status` (Ascending), `riderId` (Ascending), `orderDate` (Ascending)
   - Fields: `customerId` (Ascending), `orderDate` (Descending)
   - Fields: `farmerId` (Ascending), `orderDate` (Descending)
   - Fields: `riderId` (Ascending), `orderDate` (Descending)

2. **Products Collection:**
   - Fields: `isAvailable` (Ascending), `createdAt` (Descending)
   - Fields: `farmerId` (Ascending), `isAvailable` (Ascending), `createdAt` (Descending)
   - Fields: `category` (Ascending), `isAvailable` (Ascending), `createdAt` (Descending)

To create these indexes:
1. Go to Firestore → Indexes
2. Click "Create Index"
3. Add the fields as specified above
4. Set Query scope to "Collection"

## STORAGE RULES

For Firebase Storage (product images):

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Product images - only farmers can upload
    match /products/{farmerId}/{imageId} {
      allow read: if true; // Anyone can read product images
      allow write: if request.auth != null && 
        request.auth.uid == farmerId &&
        request.resource.size < 5 * 1024 * 1024 && // Max 5MB
        request.resource.contentType.matches('image/.*');
    }
    
    // Profile images - users can upload their own
    match /profiles/{userId}/{imageId} {
      allow read: if true;
      allow write: if request.auth != null && 
        request.auth.uid == userId &&
        request.resource.size < 2 * 1024 * 1024 && // Max 2MB
        request.resource.contentType.matches('image/.*');
    }
  }
}
```
