## 🔧 Email Verification Setup Guide

### **Issue:** Email OTP not being received

### **Root Causes:**
1. Firebase email templates not configured
2. Development environment email delays
3. Email provider spam filtering
4. Domain authentication issues

---

## **🔥 Firebase Console Setup:**

### **Step 1: Configure Email Templates**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your `request-marketplace` project
3. Navigate to **Authentication** → **Templates**
4. Configure these templates:
   - ✉️ **Email address verification**
   - 🔐 **Password reset** 
   - 📧 **Email address change**

### **Step 2: Email Template Settings**
```
From Name: Request Marketplace
Reply-to: noreply@request-marketplace.com
Subject: Verify your email address for Request Marketplace
```

### **Step 3: Custom Action URL (Recommended)**
```
Action URL: https://your-domain.com/auth/action
```

---

## **📱 Testing the Fix:**

### **Option 1: Use Development Bypass**
- In the email verification screen, you'll now see a "Development Mode" section
- Click **"Continue Without Verification (Dev Only)"** to test the app
- **⚠️ Remove this in production!**

### **Option 2: Test with Different Email Providers**
- Try with **Gmail** (usually works best)
- Try with **Outlook/Hotmail**
- Avoid company/corporate emails (often blocked)

### **Option 3: Check Spam/Junk Folder**
- Firebase emails often end up in spam
- Add Firebase to your contacts/safe senders

---

## **🚀 Immediate Testing:**

1. **Run the app:** `flutter run`
2. **Try email signup** with a Gmail address
3. **Wait 2-5 minutes** for email delivery
4. **Check spam folder** if not in inbox
5. **Use development bypass** if email still doesn't arrive

---

## **📈 Production Recommendations:**

### **1. Custom Email Domain**
- Set up custom domain: `auth@your-domain.com`
- Configure SPF, DKIM records
- Use professional email service (SendGrid, AWS SES)

### **2. Email Templates**
- Design custom HTML templates
- Add company branding
- Include support contact information

### **3. Backup Authentication**
- Phone number verification
- Social login (Google, Apple)
- Magic link authentication

---

## **🐛 Debugging:**

### **Check Console Logs:**
```bash
flutter logs
```
Look for these messages:
- "Sending verification email to: ..."
- "Verification email sent successfully!"
- Any error messages

### **Common Error Messages:**
- `too-many-requests`: Wait before resending
- `invalid-email`: Check email format
- `user-not-found`: User needs to sign up first

---

## **✅ Success Indicators:**
- ✅ Email appears in inbox (2-5 minutes)
- ✅ Click verification link works
- ✅ User redirected to main app
- ✅ No error messages in console

**Need help?** Check the troubleshooting section in the email verification screen!
