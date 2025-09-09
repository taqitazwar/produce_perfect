# Firebase Composite Index Required

## The Error:
```
The query requires an index. You can create it here:
https://console.firebase.google.com/v1/r/project/produceperfect-8b5ee/firestore/indexes?create_composite
```

## Required Index for Orders Collection:

**Collection ID:** `orders`

**Fields to index:**
1. **status** - Ascending
2. **orderDate** - Ascending

## How to Create the Index:

### Method 1: Use the Error Link
1. Click the link in the error message (if available)
2. It will automatically create the correct index

### Method 2: Manual Creation in Firebase Console
1. Go to Firebase Console → Firestore Database
2. Click on **"Indexes"** tab
3. Click **"Create Index"**
4. Set:
   - **Collection ID:** `orders`
   - **Field 1:** `status` (Ascending)
   - **Field 2:** `orderDate` (Ascending)
5. Click **"Create"**

### Method 3: Using Firebase CLI (if you have it installed)
```bash
firebase deploy --only firestore:indexes
```

## Index Configuration (firestore.indexes.json):
```json
{
  "indexes": [
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "orderDate",
          "order": "ASCENDING"
        }
      ]
    }
  ]
}
```

## Wait Time:
After creating the index, wait **5-10 minutes** for it to build completely.
