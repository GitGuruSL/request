import React, { createContext, useContext, useEffect, useState } from 'react';
import { onAdminAuthStateChanged } from '../firebase/auth';

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
      setUser(user);
      setAdminData(adminData);
      setLoading(false);
    });

    return unsubscribe;
  }, []);

  const value = {
    user,
    adminData,
    loading,
    isAuthenticated: !!user && !!adminData,
    isSuperAdmin: adminData?.role === 'super_admin',
    isCountryAdmin: adminData?.role === 'country_admin'
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};
