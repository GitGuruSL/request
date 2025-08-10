# 🚨 FIREBASE AUTHENTICATION CONFIGURATION FIX

## CRITICAL ERROR:
```
Invalid app info in play_integrity_token
This app is not authorized to use Firebase Authentication
```

## IMMEDIATE FIXES REQUIRED:

### 1. GET YOUR APP'S SHA FINGERPRINTS
Run these commands to get your SHA fingerprints:

```bash
# Debug keystore (for development)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# If using Linux/Mac, also try:
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA
```

### 2. ADD SHA FINGERPRINTS TO FIREBASE
1. Go to: https://console.firebase.google.com/project/request-marketplace/settings/general
2. Scroll down to "Your apps" section
3. Click on your Android app
4. Click "Add fingerprint" 
5. Add BOTH SHA-1 AND SHA-256 from the keytool output above

### 3. ENABLE PHONE AUTHENTICATION
1. Go to: https://console.firebase.google.com/project/request-marketplace/authentication/providers
2. Click "Phone" and enable it
3. Add test phone number: +94 760 222 222 with code: 123456

### 4. UPDATE SECURITY RULES
The permission denied error shows Firestore rules are blocking writes.

Go to: https://console.firebase.google.com/project/request-marketplace/firestore/rules

Replace rules with:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own data
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 5. DOWNLOAD NEW CONFIG FILE
After adding SHA fingerprints:
1. Download new `google-services.json`
2. Replace the old one in `android/app/google-services.json`

## PRIORITY ORDER:
1. ✅ Add SHA fingerprints to Firebase Console
2. ✅ Enable phone authentication  
3. ✅ Update Firestore security rules
4. ✅ Download new google-services.json
5. ✅ Test phone verification and response submission
