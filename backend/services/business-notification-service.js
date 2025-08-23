const database = require('./database');

class BusinessNotificationService {
  /**
   * Find businesses that should be notified for a specific request
   * @param {string} requestId - The request ID
   * @param {string} categoryId - The category ID of the request
   * @param {string} subcategoryId - The subcategory ID of the request (optional)
   * @param {string} requestType - The type of request (item, service, ride, etc.)
   * @param {string} countryCode - The country code for the request
   * @returns {Array} Array of business user IDs to notify
   */
  static async getBusinessesToNotify(requestId, categoryId, subcategoryId, requestType, countryCode) {
    try {
      console.log(`🔍 Finding businesses to notify for request ${requestId}`);
      console.log(`   Category: ${categoryId}, Subcategory: ${subcategoryId}`);
      console.log(`   Request Type: ${requestType}, Country: ${countryCode}`);

      // For delivery requests, find delivery service businesses
      if (requestType === 'delivery') {
        return await this.getDeliveryBusinesses(countryCode);
      }

      // For other requests, find businesses in matching categories
      return await this.getCategoryMatchingBusinesses(categoryId, subcategoryId, countryCode);

    } catch (error) {
      console.error('Error finding businesses to notify:', error);
      return [];
    }
  }

  /**
   * Get delivery service businesses
   */
  static async getDeliveryBusinesses(countryCode) {
    const query = `
      SELECT DISTINCT bv.user_id, bv.business_name, bv.business_email
      FROM business_verifications bv
      WHERE bv.is_verified = true
        AND bv.status = 'approved'
        AND (bv.business_type = 'delivery_service' OR bv.business_type = 'both')
        AND bv.country = $1
      ORDER BY bv.business_name
    `;

    const result = await database.query(query, [countryCode]);
    console.log(`📦 Found ${result.rows.length} delivery businesses in ${countryCode}`);
    
    return result.rows.map(row => ({
      userId: row.user_id,
      businessName: row.business_name,
      businessEmail: row.business_email,
      notificationReason: 'delivery_service'
    }));
  }

  /**
   * Get businesses that match specific categories
   */
  static async getCategoryMatchingBusinesses(categoryId, subcategoryId, countryCode) {
    // Build query to find businesses with matching categories
    let query = `
      SELECT DISTINCT bv.user_id, bv.business_name, bv.business_email, bv.categories, bv.business_type
      FROM business_verifications bv
      WHERE bv.is_verified = true
        AND bv.status = 'approved'
        AND (bv.business_type = 'product_selling' OR bv.business_type = 'both')
        AND bv.country = $1
        AND (
          bv.categories @> $2::jsonb
          ${subcategoryId ? 'OR bv.categories @> $3::jsonb' : ''}
        )
      ORDER BY bv.business_name
    `;

    const params = [countryCode, JSON.stringify([categoryId])];
    if (subcategoryId) {
      params.push(JSON.stringify([subcategoryId]));
    }

    const result = await database.query(query, params);
    console.log(`🏪 Found ${result.rows.length} category-matching businesses in ${countryCode}`);
    
    return result.rows.map(row => ({
      userId: row.user_id,
      businessName: row.business_name,
      businessEmail: row.business_email,
      categories: row.categories,
      businessType: row.business_type,
      notificationReason: 'category_match'
    }));
  }

  /**
   * Check if a business can respond to a specific request type
   */
  static async canBusinessRespondToRequest(userId, requestType, categoryId) {
    const query = `
      SELECT business_type, categories, is_verified, status
      FROM business_verifications 
      WHERE user_id = $1 AND is_verified = true AND status = 'approved'
    `;

    const result = await database.query(query, [userId]);
    if (result.rows.length === 0) {
      return { canRespond: false, reason: 'not_verified' };
    }

    const business = result.rows[0];

    // Check business type compatibility
    if (requestType === 'delivery') {
      if (business.business_type === 'delivery_service' || business.business_type === 'both') {
        return { canRespond: true, reason: 'delivery_service_match' };
      }
      return { canRespond: false, reason: 'not_delivery_service' };
    }

    // For product/service requests, check if business sells products and has category match
    if (business.business_type === 'product_selling' || business.business_type === 'both') {
      const categories = business.categories || [];
      if (categories.includes(categoryId)) {
        return { canRespond: true, reason: 'category_match' };
      }
      return { canRespond: false, reason: 'category_mismatch' };
    }

    return { canRespond: false, reason: 'business_type_mismatch' };
  }

  /**
   * Get business access rights (what features they can use)
   */
  static async getBusinessAccessRights(userId) {
    const query = `
      SELECT business_type, categories, is_verified, status
      FROM business_verifications 
      WHERE user_id = $1
    `;

    const result = await database.query(query, [userId]);
    if (result.rows.length === 0) {
      return {
        canAddPrices: false,
        canRespondToDelivery: false,
        canRespondToProducts: false,
        categories: [],
        verified: false
      };
    }

    const business = result.rows[0];
    const isVerified = business.is_verified && business.status === 'approved';

    return {
      canAddPrices: isVerified && (business.business_type === 'product_selling' || business.business_type === 'both'),
      canRespondToDelivery: isVerified && (business.business_type === 'delivery_service' || business.business_type === 'both'),
      canRespondToProducts: isVerified && (business.business_type === 'product_selling' || business.business_type === 'both'),
      categories: business.categories || [],
      businessType: business.business_type,
      verified: isVerified
    };
  }

  /**
   * Update business categories
   */
  static async updateBusinessCategories(userId, categories) {
    const query = `
      UPDATE business_verifications 
      SET categories = $2, updated_at = CURRENT_TIMESTAMP
      WHERE user_id = $1 AND is_verified = true
      RETURNING categories
    `;

    const result = await database.query(query, [userId, JSON.stringify(categories)]);
    return result.rows[0];
  }
}

module.exports = BusinessNotificationService;
