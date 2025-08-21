import React, { createContext, useContext } from 'react';
import { AuthContext } from './AuthContext';

/**
 * Country Filter Context - Provides centralized country filtering
 */
export const CountryFilterContext = createContext();

/**
 * Country Filter Provider - Wraps the app to provide country filtering
 */
export const CountryFilterProvider = ({ children }) => {
  const { adminData } = useContext(AuthContext);

  const isSuperAdmin = adminData?.role === 'super_admin';
  const isCountryAdmin = adminData?.role === 'country_admin';
  const userCountry = adminData?.country;

  const value = {
    adminData,
    isSuperAdmin,
    isCountryAdmin,
    userCountry
  };

  return (
    <CountryFilterContext.Provider value={value}>
      {children}
    </CountryFilterContext.Provider>
  );
};
