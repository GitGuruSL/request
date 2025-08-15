const { initializeApp } = require('firebase/app');
const { getFirestore, collection, addDoc, serverTimestamp } = require('firebase/firestore');

// Firebase config - replace with your actual config
const firebaseConfig = {
  apiKey: "AIzaSyD2iZWGJhKf4FHp8CU2LS92mCzHTVJW9sY",
  authDomain: "request-marketplace.firebaseapp.com",
  projectId: "request-marketplace",
  storageBucket: "request-marketplace.firebasestorage.app",
  messagingSenderId: "747327994851",
  appId: "1:747327994851:web:af5b3a8e9c57cf7df5b00a"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// Sample pages data
const samplePages = [
  // Global pages
  {
    title: 'Privacy Policy',
    slug: 'privacy-policy',
    category: 'Legal',
    type: 'centralized',
    targetCountry: null,
    content: `
      <h1>Privacy Policy</h1>
      <p>Last updated: January 2025</p>
      
      <h2>Information We Collect</h2>
      <p>We collect information you provide directly to us, such as when you:</p>
      <ul>
        <li>Create an account</li>
        <li>Make a request</li>
        <li>Contact us for support</li>
        <li>Subscribe to our newsletters</li>
      </ul>
      
      <h2>How We Use Your Information</h2>
      <p>We use the information we collect to:</p>
      <ul>
        <li>Provide, maintain, and improve our services</li>
        <li>Process transactions</li>
        <li>Send you technical notices and support messages</li>
        <li>Communicate with you about products and services</li>
      </ul>
      
      <h2>Information Sharing</h2>
      <p>We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy.</p>
      
      <h2>Contact Us</h2>
      <p>If you have any questions about this Privacy Policy, please contact us at privacy@requestmarketplace.com</p>
    `,
    status: 'published',
    displayOrder: 1,
    metadata: {
      lastReviewed: '2025-01-01',
      version: '1.0'
    }
  },
  {
    title: 'Terms of Service',
    slug: 'terms-of-service',
    category: 'Legal',
    type: 'centralized',
    targetCountry: null,
    content: `
      <h1>Terms of Service</h1>
      <p>Last updated: January 2025</p>
      
      <h2>Acceptance of Terms</h2>
      <p>By using Request Marketplace, you agree to be bound by these Terms of Service.</p>
      
      <h2>Description of Service</h2>
      <p>Request Marketplace is a platform that connects users who need services with service providers who can fulfill those requests.</p>
      
      <h2>User Accounts</h2>
      <p>To access certain features, you must register for an account. You are responsible for:</p>
      <ul>
        <li>Maintaining the security of your account</li>
        <li>All activities under your account</li>
        <li>Providing accurate information</li>
      </ul>
      
      <h2>Prohibited Activities</h2>
      <p>Users may not:</p>
      <ul>
        <li>Use the service for illegal activities</li>
        <li>Post false or misleading information</li>
        <li>Spam or harass other users</li>
        <li>Attempt to gain unauthorized access</li>
      </ul>
      
      <h2>Contact Information</h2>
      <p>For questions about these terms, contact legal@requestmarketplace.com</p>
    `,
    status: 'published',
    displayOrder: 2,
    metadata: {
      lastReviewed: '2025-01-01',
      version: '1.0'
    }
  },
  {
    title: 'Help & Support',
    slug: 'help-support',
    category: 'Support',
    type: 'centralized',
    targetCountry: null,
    content: `
      <h1>Help & Support</h1>
      
      <h2>Getting Started</h2>
      <p>Welcome to Request Marketplace! Here's how to get started:</p>
      <ol>
        <li><strong>Create an Account:</strong> Sign up with your phone number or email</li>
        <li><strong>Verify Your Identity:</strong> Complete profile verification for better trust</li>
        <li><strong>Create a Request:</strong> Describe what you need and set your budget</li>
        <li><strong>Review Offers:</strong> Service providers will send you quotes</li>
        <li><strong>Choose & Connect:</strong> Select the best offer and connect with the provider</li>
      </ol>
      
      <h2>Frequently Asked Questions</h2>
      
      <h3>How do I create a request?</h3>
      <p>Tap the '+' button on the home screen, select your request type, fill in the details, and publish your request.</p>
      
      <h3>How do I verify my account?</h3>
      <p>Go to your profile and follow the verification process. This helps build trust with other users.</p>
      
      <h3>Is there a fee to use the platform?</h3>
      <p>Creating requests is free. Service providers may include platform fees in their quotes.</p>
      
      <h3>How do I report a problem?</h3>
      <p>Use the report button on any request or profile, or contact our support team directly.</p>
      
      <h2>Contact Support</h2>
      <p>Need more help? Contact us:</p>
      <ul>
        <li>Email: support@requestmarketplace.com</li>
        <li>Phone: Available in app settings</li>
        <li>Live Chat: Available 9 AM - 6 PM local time</li>
      </ul>
    `,
    status: 'published',
    displayOrder: 3,
    metadata: {
      supportEmail: 'support@requestmarketplace.com'
    }
  },
  {
    title: 'Community Guidelines',
    slug: 'community-guidelines',
    category: 'Support',
    type: 'centralized',
    targetCountry: null,
    content: `
      <h1>Community Guidelines</h1>
      
      <h2>Our Mission</h2>
      <p>Request Marketplace connects people and helps communities thrive by facilitating safe, reliable service exchanges.</p>
      
      <h2>What We Expect</h2>
      
      <h3>Be Respectful</h3>
      <ul>
        <li>Treat everyone with courtesy and respect</li>
        <li>Use appropriate language</li>
        <li>Respect cultural differences</li>
      </ul>
      
      <h3>Be Honest</h3>
      <ul>
        <li>Provide accurate information in requests</li>
        <li>Be transparent about pricing and terms</li>
        <li>Honor your commitments</li>
      </ul>
      
      <h3>Be Safe</h3>
      <ul>
        <li>Verify service provider credentials</li>
        <li>Meet in safe, public locations when appropriate</li>
        <li>Report suspicious activity</li>
      </ul>
      
      <h2>What's Not Allowed</h2>
      <ul>
        <li>Illegal activities or services</li>
        <li>Harassment or discriminatory behavior</li>
        <li>Spam or misleading content</li>
        <li>Sharing personal contact information publicly</li>
      </ul>
      
      <h2>Reporting</h2>
      <p>Help us maintain a safe community by reporting violations. We review all reports promptly and take appropriate action.</p>
    `,
    status: 'published',
    displayOrder: 4
  },
  
  // Sri Lanka specific pages
  {
    title: 'Local Services Guide - Sri Lanka',
    slug: 'local-services-guide-lk',
    category: 'Guide',
    type: 'country_specific',
    targetCountry: 'LK',
    content: `
      <h1>Local Services Guide - Sri Lanka</h1>
      
      <h2>Popular Services in Sri Lanka</h2>
      
      <h3>Transportation</h3>
      <ul>
        <li><strong>Three-wheeler (Tuk-tuk):</strong> Quick rides for short distances</li>
        <li><strong>Car rentals:</strong> Daily and weekly rentals available</li>
        <li><strong>Intercity buses:</strong> Affordable travel between cities</li>
        <li><strong>Train services:</strong> Scenic routes available</li>
      </ul>
      
      <h3>Home Services</h3>
      <ul>
        <li><strong>House cleaning:</strong> Professional domestic help</li>
        <li><strong>Plumbing:</strong> Licensed plumbers available</li>
        <li><strong>Electrical work:</strong> Certified electricians</li>
        <li><strong>Carpentry:</strong> Furniture and repair services</li>
      </ul>
      
      <h3>Food & Catering</h3>
      <ul>
        <li><strong>Traditional Sri Lankan cuisine</strong></li>
        <li><strong>Wedding catering</strong></li>
        <li><strong>Home food delivery</strong></li>
        <li><strong>Event catering</strong></li>
      </ul>
      
      <h2>Local Tips</h2>
      <p><strong>Payment:</strong> Cash is widely accepted. Digital payments are growing in urban areas.</p>
      <p><strong>Language:</strong> Services available in Sinhala, Tamil, and English.</p>
      <p><strong>Timing:</strong> Most services operate 8 AM - 6 PM. Emergency services available 24/7.</p>
      
      <h2>Emergency Contacts</h2>
      <ul>
        <li>Police: 119</li>
        <li>Fire & Ambulance: 110</li>
        <li>Tourist Hotline: 1912</li>
      </ul>
    `,
    status: 'published',
    displayOrder: 1,
    metadata: {
      localizedFor: 'LK',
      lastUpdated: '2025-01-01'
    }
  },
  {
    title: 'Pricing Guide - Sri Lanka',
    slug: 'pricing-guide-lk',
    category: 'Guide',
    type: 'country_specific',
    targetCountry: 'LK',
    content: `
      <h1>Pricing Guide - Sri Lanka</h1>
      <p><em>All prices are approximate and in Sri Lankan Rupees (LKR)</em></p>
      
      <h2>Transportation</h2>
      <ul>
        <li>Three-wheeler (per km): LKR 50-80</li>
        <li>Car rental (per day): LKR 8,000-15,000</li>
        <li>Motorcycle taxi: LKR 30-50 per km</li>
      </ul>
      
      <h2>Home Services</h2>
      <ul>
        <li>House cleaning (per hour): LKR 500-800</li>
        <li>Plumber (per hour): LKR 1,500-3,000</li>
        <li>Electrician (per hour): LKR 2,000-4,000</li>
        <li>Carpenter (per day): LKR 3,000-6,000</li>
      </ul>
      
      <h2>Professional Services</h2>
      <ul>
        <li>Tutoring (per hour): LKR 1,000-3,000</li>
        <li>Photography (per event): LKR 15,000-50,000</li>
        <li>Web design: LKR 25,000-100,000</li>
        <li>Legal consultation: LKR 5,000-10,000</li>
      </ul>
      
      <h2>Food & Catering</h2>
      <ul>
        <li>Home cooking (per meal): LKR 200-500</li>
        <li>Event catering (per person): LKR 800-2,000</li>
        <li>Wedding catering (per person): LKR 1,500-5,000</li>
      </ul>
      
      <p><strong>Note:</strong> Prices vary by location, quality, and complexity. Urban areas typically have higher rates than rural areas.</p>
    `,
    status: 'published',
    displayOrder: 2,
    metadata: {
      currency: 'LKR',
      lastUpdated: '2025-01-01'
    }
  },
  {
    title: 'Safety Guidelines - Sri Lanka',
    slug: 'safety-guidelines-lk',
    category: 'Safety',
    type: 'country_specific',
    targetCountry: 'LK',
    content: `
      <h1>Safety Guidelines - Sri Lanka</h1>
      
      <h2>General Safety Tips</h2>
      
      <h3>Meeting Service Providers</h3>
      <ul>
        <li>Meet in public places when possible</li>
        <li>Inform family/friends about your appointments</li>
        <li>Verify provider credentials and reviews</li>
        <li>Trust your instincts</li>
      </ul>
      
      <h3>Payment Safety</h3>
      <ul>
        <li>Avoid large advance payments</li>
        <li>Use platform's secure payment methods when available</li>
        <li>Get receipts for all transactions</li>
        <li>Report payment disputes immediately</li>
      </ul>
      
      <h2>Location-Specific Advice</h2>
      
      <h3>Colombo</h3>
      <p>High-traffic areas like Galle Face and Pettah are generally safe during daytime. Use registered taxi services.</p>
      
      <h3>Kandy</h3>
      <p>Temple areas are very safe. Be cautious during Perahera festival due to crowds.</p>
      
      <h3>Galle</h3>
      <p>Fort area is tourist-friendly. Beach areas are safe but avoid isolated spots after dark.</p>
      
      <h2>Emergency Resources</h2>
      <ul>
        <li><strong>Police:</strong> 119 or 118</li>
        <li><strong>Fire & Ambulance:</strong> 110</li>
        <li><strong>Tourist Police:</strong> +94 11 2421451</li>
        <li><strong>Women's Helpline:</strong> 1938</li>
      </ul>
      
      <h2>Reporting on Platform</h2>
      <p>If you encounter any safety issues while using our platform:</p>
      <ol>
        <li>Report immediately using the in-app report feature</li>
        <li>Contact local authorities if necessary</li>
        <li>Save all communication records</li>
        <li>Contact our support team for assistance</li>
      </ol>
    `,
    status: 'published',
    displayOrder: 3,
    metadata: {
      localEmergency: '119',
      touristHelpline: '1912'
    }
  }
];

async function addSamplePages() {
  try {
    console.log('🔥 Adding sample content pages...');
    
    for (const pageData of samplePages) {
      await addDoc(collection(db, 'content_pages'), {
        ...pageData,
        createdAt: serverTimestamp(),
        updatedAt: serverTimestamp(),
        createdBy: 'system',
        updatedBy: 'system'
      });
      console.log(`✅ Added: ${pageData.title}`);
    }
    
    console.log(`\n🎉 Successfully added ${samplePages.length} sample pages!`);
    console.log('\nPages added:');
    samplePages.forEach((page, index) => {
      console.log(`${index + 1}. ${page.title} (${page.type}${page.targetCountry ? ' - ' + page.targetCountry : ''})`);
    });
    
  } catch (error) {
    console.error('❌ Error adding pages:', error);
  }
}

// Run the script
addSamplePages();
