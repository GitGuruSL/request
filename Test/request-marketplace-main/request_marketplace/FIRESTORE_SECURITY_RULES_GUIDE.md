# Firestore Security Rules Setup Guide

## Problem
User authentication is working but no data is being saved to Firestore collections. This is most likely due to Firestore security rules blocking writes.

## Solution

### Step 1: Go to Firebase Console
1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `request-marketplace`
3. Navigate to **Firestore Database** in the left sidebar
4. Click on the **Rules** tab

### Step 2: Check Current Rules
Your current rules probably look like this (blocking all access):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### Step 3: Update Rules for Authenticated Users
Replace your rules with these (allows authenticated users to access their own data):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read and write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow authenticated users to read/write activity logs for themselves
    match /activities/{activityId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.uid;
    }
    
    // Temporary: Allow all authenticated users to write to test collection for debugging
    match /test/{document} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Step 4: Publish the Rules
1. Click **Publish** to apply the new rules
2. You should see a confirmation that the rules were updated

### Step 5: Test the App
1. Try registering a new user or signing in with Google
2. Check the Flutter logs for our connectivity test results
3. Check the Firestore console to see if user documents are now being created

## Alternative: Temporary Open Rules (NOT for production)
If you want to test without any restrictions temporarily:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```
**⚠️ WARNING: This allows anyone to read/write all data. Only use for testing!**

## What Each Rule Does

### `request.auth != null`
- Ensures the user is authenticated with Firebase Auth
- This should be true after successful Google Sign-In or email registration

### `request.auth.uid == userId`
- Ensures users can only access their own user document
- The `userId` in the path must match their authentication UID

### `resource.data.uid`
- References the `uid` field in the document being accessed
- Used for documents that store which user they belong to

## Testing
After updating the rules, run the app and:
1. Look for "✅ Successfully wrote test document" in the logs
2. Check if user documents appear in Firestore console under `/users/{uid}`
3. Look for any permission-denied errors in the Flutter logs

## Common Issues
- **Clock skew**: Make sure your device time is correct
- **Authentication state**: User must be fully authenticated before Firestore writes
- **Rule syntax**: Make sure there are no syntax errors in the rules editor
