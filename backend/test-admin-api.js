// Test the admin business-verifications API endpoint
const axios = require('axios');

async function testAdminAPI() {
  try {
    console.log('🔄 Testing admin business-verifications API...');
    
    // Call the same endpoint that admin panel calls
    const response = await axios.get('http://localhost:3001/api/business-verifications', {
      headers: {
        'Content-Type': 'application/json'
        // Note: We're not including auth header for this test
      }
    });

    console.log('✅ API Response Status:', response.status);
    console.log('📊 API Response Structure:');
    console.log('  success:', response.data.success);
    console.log('  count:', response.data.count);
    console.log('  data array length:', response.data.data ? response.data.data.length : 'No data array');
    
    if (response.data.data && response.data.data.length > 0) {
      const firstBusiness = response.data.data[0];
      console.log('\n=== First Business Record (Admin API Response) ===');
      console.log('Business ID:', firstBusiness.id);
      console.log('Business Name:', firstBusiness.businessName || firstBusiness.business_name);
      console.log('Status:', firstBusiness.status);
      
      console.log('\n=== Document URL Fields (Expected by Admin Panel) ===');
      console.log('businessLicenseUrl:', firstBusiness.businessLicenseUrl);
      console.log('taxCertificateUrl:', firstBusiness.taxCertificateUrl);
      console.log('insuranceDocumentUrl:', firstBusiness.insuranceDocumentUrl);
      console.log('businessLogoUrl:', firstBusiness.businessLogoUrl);
      
      console.log('\n=== Raw Database Fields (Backup) ===');
      console.log('business_license_url:', firstBusiness.business_license_url);
      console.log('tax_certificate_url:', firstBusiness.tax_certificate_url);
      console.log('insurance_document_url:', firstBusiness.insurance_document_url);
      console.log('business_logo_url:', firstBusiness.business_logo_url);
      
      // Test if URLs are accessible
      console.log('\n=== URL Accessibility Test ===');
      const urlsToTest = [
        { name: 'businessLicenseUrl', url: firstBusiness.businessLicenseUrl },
        { name: 'taxCertificateUrl', url: firstBusiness.taxCertificateUrl },
        { name: 'insuranceDocumentUrl', url: firstBusiness.insuranceDocumentUrl },
        { name: 'businessLogoUrl', url: firstBusiness.businessLogoUrl }
      ];
      
      for (const { name, url } of urlsToTest) {
        if (url) {
          try {
            const urlResponse = await axios.head(url, { timeout: 5000 });
            console.log(`✅ ${name}: Accessible (${urlResponse.status})`);
          } catch (error) {
            console.log(`❌ ${name}: Not accessible (${error.message})`);
          }
        } else {
          console.log(`⚠️ ${name}: No URL provided`);
        }
      }
    }
    
  } catch (error) {
    console.error('❌ Error testing admin API:', error.message);
    if (error.response) {
      console.error('Response Status:', error.response.status);
      console.error('Response Data:', error.response.data);
    }
  }
}

testAdminAPI();
