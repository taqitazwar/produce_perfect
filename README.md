# ProducePerfect

> Reducing waste, one imperfect produce at a time.

ProducePerfect is a mobile marketplace that connects farmers with consumers to
sell imperfect and surplus produce at a discount. Cosmetically imperfect fruit
and vegetables are a major source of food waste even though they are perfectly
good to eat. ProducePerfect gives farmers a channel to sell that produce, gives
consumers cheaper groceries, and coordinates local riders to handle delivery.

**NL Eats Food Forward Innovation Challenge, 1st Runner-Up (2025).**

<img width="1582" height="940" alt="ProducePerfect app" src="https://github.com/user-attachments/assets/0137cc21-ac69-4d3d-ab14-8e85c5b39cc4" />

[Watch the demo video](Demo.mp4)

## Overview

The app supports three roles from a single codebase, all kept in sync through
real-time Firestore streams:

- **Farmers** list imperfect or surplus produce with photos, pricing, and a farm
  location.
- **Consumers** browse nearby listings, build a cart, enter a delivery address,
  and check out.
- **Riders** see available orders live, accept them, and navigate from the farm
  to the consumer to complete delivery.

## Features

- Email and password authentication with role-based sign-up
- Farmer product listings with image upload and inventory management
- Consumer browsing by category, cart, and checkout with a demo payment flow
- Distance-based delivery fees calculated from farm and delivery locations
- Google Places address autocomplete and Google Maps turn-by-turn navigation
- Real-time order tracking across the full delivery lifecycle
- Impact stats for food saved and estimated carbon avoided

## Tech stack

- **Flutter** and **Dart** for the cross-platform UI
- **Firebase Authentication** for accounts
- **Cloud Firestore** for real-time data
- **Firebase Storage** for product and profile images
- **Google Maps, Places, and Distance Matrix APIs** for location and routing
- **provider** for state management and **go_router** for navigation

## How it works

The marketplace connects three participants:

1. **Farmer** lists surplus or imperfect produce at a discount, including a farm
   location and product photos.
2. **Consumer** browses nearby produce, adds items to a cart, provides a delivery
   address, and pays at checkout.
3. **Rider** sees available orders in real time, accepts one, navigates to the
   farm to pick up, and then to the consumer to deliver.

```
Farmer lists produce
        |
        v
Consumer browses and orders  ->  Order created in Firestore
        |                                   |
        v                                   v
Payment (demo)                     Rider sees order in real time
                                            |
                                            v
                             Rider picks up at farm, delivers to consumer
                                            |
                                            v
                              Status updates stream back to all parties
```

Distances between a farm and a delivery address are computed with the Google
Maps Distance Matrix API and drive the delivery fee. Riders use turn-by-turn
navigation to travel from the farm to the consumer.

## Project structure

```
lib/
  constants/   Theme, colors, and shared constants
  models/      Data models (user, product, order, category)
  screens/     UI grouped by role: auth, consumer, farmer, rider
  services/    Firebase, cart, orders, payments, and maps logic
  widgets/     Reusable UI components
```

State is managed with `provider`, navigation uses `go_router`, and the UI is
built on Material with `google_fonts` and `flutter_animate`. Backend
configuration lives at the repository root: `firestore.rules`, `storage.rules`,
and `firestore.indexes.json`.

## Data model

Firestore holds four main collections:

- **`users/{userId}`** - profile for any role, including `userType` (`farmer`,
  `consumer`, or `rider`), contact details, and a geocoded address
  (`latitude`, `longitude`, `placeId`) used for distance and delivery-fee
  calculations.
- **`products/{productId}`** - a farmer's produce listing: title, description,
  category, `originalPrice`, `discountedPrice`, `quantity`, `unit`, image URLs,
  farm location, and an `isAvailable` flag.
- **`orders/{orderId}`** - a consumer order referencing the farmer, ordered
  items, pricing (`subtotal`, `deliveryFee`, `total`), delivery and farm
  locations, and a `status` that moves through the delivery lifecycle:
  `pending` -> `confirmed` -> `preparing` -> `readyForPickup` -> `pickedUp` ->
  `inTransit` -> `delivered` (or `cancelled`).
- **`carts/{userId}`** - the signed-in consumer's cart items, private to the
  owner.

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.9 or newer
- An Android device or emulator (or the Android toolchain via Android Studio)
- A [Firebase](https://console.firebase.google.com/) project
- A [Google Cloud](https://console.cloud.google.com/) project with the Maps and
  Places APIs enabled

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Configure Firebase

1. Create a project in the Firebase Console.
2. Add an Android app with the package name `com.produceperfect.app.produce_perfect`.
3. Download the generated `google-services.json` and place it in `android/app/`.
   This file is intentionally not committed to the repository.
4. Populate `lib/services/firebase_options.dart` with your project's values, or
   regenerate it with the
   [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup):

   ```bash
   flutterfire configure
   ```

5. Enable **Email/Password** authentication, **Cloud Firestore**, and
   **Storage** in the Firebase Console.
6. Deploy the security rules and indexes included in this repository:

   ```bash
   firebase deploy --only firestore:rules,firestore:indexes,storage
   ```

   Composite indexes can take a few minutes to finish building.

### 3. Configure Google Maps and Places

1. In the Google Cloud Console, enable the Maps SDK for Android, Places API,
   Geocoding API, Distance Matrix API, and Directions API.
2. Create an API key under **APIs and Services > Credentials**. Restricting it to
   the APIs above and to your Android package name is recommended.
3. Add the key in the three places the app reads it, each currently set to the
   placeholder `YOUR_GOOGLE_MAPS_API_KEY`:
   - `lib/services/maps_service.dart`
   - `lib/widgets/address_picker.dart`
   - `android/app/src/main/AndroidManifest.xml`

### 4. Run the app

```bash
flutter run
```

To exercise the full workflow, sign up one account for each role (farmer,
consumer, and rider) so you can post produce, place an order, and deliver it.
