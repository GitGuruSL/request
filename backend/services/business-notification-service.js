const database = require('./database');

class BusinessNotificationService {
  /**
   * Find businesses that should be notified for a specific request
   * Updated logic: Most requests are open to all, only delivery is restricted
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

      const type = (requestType || '').toLowerCase();
      const COMMON = ['item','service','tours','events','construction','education','hiring'];

      // For delivery requests, only notify delivery service businesses
      if (type === 'delivery') {
        return await this.getDeliveryBusinesses(countryCode);
      }

      // For ride requests, don't notify businesses (only drivers should respond)
      if (type === 'ride') {
        console.log('🚗 Ride requests only notify drivers, not businesses');
        return [];
      }

      // Price requests: product sellers should respond
      if (type === 'price') {
        return await this.getProductSellerBusinesses(countryCode);
      }

      // Common requests: product sellers and delivery businesses should respond
      if (COMMON.includes(type)) {
        return await this.getBusinessesByTypeNames(countryCode, ['product seller', 'delivery', 'delivery service']);
      }

      // For item/service/rent requests, notify all verified businesses in country
      // (with optional category preference for product sellers)
      return await this.getAllBusinessesWithCategoryPreference(categoryId, subcategoryId, countryCode);

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
      LEFT JOIN business_types bt ON bt.id = bv.business_type_id
      WHERE bv.is_verified = true
        AND bv.status = 'approved'
        AND bv.country = $1
        AND (
          LOWER(COALESCE(bt.name, '')) IN ('delivery service','delivery') OR
          LOWER(COALESCE(bv.business_category, '')) IN ('delivery service','delivery') OR
          bv.business_type = 'delivery_service' OR
          bv.business_type = 'both'
        )
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
   * Get product seller businesses only
   */
  static async getProductSellerBusinesses(countryCode) {
    const query = `
      SELECT DISTINCT bv.user_id, bv.business_name, bv.business_email
      FROM business_verifications bv
      LEFT JOIN business_types bt ON bt.id = bv.business_type_id
      WHERE bv.is_verified = true
        AND bv.status = 'approved'
        AND bv.country = $1
        AND (
          LOWER(COALESCE(bt.name, '')) = 'product seller' OR
          LOWER(COALESCE(bv.business_category, '')) = 'product seller' OR
          bv.business_type = 'product_selling' OR
          bv.business_type = 'both'
        )
      ORDER BY bv.business_name
    `;

    const result = await database.query(query, [countryCode]);
    console.log(`🏷️ Found ${result.rows.length} product seller businesses in ${countryCode}`);
    return result.rows.map(row => ({
      userId: row.user_id,
      businessName: row.business_name,
      businessEmail: row.business_email,
      notificationReason: 'product_seller'
    }));
  }

  /**
   * Get businesses filtered by business type names (supports legacy and joined name)
   */
  static async getBusinessesByTypeNames(countryCode, names = []) {
    const lowered = names.map(n => String(n).toLowerCase());
    const query = `
      SELECT DISTINCT bv.user_id, bv.business_name, bv.business_email
      FROM business_verifications bv
      LEFT JOIN business_types bt ON bt.id = bv.business_type_id
      WHERE bv.is_verified = true
        AND bv.status = 'approved'
        AND bv.country = $1
        AND (
          LOWER(COALESCE(bt.name, '')) = ANY($2)
          OR LOWER(COALESCE(bv.business_category, '')) = ANY($2)
        )
      ORDER BY bv.business_name
    `;
    const result = await database.query(query, [countryCode, lowered]);
    console.log(`🏢 Found ${result.rows.length} businesses by types [${lowered.join(', ')}] in ${countryCode}`);
    return result.rows.map(row => ({
      userId: row.user_id,
      businessName: row.business_name,
      businessEmail: row.business_email,
      notificationReason: 'type_filtered'
    }));
  }

  /**
   * Get all businesses with category preference (for item/service/rent requests)
   * Anyone can respond, but prioritize category matches
   */
  static async getAllBusinessesWithCategoryPreference(categoryId, subcategoryId, countryCode) {
    const query = `
      SELECT DISTINCT bv.user_id, bv.business_name, bv.business_email, bv.categories, bv.business_type,
             CASE 
               WHEN bv.categories @> $2::jsonb THEN 'category_match'
               WHEN bv.categories @> $3::jsonb THEN 'subcategory_match' 
               ELSE 'general_business'
             END as match_priority
      FROM business_verifications bv
      WHERE bv.is_verified = true
        AND bv.status = 'approved'
        AND bv.country = $1
      ORDER BY 
        CASE 
          WHEN bv.categories @> $2::jsonb THEN 1
          WHEN bv.categories @> $3::jsonb THEN 2 
          ELSE 3
        END,
        bv.business_name
    `;

    const params = [
      countryCode, 
      JSON.stringify([categoryId]),
      subcategoryId ? JSON.stringify([subcategoryId]) : JSON.stringify([])
    ];

    const result = await database.query(query, params);
    console.log(`🏪 Found ${result.rows.length} businesses (all can respond, ${result.rows.filter(r => r.match_priority.includes('match')).length} have category preference)`);
    
    return result.rows.map(row => ({
      userId: row.user_id,
      businessName: row.business_name,
      businessEmail: row.business_email,
      categories: row.categories,
      businessType: row.business_type,
      notificationReason: row.match_priority
    }));
  }

  /**
   * Check if a business can respond to a specific request type
   * Updated logic: Most requests are open, only delivery/ride restricted
   */
  static async canBusinessRespondToRequest(userId, requestType, categoryId) {
    const query = `
      SELECT bv.business_type, bv.categories, bv.is_verified, bv.status,
             COALESCE(bt.name, '') as bt_name, COALESCE(bv.business_category, '') as bt_category
      FROM business_verifications bv
      LEFT JOIN business_types bt ON bt.id = bv.business_type_id
      WHERE bv.user_id = $1 AND bv.is_verified = true AND bv.status = 'approved'
    `;

    const result = await database.query(query, [userId]);
    if (result.rows.length === 0) {
      return { canRespond: false, reason: 'not_verified_business' };
    }

    const business = result.rows[0];

    // Check request type restrictions
    if (requestType === 'delivery') {
      // Only delivery service businesses can respond to delivery requests
      const name = (business.bt_name || '').toLowerCase();
      const cat = (business.bt_category || '').toLowerCase();
      const legacy = business.business_type;
      const isDelivery = ['delivery service','delivery'].includes(name) || ['delivery service','delivery'].includes(cat) || legacy === 'delivery_service' || legacy === 'both';
      if (isDelivery) return { canRespond: true, reason: 'delivery_service_authorized' };
      return { canRespond: false, reason: 'delivery_requires_delivery_service' };
    }

    if (requestType === 'ride') {
      // Ride requests are for drivers, not businesses
      return { canRespond: false, reason: 'ride_requests_for_drivers_only' };
    }

    // For item/service/rent requests, all verified businesses can respond
    if (['item', 'service', 'rent'].includes(requestType)) {
      return { canRespond: true, reason: 'open_to_all_businesses' };
    }

    return { canRespond: true, reason: 'general_business_request' };
  }

  /**
   * Get business access rights (what features they can use)
   * Updated: Product sellers can add prices AND send most requests
   */
  static async getBusinessAccessRights(userId) {
    const query = `
      SELECT bv.business_type, bv.categories, bv.is_verified, bv.status,
             COALESCE(bt.name, '') as bt_name, COALESCE(bv.business_category, '') as bt_category
      FROM business_verifications bv
      LEFT JOIN business_types bt ON bt.id = bv.business_type_id
      WHERE bv.user_id = $1
    `;

    const result = await database.query(query, [userId]);
    if (result.rows.length === 0) {
      return {
        canAddPrices: false,
        canSendItemRequests: false,
        canSendServiceRequests: false,
        canSendRentRequests: false,
        canSendDeliveryRequests: false,
        canSendRideRequests: false,
        canRespondToDelivery: false,
        canRespondToRide: false,
        canRespondToOther: false,
        categories: [],
        verified: false
      };
    }

    const business = result.rows[0];
  const isVerified = business.is_verified && business.status === 'approved';

  // Determine access rights based on type (support both legacy string and new bt_name/category)
  const btName = (business.bt_name || '').toLowerCase();
  const btCat = (business.bt_category || '').toLowerCase();
  const legacy = (business.business_type || '').toLowerCase();
  const isProductSeller = btName === 'product seller' || btCat === 'product seller' || legacy === 'product_selling' || legacy === 'both';
  const isDeliveryService = ['delivery service','delivery'].includes(btName) || ['delivery service','delivery'].includes(btCat) || legacy === 'delivery_service' || legacy === 'both';

    return {
      // Price management (only product sellers)
      canAddPrices: isVerified && isProductSeller,

  // Request creation rights (any verified business can send any request except ride)
  canSendItemRequests: isVerified,
  canSendServiceRequests: isVerified,
  canSendRentRequests: isVerified,
  canSendDeliveryRequests: isVerified,
      canSendRideRequests: false,          // rides are for drivers only

      // Response rights
      canRespondToDelivery: isVerified && isDeliveryService, // Only delivery services
      canRespondToRide: false,                               // Only registered drivers, not businesses
      canRespondToOther: isVerified,                         // Anyone can respond to item/service/rent

      // Metadata
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
