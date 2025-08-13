import { 
  signInWithEmailAndPassword, 
  signOut, 
  onAuthStateChanged,
  createUserWithEmailAndPassword 
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
    
    // Create admin document
    await setDoc(doc(db, 'admin_users', user.uid), {
      name: adminData.name,
      email: adminData.email,
      role: adminData.role,
      country: adminData.country,
      isActive: true,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp()
    });
    
    return user;
  } catch (error) {
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
