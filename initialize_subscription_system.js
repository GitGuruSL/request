const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./path/to/your/firebase-service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function initializeSubscriptionSystem() {
  console.log('🚀 Initializing Subscription System...');

  try {
    // Initialize subscription plans
    await initializeSubscriptionPlans();
    
    // Initialize sample promo codes (pre-approved for demo)
    await initializeSamplePromoCodes();
    
    // Initialize admin roles and permissions
    await initializeAdminRoles();
    
    console.log('✅ Subscription system initialization complete!');
  } catch (error) {
    console.error('❌ Error initializing subscription system:', error);
  }
}

async function initializeSubscriptionPlans() {
  console.log('📋 Creating subscription plans...');

  const plans = [
    // Rider Plans
    {
      name: 'Rider Premium Monthly',
      description: 'Unlimited ride responses with premium features',
      type: 'rider',
      paymentModel: 'monthly',
      countryPrices: {
        'LK': 500.0,  // Sri Lankan Rupees
        'IN': 150.0,  // Indian Rupees
        'BD': 200.0,  // Bangladeshi Taka
        'PK': 300.0,  // Pakistani Rupees
        'US': 9.99,   // US Dollars
        'GB': 7.99,   // British Pounds
        'AU': 12.99,  // Australian Dollars
        'CA': 12.99,  // Canadian Dollars
      },
      currencySymbols: {
        'LK': 'Rs',
        'IN': '₹',
        'BD': '৳',
        'PK': 'Rs',
        'US': '$',
        'GB': '£',
        'AU': 'A$',
        'CA': 'C$',
      },
      features: [
        'Unlimited ride responses',
        'Real-time notifications',
        'Priority customer support',
        'Advanced ride filters',
        'Ride history tracking',
        'Price comparison tools'
      ],
      limitations: {},
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },

    {
      name: 'Rider Premium Yearly',
      description: 'Annual subscription with 20% discount',
      type: 'rider',
      paymentModel: 'yearly',
      countryPrices: {
        'LK': 4800.0,   // 20% discount
        'IN': 1440.0,
        'BD': 1920.0,
        'PK': 2880.0,
        'US': 95.90,
        'GB': 76.70,
        'AU': 124.70,
        'CA': 124.70,
      },
      currencySymbols: {
        'LK': 'Rs',
        'IN': '₹',
        'BD': '৳',
        'PK': 'Rs',
        'US': '$',
        'GB': '£',
        'AU': 'A$',
        'CA': 'C$',
      },
      features: [
        'Everything in Monthly plan',
        '20% annual discount',
        'Priority feature updates',
        'Extended support hours'
      ],
      limitations: {},
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },

    // Business Plans
    {
      name: 'Business Pay-Per-Click',
      description: 'Pay only when customers interact with your business',
      type: 'business',
      paymentModel: 'payPerClick',
      countryPrices: {
        'LK': 100.0,   // Sri Lankan Rupees per click
        'IN': 30.0,    // Indian Rupees per click
        'BD': 40.0,    // Bangladeshi Taka per click
        'PK': 60.0,    // Pakistani Rupees per click
        'US': 1.99,    // US Dollars per click
        'GB': 1.49,    // British Pounds per click
        'AU': 2.49,    // Australian Dollars per click
        'CA': 2.49,    // Canadian Dollars per click
      },
      currencySymbols: {
        'LK': 'Rs',
        'IN': '₹',
        'BD': '৳',
        'PK': 'Rs',
        'US': '$',
        'GB': '£',
        'AU': 'A$',
        'CA': 'C$',
      },
      features: [
        'Pay only for actual customer interactions',
        'Detailed click analytics',
        'Business performance dashboard',
        'Customer inquiry management',
        'Response time tracking',
        'Monthly usage reports'
      ],
      limitations: {},
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },

    {
      name: 'Business Premium Monthly',
      description: 'Fixed monthly fee with unlimited interactions',
      type: 'business',
      paymentModel: 'monthly',
      countryPrices: {
        'LK': 2500.0,  // Sri Lankan Rupees
        'IN': 750.0,   // Indian Rupees
        'BD': 1000.0,  // Bangladeshi Taka
        'PK': 1500.0,  // Pakistani Rupees
        'US': 49.99,   // US Dollars
        'GB': 39.99,   // British Pounds
        'AU': 64.99,   // Australian Dollars
        'CA': 64.99,   // Canadian Dollars
      },
      currencySymbols: {
        'LK': 'Rs',
        'IN': '₹',
        'BD': '৳',
        'PK': 'Rs',
        'US': '$',
        'GB': '£',
        'AU': 'A$',
        'CA': 'C$',
      },
      features: [
        'Unlimited customer interactions',
        'Advanced analytics dashboard',
        'Priority listing in search results',
        'Custom business profile features',
        'Dedicated account manager',
        'API access for integrations'
      ],
      limitations: {},
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }
  ];

  // Create each plan
  for (const plan of plans) {
    await db.collection('subscription_plans').add(plan);
    console.log(`✅ Created plan: ${plan.name}`);
  }
}

async function initializeSamplePromoCodes() {
  console.log('🎫 Creating sample promo codes...');

  const promoCodes = [
    // Welcome bonus for new users
    {
      code: 'WELCOME2025',
      title: 'New User Welcome Bonus',
      description: 'Get 1 extra month free trial for new users',
      type: 'freeTrialExtension',
      status: 'active', // Pre-approved for demo
      value: 30, // 30 extra days
      validFrom: admin.firestore.Timestamp.now(),
      validTo: admin.firestore.Timestamp.fromDate(new Date('2025-12-31')),
      maxUses: 1000,
      currentUses: 0,
      applicableUserTypes: ['rider', 'business', 'driver'],
      applicableCountries: [], // Empty means all countries
      conditions: {},
      createdBy: 'system', // System generated
      approvedBy: 'system',
      approvedAt: admin.firestore.Timestamp.now(),
      rejectionReason: null,
      createdByCountry: 'GLOBAL',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },

    // Percentage discount for riders
    {
      code: 'RIDER50',
      title: '50% Off First Month',
      description: 'Get 50% discount on your first monthly subscription',
      type: 'percentageDiscount',
      status: 'active',
      value: 50, // 50% discount
      validFrom: admin.firestore.Timestamp.now(),
      validTo: admin.firestore.Timestamp.fromDate(new Date('2025-06-30')),
      maxUses: 500,
      currentUses: 0,
      applicableUserTypes: ['rider'],
      applicableCountries: [], 
      conditions: {
        applicableToPlans: ['monthly'],
        firstTimeSubscribersOnly: true
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },

    // Business free clicks
    {
      code: 'BIZSTART100',
      title: 'Business Starter Pack',
      description: 'Get 100 free clicks after trial period',
      type: 'businessFreeClicks',
      status: 'active',
      value: 100, // 100 free clicks
      validFrom: admin.firestore.Timestamp.now(),
      validTo: admin.firestore.Timestamp.fromDate(new Date('2025-09-30')),
      maxUses: 200,
      currentUses: 0,
      applicableUserTypes: ['business'],
      applicableCountries: [],
      conditions: {
        validForDays: 60, // Valid for 60 days
        afterTrialOnly: true
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },

    // Sri Lanka specific offer
    {
      code: 'SRILANKA2025',
      title: 'Sri Lanka Special',
      description: 'Fixed 200 LKR discount for Sri Lankan users',
      type: 'fixedDiscount',
      status: 'active',
      value: 200, // 200 LKR discount
      validFrom: admin.firestore.Timestamp.now(),
      validTo: admin.firestore.Timestamp.fromDate(new Date('2025-08-31')),
      maxUses: 300,
      currentUses: 0,
      applicableUserTypes: ['rider', 'business'],
      applicableCountries: ['LK'], // Only Sri Lanka
      conditions: {
        minimumPurchase: 500 // Minimum 500 LKR purchase
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },

    // Unlimited responses for limited time
    {
      code: 'UNLIMITED30',
      title: '30 Days Unlimited',
      description: 'Get 30 days of unlimited ride responses',
      type: 'unlimitedResponses',
      status: 'active',
      value: 30, // 30 days
      validFrom: admin.firestore.Timestamp.now(),
      validTo: admin.firestore.Timestamp.fromDate(new Date('2025-07-15')),
      maxUses: 150,
      currentUses: 0,
      applicableUserTypes: ['rider'],
      applicableCountries: [],
      conditions: {
        expiredSubscriptionRequired: true // Only for users with expired subscriptions
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }
  ];

    // Update all promo codes to include approval workflow fields
    const promoCodeUpdates = promoCodes.map(promo => ({
      ...promo,
      createdBy: 'system',
      approvedBy: 'system',
      approvedAt: admin.firestore.Timestamp.now(),
      rejectionReason: null,
      createdByCountry: promo.applicableCountries.length > 0 ? promo.applicableCountries[0] : 'GLOBAL',
    }));

    // Create each promo code
    for (const promoCode of promoCodeUpdates) {
      await db.collection('promoCodes').add(promoCode);
      console.log(`✅ Created promo code: ${promoCode.code}`);
    }
  }

  async function initializeAdminRoles() {
    console.log('👑 Setting up admin roles and permissions...');

    // Create admin users collection structure (example)
    const adminRoles = [
      {
        uid: 'super_admin_1', // This should be replaced with actual UIDs
        email: 'superadmin@example.com',
        role: 'super_admin',
        countries: [], // Super admin has access to all countries
        permissions: [
          'approve_promo_codes',
          'manage_subscriptions',
          'view_all_analytics',
          'manage_country_admins'
        ],
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        uid: 'country_admin_lk',
        email: 'admin.lk@example.com',
        role: 'country_admin',
        countries: ['LK'], // Sri Lanka admin
        permissions: [
          'create_promo_codes',
          'view_country_analytics',
          'manage_country_subscriptions'
        ],
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {
        uid: 'country_admin_in',
        email: 'admin.in@example.com',
        role: 'country_admin',
        countries: ['IN'], // India admin
        permissions: [
          'create_promo_codes',
          'view_country_analytics',
          'manage_country_subscriptions'
        ],
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }
    ];

    // Create admin users (you'll need to replace UIDs with real ones)
    for (const admin of adminRoles) {
      await db.collection('admin_users').doc(admin.uid).set(admin);
      console.log(`✅ Created admin role: ${admin.role} for ${admin.email}`);
    }
  }// Run the initialization
initializeSubscriptionSystem().then(() => {
  console.log('🎉 All done! You can now use the subscription system.');
  process.exit(0);
}).catch(error => {
  console.error('💥 Initialization failed:', error);
  process.exit(1);
});

// Export for use in other scripts
module.exports = {
  initializeSubscriptionSystem,
  initializeSubscriptionPlans,
  initializeSamplePromoCodes,
  initializeAdminRoles
};
