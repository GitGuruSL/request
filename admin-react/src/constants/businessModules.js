// Business modules configuration
export const BUSINESS_MODULES = {
  ITEM: {
    id: 'item',
    name: 'Item Request',
    description: 'Buy and sell items - electronics, furniture, clothing, etc.',
    icon: '🛍️',
    color: '#FF6B35',
    features: [
      'Product listings',
      'Categories & subcategories',
      'Search & filters',
      'Reviews & ratings',
      'Wishlist',
      'Shopping cart'
    ],
    dependencies: ['payment', 'messaging'],
    defaultEnabled: true
  },
  SERVICE: {
    id: 'service',
    name: 'Service Request',
    description: 'Find and offer services - cleaning, repairs, tutoring, etc.',
    icon: '🔧',
    color: '#4ECDC4',
    features: [
      'Service listings',
      'Professional profiles',
      'Booking system',
      'Time slots',
      'Service areas',
      'Portfolio gallery'
    ],
    dependencies: ['payment', 'messaging', 'location'],
    defaultEnabled: true
  },
  RENT: {
    id: 'rent',
    name: 'Rent Request',
    description: 'Rent items temporarily - tools, equipment, vehicles, etc.',
    icon: '📅',
    color: '#45B7D1',
    features: [
      'Rental duration',
      'Availability calendar',
      'Deposit system',
      'Return conditions',
      'Insurance options',
      'Late fees'
    ],
    dependencies: ['payment', 'messaging', 'location'],
    defaultEnabled: false
  },
  DELIVERY: {
    id: 'delivery',
    name: 'Delivery Request',
    description: 'Package delivery and courier services',
    icon: '📦',
    color: '#96CEB4',
    features: [
      'Pickup & delivery',
      'Package tracking',
      'Delivery zones',
      'Express delivery',
      'Package size/weight',
      'Delivery notes'
    ],
    dependencies: ['payment', 'location', 'driver'],
    defaultEnabled: false
  },
  RIDE: {
    id: 'ride',
    name: 'Ride Sharing',
    description: 'Taxi and ride sharing services',
    icon: '🚗',
    color: '#FFEAA7',
    features: [
      'Ride booking',
      'Driver matching',
      'Route optimization',
      'Fare calculation',
      'Live tracking',
      'Multiple stops'
    ],
    dependencies: ['payment', 'location', 'driver'],
    defaultEnabled: false
  },
  PRICE: {
    id: 'price',
    name: 'Price Request',
    description: 'Compare prices across different sellers/services',
    icon: '💰',
    color: '#DDA0DD',
    features: [
      'Price tracking',
      'Price alerts',
      'Comparison charts',
      'Historical data',
      'Best deals',
      'Price predictions'
    ],
    dependencies: ['payment', 'messaging'],
    defaultEnabled: false
  },
  FOOD_DELIVERY: {
    id: 'food_delivery',
    name: 'Food Delivery',
    description: 'Restaurant food delivery and takeout services',
    icon: '🍔',
    color: '#FF9F43',
    features: [
      'Restaurant listings',
      'Menu management',
      'Order tracking',
      'Delivery zones',
      'Special offers',
      'Customer reviews'
    ],
    dependencies: ['payment', 'location', 'driver'],
    defaultEnabled: false
  },
  GROCERY: {
    id: 'grocery',
    name: 'Grocery Delivery',
    description: 'Grocery and essential items delivery',
    icon: '🛒',
    color: '#10AC84',
    features: [
      'Product catalogs',
      'Store listings',
      'Bulk ordering',
      'Scheduled delivery',
      'Fresh produce',
      'Household items'
    ],
    dependencies: ['payment', 'location', 'driver'],
    defaultEnabled: false
  },
  BEAUTY: {
    id: 'beauty',
    name: 'Beauty & Wellness',
    description: 'Beauty services, salon bookings, and wellness',
    icon: '💄',
    color: '#FF6B9D',
    features: [
      'Salon bookings',
      'Service packages',
      'Beauty professionals',
      'Appointment scheduling',
      'Treatment history',
      'Before/after gallery'
    ],
    dependencies: ['payment', 'messaging', 'location'],
    defaultEnabled: false
  },
  PROFESSIONAL: {
    id: 'professional',
    name: 'Professional Services',
    description: 'Legal, accounting, consulting, and professional services',
    icon: '💼',
    color: '#3742FA',
    features: [
      'Professional profiles',
      'Consultation booking',
      'Document sharing',
      'Secure messaging',
      'Video consultations',
      'Case management'
    ],
    dependencies: ['payment', 'messaging'],
    defaultEnabled: false
  }
};

// Core system dependencies
export const CORE_DEPENDENCIES = {
  payment: 'Payment System',
  messaging: 'In-app Messaging',
  location: 'Location Services',
  driver: 'Driver Management'
};

// Get modules that a specific module depends on
export const getModuleDependencies = (moduleId) => {
  const module = BUSINESS_MODULES[moduleId.toUpperCase()];
  return module ? module.dependencies : [];
};

// Check if all dependencies are met for a module
export const canEnableModule = (moduleId, enabledModules, enabledDependencies) => {
  const dependencies = getModuleDependencies(moduleId);
  
  // Check if all dependencies are enabled
  for (const dep of dependencies) {
    if (BUSINESS_MODULES[dep.toUpperCase()]) {
      // It's a module dependency
      if (!enabledModules.includes(dep)) {
        return { canEnable: false, missing: dep, type: 'module' };
      }
    } else {
      // It's a core dependency
      if (!enabledDependencies.includes(dep)) {
        return { canEnable: false, missing: dep, type: 'core' };
      }
    }
  }
  
  return { canEnable: true };
};

// Get modules that depend on a specific module (reverse dependency check)
export const getModulesUsingDependency = (moduleId) => {
  return Object.keys(BUSINESS_MODULES).filter(key => {
    const module = BUSINESS_MODULES[key];
    return module.dependencies.includes(moduleId);
  });
};
