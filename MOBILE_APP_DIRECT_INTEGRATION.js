// Mobile App Integration - Direct Firestore Approach
// Add this to your React Native/Flutter app

// For React Native (JavaScript/TypeScript)
import { db } from './firebaseConfig'; // Your Firebase config
import { doc, getDoc } from 'firebase/firestore';

/**
 * Get enabled modules for a specific country
 * @param {string} countryCode - Country code (e.g., 'LK', 'US')
 * @returns {Promise<Object>} Country module configuration
 */
export const getCountryModulesFromFirestore = async (countryCode) => {
  try {
    console.log(`🌍 Fetching modules for country: ${countryCode}`);
    
    // Get country module configuration from Firestore
    const countryModuleRef = doc(db, 'country_modules', countryCode.toUpperCase());
    const countryModuleDoc = await getDoc(countryModuleRef);
    
    if (!countryModuleDoc.exists()) {
      console.log(`⚠️ No module config found for ${countryCode}, using defaults`);
      // Return default configuration
      return {
        success: true,
        countryCode: countryCode.toUpperCase(),
        modules: {
          item: true,
          service: true,
          rent: false,
          delivery: false,
          ride: false,
          price: false
        },
        coreDependencies: {
          payment: true,
          messaging: true,
          location: true,
          driver: false
        }
      };
    }
    
    const moduleData = countryModuleDoc.data();
    console.log(`✅ Found module config for ${countryCode}:`, moduleData.modules);
    
    return {
      success: true,
      countryCode: countryCode.toUpperCase(),
      modules: moduleData.modules || {},
      coreDependencies: moduleData.coreDependencies || {},
      lastUpdated: moduleData.updatedAt || null
    };
    
  } catch (error) {
    console.error('❌ Error fetching country modules:', error);
    return {
      success: false,
      error: error.message
    };
  }
};

// Usage in your mobile app component:
import React, { useState, useEffect } from 'react';

const CreateRequestScreen = ({ userCountry = 'LK' }) => {
  const [enabledModules, setEnabledModules] = useState({});
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchModules = async () => {
      try {
        const result = await getCountryModulesFromFirestore(userCountry);
        if (result.success) {
          setEnabledModules(result.modules);
        }
      } catch (error) {
        console.error('Error fetching modules:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchModules();
  }, [userCountry]);

  if (loading) {
    return <LoadingScreen />;
  }

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Create New Request</Text>
      
      {/* Only show enabled modules */}
      {enabledModules.item && (
        <TouchableOpacity style={styles.requestOption}>
          <Icon name="shopping-bag" />
          <Text>Item Request</Text>
          <Text>Request for products or items</Text>
        </TouchableOpacity>
      )}
      
      {enabledModules.service && (
        <TouchableOpacity style={styles.requestOption}>
          <Icon name="wrench" />
          <Text>Service Request</Text>
          <Text>Request for services</Text>
        </TouchableOpacity>
      )}
      
      {enabledModules.delivery && (
        <TouchableOpacity style={styles.requestOption}>
          <Icon name="truck" />
          <Text>Delivery Request</Text>
          <Text>Request for delivery services</Text>
        </TouchableOpacity>
      )}
      
      {enabledModules.rent && (
        <TouchableOpacity style={styles.requestOption}>
          <Icon name="calendar" />
          <Text>Rental Request</Text>
          <Text>Rent vehicles, equipment, or items</Text>
        </TouchableOpacity>
      )}
      
      {enabledModules.ride && (
        <TouchableOpacity style={styles.requestOption}>
          <Icon name="car" />
          <Text>Ride Request</Text>
          <Text>Request for transportation</Text>
        </TouchableOpacity>
      )}
      
      {enabledModules.price && (
        <TouchableOpacity style={styles.requestOption}>
          <Icon name="dollar-sign" />
          <Text>Price Request</Text>
          <Text>Request price quotes for items or services</Text>
        </TouchableOpacity>
      )}
    </View>
  );
};
