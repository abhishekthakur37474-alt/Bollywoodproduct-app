# Bollywood Product APIs

All REST APIs use `GET` requests. The app expects HTTP `200` and JSON responses.

## Movie APIs

- Latest Movies - https://bollywoodproduct.com/api-latest-movies.php
- Upcoming Movies - https://www.bollywoodproduct.com/api-upcoming-movies.php
- All Movies - https://www.bollywoodproduct.com/api-all-movies.php
- Full Movies - https://www.bollywoodproduct.com/api-full-movies.php
- Search Films - https://www.bollywoodproduct.com/api-films.php
- Dubbed Movies - https://www.bollywoodproduct.com/api-dubbed-movies.php
- Movie Detail - https://www.bollywoodproduct.com/language-subdomain/api-film.php?unique_id={unique_id}
- Movie Detail and CBFC - https://hindi.bollywoodproduct.com/api-film-details.php?unique_id={unique_id}

## OTT APIs

- OTT Movies - https://www.bollywoodproduct.com/api-ott-movies.php
- Latest OTT Movies - https://www.bollywoodproduct.com/api-ott-latest-movies.php
- Upcoming OTT Movies - https://www.bollywoodproduct.com/api-ott-upcoming-movies.php

## Trailer APIs

- All Trailers - https://hindi.bollywoodproduct.com/api-trailers.php
- Latest Trailers - https://www.bollywoodproduct.com/api-latest-trailers.php
- Most Viewed Trailers - https://www.bollywoodproduct.com/api-most-viewed-trailers.php

## Celebrity APIs

- Today's Celebrity Birthdays - https://bollywoodproduct.com/api-today-cast-birthday.php?page={page}&limit={limit}
- Tomorrow's Celebrity Birthdays - https://www.bollywoodproduct.com/api-tommorow-cast-birthday.php?page={page}&limit={limit}
- Celebrity Profile - https://www.bollywoodproduct.com/api-cast-list.php?profile_unique_id={profile_unique_id}

## Songs APIs

- Latest Songs - https://www.bollywoodproduct.com/api/songs/latest.php

## Firebase APIs

Firebase is used through the Firebase SDK, not direct REST URLs.

- Firebase Initialization - Firebase.initializeApp()
- Google Login - FirebaseAuth.signInWithCredential()
- Firebase Logout - FirebaseAuth.signOut()
- Current User - FirebaseAuth.instance.currentUser
- Save User Profile - Firestore: users/{uid}
- Upload Profile Image - Storage: users/{uid}/profile.jpg
- Get Profile Image URL - Firebase Storage getDownloadURL()
- Read Notifications - Firestore: users/{uid}/notifications
- Save Notification - Firestore: users/{uid}/notifications/{notificationId}
- Mark Notification Seen - Firestore: users/{uid}/notifications/{notificationId}
- Delete Notification - Firestore: users/{uid}/notifications/{notificationId}
- Submit Movie Report - Firestore: reports/{reportId}
- Get FCM Token - FirebaseMessaging.instance.getToken()
- Receive Foreground Notification - FirebaseMessaging.onMessage
- Open Notification Event - FirebaseMessaging.onMessageOpenedApp

## External Media APIs

- YouTube Video - https://www.youtube.com/watch?v={video_id}
- YouTube Thumbnail - https://img.youtube.com/vi/{video_id}/0.jpg
- YouTube HD Thumbnail - https://img.youtube.com/vi/{video_id}/hqdefault.jpg
- YouTube Metadata Check - https://noembed.com/embed?url=https://www.youtube.com/watch?v={video_id}
- Placeholder Image - https://via.placeholder.com/640x360/1a1a1a/ffffff?text=No+Image

## Common Response Keys

- Movie APIs - `movies`, `data`
- OTT APIs - `films`
- Trailer APIs - `trailers`
- Birthday and Celebrity APIs - `data`
- Songs API - `songs`

## Common Query Parameters

- `unique_id` - Movie unique ID
- `profile_unique_id` - Celebrity profile unique ID
- `page` - Pagination page number
- `limit` - Number of records per page

## Source Files

- REST services - `lib/services/`
- Home API loader - `lib/utils/home_service.dart`
- Direct screen API calls - `lib/screens/`
- Firebase services - `lib/services/auth_service.dart`, `user_service.dart`, `notification_service.dart`, `report_service.dart`, and `fcm_service.dart`
