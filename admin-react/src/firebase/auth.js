import { 
  signInWithEmailAndPassword, 
  signOut, 
  onAuthStateChanged,
  createUserWithEmailAndPassword,
  updatePassword,
  reauthenticateWithCredential,
  EmailAuthProvider
} from 'firebase/auth';
import { 
  doc, 
  getDoc, 
  setDoc, 
  serverTimestamp,
  collection,
  query,
  where,
  getDocs 
} from 'firebase/firestore';
import { auth, db } from './config';

// Admin user roles
export const ROLES = {
  SUPER_ADMIN: 'super_admin',
  COUNTRY_ADMIN: 'country_admin'
};

// Sign in admin user
export const signInAdmin = async (email, password) => {
  try {
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    const user = userCredential.user;
    
    // Check if user is an admin
    const adminDoc = await getDoc(doc(db, 'admin_users', user.uid));
    if (!adminDoc.exists()) {
      await signOut(auth);
      throw new Error('You are not authorized to access the admin panel');
    }
    
    const adminData = { id: adminDoc.id, ...adminDoc.data() };
    
    // Check if admin is active
    if (!adminData.isActive) {
      await signOut(auth);
      throw new Error('Your admin account has been deactivated');
    }
    
    return {
      user,
      adminData
    };
  } catch (error) {
    throw error;
  }
};

// Sign out
export const signOutAdmin = async () => {
  try {
    await signOut(auth);
  } catch (error) {
    throw error;
  }
};

// Create admin user (only for super admin)
export const createAdminUser = async (adminData) => {
  try {
    const userCredential = await createUserWithEmailAndPassword(
      auth, 
      adminData.email, 
      adminData.password
    );
    const user = userCredential.user;
    
    // Create admin document with proper field mapping
    await setDoc(doc(db, 'admin_users', user.uid), {
      displayName: adminData.displayName,
      email: adminData.email,
      role: adminData.role,
      country: adminData.country,
      isActive: adminData.isActive !== undefined ? adminData.isActive : true,
      permissions: adminData.permissions || {
        paymentMethods: true,
        legalDocuments: true,
        businessManagement: true,
        driverManagement: true,
        adminUsersManagement: adminData.role === 'super_admin' // Give admin users permission only to super admins by default
      },
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
      uid: user.uid
    });
    
    return user;
  } catch (error) {
    console.error('Error in createAdminUser:', error);
    throw error;
  }
};

// Get admin user data
export const getAdminUser = async (uid) => {
  try {
    const adminDoc = await getDoc(doc(db, 'admin_users', uid));
    if (adminDoc.exists()) {
      return { id: adminDoc.id, ...adminDoc.data() };
    }
    return null;
  } catch (error) {
    throw error;
  }
};

// Auth state listener
export const onAdminAuthStateChanged = (callback) => {
  return onAuthStateChanged(auth, async (user) => {
    if (user) {
      try {
        const adminData = await getAdminUser(user.uid);
        callback({ user, adminData });
      } catch (error) {
        console.error('Error getting admin data:', error);
        callback({ user: null, adminData: null });
      }
    } else {
      callback({ user: null, adminData: null });
    }
  });
};

// Get country-specific data (for country admins)
export const getCountryFilteredQuery = (baseQuery, adminData) => {
  if (adminData.role === ROLES.SUPER_ADMIN) {
    return baseQuery; // Super admin sees all data
  }
  
  // Country admin only sees their country's data
  return query(baseQuery, where('country', '==', adminData.country));
};

// Update user password
export const updateUserPassword = async (currentPassword, newPassword) => {
  try {
    const user = auth.currentUser;
    if (!user || !user.email) {
      throw new Error('No authenticated user found');
    }

    // Re-authenticate the user with their current password
    const credential = EmailAuthProvider.credential(user.email, currentPassword);
    await reauthenticateWithCredential(user, credential);

    // Update to new password
    await updatePassword(user, newPassword);
    
    return { success: true };
  } catch (error) {
    let errorMessage = 'Failed to update password';
    
    if (error.code === 'auth/wrong-password') {
      errorMessage = 'Current password is incorrect';
    } else if (error.code === 'auth/weak-password') {
      errorMessage = 'New password is too weak';
    } else if (error.code === 'auth/too-many-requests') {
      errorMessage = 'Too many attempts. Please try again later';
    }
    
    throw new Error(errorMessage);
  }
};
