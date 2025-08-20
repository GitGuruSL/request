# Unified Phone Verification System Documentation

## Overview
This document describes the unified phone verification system implemented for both business verification and driver verification in the Request Marketplace application. The system provides consistent phone and email verification across different user roles and verification types.

## System Architecture

### Database Tables
1. **`users`** - Main user table with personal contact information
   - `phone` - Personal phone number
   - `phone_verified` - Personal phone verification status
   - `email` - Primary email address
   - `email_verified` - Email verification status

2. **`user_phone_numbers`** - Professional phone numbers table
   - `user_id` - Reference to users table
   - `phone_number` - Professional phone number (normalized format)
   - `is_verified` - Verification status
   - `purpose` - Purpose of phone (business_verification, driver_verification, etc.)
   - `phone_type` - Type classification (professional, business, etc.)

3. **`business_verifications`** - Business verification records
   - `phone_verified` - Auto-populated verification status
   - `email_verified` - Auto-populated verification status

4. **`driver_verifications`** - Driver verification records
   - `phone_verified` - Auto-populated verification status
   - `email_verified` - Auto-populated verification status

### Phone Number Classification
- **Personal Phone**: Stored in `users.phone`, used for account registration and personal communications
- **Professional Phone**: Stored in `user_phone_numbers`, used for business/driver verification and professional activities

## Verification Logic

### Phone Verification Process
The system follows this priority order for phone verification:

1. **Professional Phone Check**: Check if phone exists in `user_phone_numbers` as verified
   - If found and verified → Phone is verified
   - Source: `user_phone_numbers`, Type: `professional`

2. **Personal Phone Check**: Check if phone matches user's personal phone and is verified
   - If matches and verified → Phone is verified
   - Source: `users_table`, Type: `personal`

3. **Auto-Update**: If user has no personal phone, update it with provided phone
   - Updates `users.phone` with normalized phone number
   - Requires manual verification

4. **OTP History Check**: Check if phone was previously verified via OTP
   - Fallback verification using `phone_otp_verifications` table
   - Auto-updates user verification status if found

### Email Verification Process
The system checks email verification:

1. **User Email Check**: If email matches user's email and is verified
   - Source: `users_table`

2. **Auto-Update**: If user has no email, update it with provided email
   - Updates `users.email` with provided email
   - Requires manual verification

### Phone Number Normalization
All phone numbers are normalized to Sri Lankan format:
- Input: `0725742238` → Output: `+94725742238`
- Input: `94725742238` → Output: `+94725742238`
- Input: `725742238` → Output: `+94725742238`
- Input: `+94725742238` → Output: `+94725742238`

## Implementation

### Business Verification
File: `backend/routes/business-verifications-simple.js`

#### Key Functions
```javascript
// Normalize phone numbers for consistent comparison
function normalizePhoneNumber(phone)

// Check phone verification status across all sources
async function checkPhoneVerificationStatus(userId, phoneNumber)

// Check email verification status
async function checkEmailVerificationStatus(userId, email)
```

#### API Endpoints
- `POST /api/business-verifications/verify-phone/send-otp` - Send OTP for phone verification
- `POST /api/business-verifications/verify-phone/verify-otp` - Verify OTP and mark phone as verified

### Driver Verification
File: `backend/routes/driver-verifications.js`

#### Key Functions
```javascript
// Same unified functions as business verification
function normalizePhoneNumber(phone)
async function checkPhoneVerificationStatus(userId, phoneNumber)
async function checkEmailVerificationStatus(userId, email)
```

#### API Endpoints
- `POST /api/driver-verifications/verify-phone/send-otp` - Send OTP for phone verification
- `POST /api/driver-verifications/verify-phone/verify-otp` - Verify OTP and mark phone as verified

## Usage Examples

### Business Verification Workflow
1. User submits business verification with phone `+94725742238`
2. System checks verification status:
   - Finds phone in `user_phone_numbers` as verified
   - Auto-marks `business_verifications.phone_verified = true`
   - Source: `user_phone_numbers`, Type: `professional`

### Driver Verification Workflow
1. User submits driver verification with same phone `+94725742238`
2. System checks verification status:
   - Finds same phone in `user_phone_numbers` as verified
   - Auto-marks `driver_verifications.phone_verified = true`
   - Source: `user_phone_numbers`, Type: `professional`

### Phone Verification API Usage
```javascript
// Send OTP
POST /api/business-verifications/verify-phone/send-otp
{
  "phoneNumber": "+94725742238",
  "userId": "user-uuid"
}

// Verify OTP
POST /api/business-verifications/verify-phone/verify-otp
{
  "phoneNumber": "+94725742238",
  "otp": "123456",
  "userId": "user-uuid"
}
```

## Benefits

### 1. Unified Verification
- Single phone verification works across all verification types
- No need to verify the same phone multiple times
- Consistent verification experience

### 2. Professional vs Personal Separation
- Professional phones stored separately in `user_phone_numbers`
- Personal phones remain in `users` table
- Clear separation of contact purposes

### 3. Automatic Verification
- Once a phone is verified professionally, it's automatically verified for other professional uses
- Reduces verification friction for users
- Maintains verification integrity

### 4. Flexible Phone Management
- Users can have multiple professional phones
- Each phone can serve different purposes
- Verification status tracked independently

## Database Schema Changes

### Added Columns
```sql
-- Business verifications table
ALTER TABLE business_verifications ADD COLUMN phone_verified BOOLEAN DEFAULT false;
ALTER TABLE business_verifications ADD COLUMN email_verified BOOLEAN DEFAULT false;

-- Driver verifications table
ALTER TABLE driver_verifications ADD COLUMN phone_verified BOOLEAN DEFAULT false;
ALTER TABLE driver_verifications ADD COLUMN email_verified BOOLEAN DEFAULT false;
```

### Required Tables
```sql
-- User phone numbers table (should already exist)
CREATE TABLE user_phone_numbers (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  phone_number VARCHAR(20) NOT NULL,
  country_code VARCHAR(5) DEFAULT 'LK',
  is_verified BOOLEAN DEFAULT false,
  is_primary BOOLEAN DEFAULT false,
  verified_at TIMESTAMP,
  label VARCHAR(50),
  purpose VARCHAR(100),
  phone_type VARCHAR(50),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, phone_number)
);
```

## Testing

### Test Data
- User ID: `5af58de3-896d-4cc3-bd0b-177054916335`
- Verified Professional Phone: `+94725742238`
- Purpose: `business_verification`
- Status: Verified ✅

### Test Cases
1. **Business Verification**: Phone `+94725742238` auto-verifies ✅
2. **Driver Verification**: Same phone auto-verifies ✅
3. **Phone Normalization**: Various formats normalize correctly ✅
4. **Email Verification**: User email auto-verifies ✅

## Future Enhancements

### 1. SMS Integration
- Integrate with SMS provider for actual OTP delivery
- Add SMS templates and delivery tracking

### 2. Multi-Country Support
- Extend normalization for other countries
- Country-specific phone validation

### 3. Phone Type Management
- Add more phone types (emergency, backup, etc.)
- User interface for managing multiple phones

### 4. Verification Analytics
- Track verification success rates
- Monitor verification sources and patterns

## Troubleshooting

### Common Issues
1. **Phone Format Mismatch**: Ensure phone normalization is working
2. **Verification Not Found**: Check if phone exists in correct table
3. **User Not Found**: Verify user ID is correct UUID format

### Debug Commands
```javascript
// Check user phone verification status
SELECT u.phone, u.phone_verified, upn.phone_number, upn.is_verified
FROM users u
LEFT JOIN user_phone_numbers upn ON u.id = upn.user_id
WHERE u.id = 'user-uuid';

// Check verification table status
SELECT phone_verified, email_verified FROM business_verifications WHERE user_id = 'user-uuid';
SELECT phone_verified, email_verified FROM driver_verifications WHERE user_id = 'user-uuid';
```

## Conclusion
The unified phone verification system provides a robust, flexible, and user-friendly approach to phone verification across different verification types. It reduces user friction while maintaining verification integrity and provides clear separation between personal and professional contact information.
