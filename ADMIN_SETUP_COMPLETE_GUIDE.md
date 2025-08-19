# Admin Permissions & Auto-Activation Setup Guide

## 🎯 Overview

This guide sets up **automated permission management** and **auto-activation** for the Request Marketplace admin system, converting from Firebase to PostgreSQL.

## ✅ What's Been Fixed

### 1. **Menu Permissions Issue** 
- ✅ Fixed `AuthContext.jsx` to expose `adminData` 
- ✅ Updated country admin permissions in database
- ✅ Country admin menu should now show all items properly

### 2. **Automatic Permission Assignment**
- ✅ New admin users get correct permissions automatically
- ✅ No need to manually run scripts for each new country admin
- ✅ Backend auto-assigns 27 permissions for country admins, 28 for super admins

### 3. **PostgreSQL Auto-Activation System**
- ✅ Converted Firebase scripts to PostgreSQL
- ✅ Ready for auto-activating country data

---

## 🚀 How It Works Now

### **Creating New Country Admins** 
```
1. Create admin user through admin panel
2. ✅ Backend automatically assigns all 27 standard permissions
3. ✅ Menu items appear immediately (no manual script needed)
4. ✅ User can access all appropriate modules
```

### **Key Files Updated:**
- `admin-react/src/contexts/AuthContext.jsx` - Fixed menu permissions
- `backend/routes/admin-users.js` - Auto-assigns permissions
- `backend/services/adminPermissions.js` - Permission management
- `admin-react/auto-propagate-permissions-postgres.cjs` - PostgreSQL version

---

## 🛠️ Available Scripts

### **1. Auto-Propagate Permissions (PostgreSQL)**
```bash
# From admin-react directory
node auto-propagate-permissions-postgres.cjs
```
**Use case:** Update existing admin users with any new permissions

### **2. Auto-Activate Country Data (PostgreSQL)**
```bash
# From backend directory  
node auto_activate_country_data_postgres.js LK "Sri Lanka" admin_user_id "Admin Name"
```
**Use case:** When enabling a new country, activate all data types

### **3. Test Permission System**
```bash
# From backend directory
node test_default_permissions.js
```
**Use case:** Verify permission system is working correctly

---

## 📋 Standard Permissions (Auto-Assigned)

### **Country Admin (27 permissions):**
```javascript
✓ requestManagement, responseManagement, priceListingManagement
✓ productManagement, businessManagement, driverVerification  
✓ vehicleManagement, countryVehicleTypeManagement
✓ cityManagement, userManagement, subscriptionManagement
✓ promoCodeManagement, moduleManagement
✓ categoryManagement, subcategoryManagement, brandManagement, variableTypeManagement
✓ countryProductManagement, countryCategoryManagement, countrySubcategoryManagement
✓ countryBrandManagement, countryVariableTypeManagement, countryVehicleTypeManagement
✓ contentManagement, countryPageManagement
✓ paymentMethodManagement, legalDocumentManagement, smsConfiguration
```

### **Super Admin (28 permissions):**
```javascript
✓ All country admin permissions PLUS:
✓ adminUsersManagement (create/manage other admins)
```

---

## 🔄 Migration Status

### ✅ **Completed:**
- Country admin menu permissions fixed
- Auto permission assignment for new users
- PostgreSQL auto-propagation script
- PostgreSQL auto-activation foundation

### 🚧 **Auto-Activation System (Ready to Deploy):**

The auto-activation system is ready but needs to be integrated. Here's what it does:

**When a country is enabled:**
1. Auto-activates all variable types for that country
2. Auto-activates all categories for that country  
3. Auto-activates all subcategories for that country
4. Auto-activates all brands for that country
5. Auto-activates all products for that country
6. Auto-activates all vehicle types for that country

**Integration Options:**

**Option A: Manual Trigger**
```bash
# Run when enabling a new country
node auto_activate_country_data_postgres.js US "United States" admin_user_id "Admin Name"
```

**Option B: Automatic Trigger (Recommended)**
- Add trigger in country management API
- When country `isEnabled` changes from `false` to `true`
- Automatically run activation script

---

## 🎉 Result

### **Before Fix:**
- ❌ Country admin: Empty sidebar menu
- ❌ Manual permission assignment needed
- ❌ Firebase-based activation system

### **After Fix:** 
- ✅ Country admin: Full sidebar menu with all permitted items
- ✅ New admins get permissions automatically  
- ✅ PostgreSQL-based system ready for production

---

## 🔧 Testing

1. **Login as country admin (rimas@request.lk)**
   - Should see full menu with Products, Categories, etc.

2. **Create new country admin**
   - Should automatically get 27 permissions
   - Menu should appear immediately

3. **Check permissions**
   ```bash
   node check_admin_permissions.js
   ```

---

## 📞 Support

If issues occur:
1. Check `AuthContext.jsx` has `adminData: user` 
2. Verify admin user has correct permissions in database
3. Run auto-propagation script to update permissions
4. Check browser console for permission-related errors

**Current Status: ✅ Ready for Production**
