import React, { createContext, useContext, useEffect, useState } from 'react';
import { onAdminAuthStateChanged, signOutAdmin } from '../firebase/auth';

const AuthContext = createContext();

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [adminData, setAdminData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAdminAuthStateChanged(({ user, adminData }) => {
      console.log('AuthContext - Auth State Changed:');
      console.log('User:', user);
      console.log('AdminData:', adminData);
      console.log('Role:', adminData?.role);
      console.log('Country:', adminData?.country);
      
      setUser(user);
      setAdminData(adminData);
      setLoading(false);
    });

    return unsubscribe;
  }, []);

  const logout = async () => {
    try {
      console.log('🚪 Starting logout process...');
      await signOutAdmin();
      console.log('✅ SignOut successful, clearing state...');
      setUser(null);
      setAdminData(null);
      console.log('✅ Logout completed successfully');
    } catch (error) {
      console.error('❌ Logout error in context:', error);
      // Even if signOut fails, clear the local state
      setUser(null);
      setAdminData(null);
      throw error;
    }
  };

  const value = {
    user,
    adminData,
    loading,
    logout,
    isAuthenticated: !!user && !!adminData,
    isSuperAdmin: adminData?.role === 'super_admin',
    isCountryAdmin: adminData?.role === 'country_admin',
    // Backward compatibility
    userRole: adminData?.role,
    userCountry: adminData?.country
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};
