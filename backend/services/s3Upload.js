const AWS = require('aws-sdk');
const multer = require('multer');
const multerS3 = require('multer-s3');
const path = require('path');

// Configure AWS SDK
const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION || 'us-east-1'
});

// S3 bucket configuration
const BUCKET_NAME = process.env.AWS_S3_BUCKET || 'requestappbucket';
const ACCESS_POINT_ARN = process.env.AWS_S3_ACCESS_POINT_ARN || 'arn:aws:s3:us-east-1:512852113473:accesspoint/requestappbucket';

// Configure multer for S3 upload
const uploadToS3 = multer({
  storage: multerS3({
    s3: s3,
    bucket: ACCESS_POINT_ARN,
    acl: 'public-read',
    metadata: function (req, file, cb) {
      cb(null, {
        fieldName: file.fieldname,
        uploadTime: new Date().toISOString()
      });
    },
    key: function (req, file, cb) {
      const { uploadType, userId } = req.body;
      const timestamp = Date.now();
      const ext = path.extname(file.originalname);
      const randomString = Math.random().toString(36).substring(2);
      
      let keyPath;
      switch (uploadType) {
        case 'driver_photo':
          keyPath = `drivers/${userId}/driver_photo_${timestamp}.jpg`;
          break;
        case 'nic_front':
          keyPath = `drivers/${userId}/nic_front_${timestamp}.jpg`;
          break;
        case 'nic_back':
          keyPath = `drivers/${userId}/nic_back_${timestamp}.jpg`;
          break;
        case 'license_front':
          keyPath = `drivers/${userId}/license_front_${timestamp}.jpg`;
          break;
        case 'license_back':
          keyPath = `drivers/${userId}/license_back_${timestamp}.jpg`;
          break;
        case 'license_document':
          keyPath = `drivers/${userId}/license_document_${timestamp}${ext}`;
          break;
        case 'vehicle_registration':
          keyPath = `drivers/${userId}/vehicle_registration_${timestamp}${ext}`;
          break;
        case 'insurance_document':
          keyPath = `drivers/${userId}/insurance_document_${timestamp}${ext}`;
          break;
        case 'billing_proof':
          keyPath = `drivers/${userId}/billing_proof_${timestamp}${ext}`;
          break;
        case 'vehicle_image':
          const imageIndex = req.body.imageIndex || '1';
          keyPath = `vehicles/${userId}/${imageIndex}_${timestamp}.jpg`;
          break;
        default:
          keyPath = `uploads/${userId}/${file.fieldname}_${timestamp}_${randomString}${ext}`;
      }
      
      cb(null, keyPath);
    }
  }),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    const allowedMimes = [
      'image/jpeg',
      'image/jpg', 
      'image/png',
      'image/gif',
      'image/webp',
      'image/bmp',
      'image/heic',
      'image/heif',
      'application/pdf'
    ];
    
    const allowedExts = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic', '.heif', '.pdf'];
    const ext = path.extname(file.originalname).toLowerCase();
    
    if (allowedMimes.includes(file.mimetype) || allowedExts.includes(ext)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type. Only images and PDFs are allowed.'));
    }
  }
});

// Helper function to generate S3 object URL
const getS3ObjectUrl = (key) => {
  return `https://${BUCKET_NAME}.s3.${process.env.AWS_REGION || 'us-east-1'}.amazonaws.com/${key}`;
};

// Helper function to delete file from S3
const deleteFromS3 = async (fileUrl) => {
  try {
    // Extract key from URL
    const urlParts = fileUrl.split('/');
    const key = urlParts.slice(3).join('/'); // Remove protocol and domain
    
    const params = {
      Bucket: ACCESS_POINT_ARN,
      Key: key
    };
    
    await s3.deleteObject(params).promise();
    console.log('✅ File deleted from S3:', key);
    return true;
  } catch (error) {
    console.error('❌ Error deleting file from S3:', error);
    throw error;
  }
};

module.exports = {
  uploadToS3,
  getS3ObjectUrl,
  deleteFromS3,
  s3
};
