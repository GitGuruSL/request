# 🚀 Production Deployment Checklist

## ⚠️ **CRITICAL CHANGES BEFORE GOOGLE PLAY UPLOAD**

### 1. **Switch to Production Mode** (REQUIRED)
**File**: `request/lib/src/services/contact_verification_service.dart`
**Line**: 16

**CHANGE THIS:**
```dart
static const bool _isDevelopmentMode = true; // ❌ DEVELOPMENT MODE
```

**TO THIS:**
```dart
static const bool _isDevelopmentMode = false; // ✅ PRODUCTION MODE
```

**Impact:**
- ✅ Real SMS will be sent (costs ~$0.01-0.05 per SMS)
- ✅ Real email verification required
- ❌ No more automatic verification

### 2. **Firebase SMS Configuration**
- [ ] Go to [Firebase Console](https://console.firebase.google.com/)
- [ ] Select your project: `request-marketplace`
- [ ] Navigate to Authentication → Sign-in method → Phone
- [ ] Ensure billing account is attached (SMS requires paid plan)
- [ ] Test SMS sending with a real phone number

### 3. **Email Service Configuration**
Current implementation uses simplified email verification. For production:
- [ ] Test email verification flow
- [ ] Consider implementing proper email service (SendGrid, etc.)
- [ ] Ensure email templates are professional

### 4. **App Signing for Release**
```bash
# Generate release keystore (run once)
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias upload

# Build release APK
flutter build apk --release

# Or build app bundle (recommended for Google Play)
flutter build appbundle --release
```

### 5. **Required Legal Documents**
- [ ] **Privacy Policy** (MANDATORY for Google Play)
- [ ] **Terms of Service**
- [ ] Data collection disclosure (phone, email, location, documents)

### 6. **Google Play Store Requirements**
- [ ] Developer account ($25 one-time fee)
- [ ] App screenshots (minimum 2, maximum 8)
- [ ] Feature graphic (1024x500 px)
- [ ] High-res app icon (512x512 px)
- [ ] Store description and metadata

### 7. **Testing Checklist**
- [ ] Test production SMS verification with real phone number
- [ ] Test production email verification with real email
- [ ] Test complete business verification flow
- [ ] Verify no development artifacts remain (test accounts, debug info)

## 📱 **Current App Status**

### ✅ **Ready for Production**
- Contact verification system (Firebase linkWithCredential)
- Business verification flow
- User authentication
- UI/UX complete
- Firebase integration

### ⚠️ **Needs Production Setup**
- Switch to production mode
- Firebase billing for SMS
- App signing and release build
- Legal documents
- Google Play Store listing

## 🎯 **Quick Deployment Steps**

1. **Change production mode**: `_isDevelopmentMode = false`
2. **Test real verification**: SMS + Email
3. **Build release**: `flutter build appbundle --release`
4. **Create Play Store listing**: Upload APK + metadata
5. **Submit for review**: Google Play review process

## 💰 **Expected Costs**
- Google Play Developer: $25 (one-time)
- Firebase SMS: $0.01-0.05 per verification
- Monthly SMS (estimated): $10-50 depending on users

## 📞 **Production Mode Changes**

### Development Mode (Current):
```
Phone Verification: OTP = 123456 (fixed)
Email Verification: Automatic approval
Cost: $0
```

### Production Mode (After switch):
```
Phone Verification: Real SMS with random OTP
Email Verification: Real email with verification link
Cost: ~$0.01-0.05 per SMS verification
```

---

**Ready for production when all checkboxes above are completed! ✅**
