# 🔥 MISSING FIREBASE INDEX

## You need to add ONE more index to Firebase:

Go to **Firebase Console → Firestore Database → Indexes** and add this index:

**Index: Farmer Products Query**
```
Collection ID: products
Fields:
  - farmerId (Ascending)
  - isAvailable (Ascending) 
  - createdAt (Descending)
Query scope: Collection
```

This is the exact index that the error message is requesting. The URL in the error message should take you directly to create this index.

## Alternative: Click the URL in the error message

The red error message contains a direct link to create the missing index:
`https://console.firebase.google.com/v1/r/project/produceperfect-8b5ee/firestore/indexes?create_composite=...`

Just click that URL and it will auto-create the index for you.

---

After adding this index, the farmer screens will work perfectly!
