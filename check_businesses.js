const admin = require('firebase-admin');
const serviceAccount = require('./request-marketplace-firebase-adminsdk-ztwzx-0a73dc4cb9.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkBusinesses() {
  try {
    const snapshot = await db.collection('new_business_verifications').get();
    console.log('Total businesses:', snapshot.size);
    
    snapshot.forEach(doc => {
      const data = doc.data();
      console.log('\n--- Business ID:', doc.id, '---');
      console.log('Business Name:', data.businessName);
      console.log('Country:', data.country || 'MISSING');
      console.log('Status:', data.status);
      console.log('Has Documents:', {
        license: !!data.businessLicenseUrl,
        tax: !!data.taxCertificateUrl,
        insurance: !!data.insuranceDocumentUrl,
        logo: !!data.businessLogoUrl
      });
      console.log('Document Statuses:', {
        licenseStatus: data.businessLicenseStatus,
        taxStatus: data.taxCertificateStatus,
        insuranceStatus: data.insuranceDocumentStatus,
        logoStatus: data.businessLogoStatus
      });
    });
  } catch (error) {
    console.error('Error:', error);
  }
  process.exit(0);
}

checkBusinesses();
