const AWS = require('aws-sdk');
const multer = require('multer');
const path = require('path');

// Configure AWS SDK
const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION || 'us-east-1'
});

// S3 bucket configuration
const BUCKET_NAME = process.env.AWS_S3_BUCKET || 'requestappbucket';

// Configure multer for memory storage (we'll handle S3 upload manually)
const uploadToMemory = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    console.log('📁 File upload attempt:', {
      originalname: file.originalname,
      mimetype: file.mimetype,
      fieldname: file.fieldname
    });
    
    const allowedMimes = [
      'image/jpeg',
      'image/jpg', 
      'image/png',
      'image/gif',
      'image/webp',
      'image/bmp',
      'image/heic',
      'image/heif',
      'application/pdf',
      'application/octet-stream' // Sometimes mobile uploads use this
    ];
    
    const allowedExts = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic', '.heif', '.pdf'];
    const ext = path.extname(file.originalname).toLowerCase();
    
    // Accept if either MIME type is allowed OR extension is allowed
    const isMimeAllowed = allowedMimes.includes(file.mimetype);
    const isExtAllowed = allowedExts.includes(ext);
    const isImageMime = file.mimetype && file.mimetype.startsWith('image/');
    
    if (isMimeAllowed || isExtAllowed || isImageMime) {
      console.log('✅ File accepted:', file.originalname);
      cb(null, true);
    } else {
      console.log('❌ File rejected:', {
        filename: file.originalname,
        mimetype: file.mimetype,
        extension: ext
      });
      cb(new Error(`Invalid file type: ${file.mimetype}. Only images and PDFs are allowed.`));
    }
  }
});

// Manual S3 upload function
const uploadToS3 = async (file, uploadType, userId, imageIndex) => {
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
      const imgIndex = imageIndex || '1';
      keyPath = `vehicles/${userId}/${imgIndex}_${timestamp}.jpg`;
      break;
    default:
      keyPath = `uploads/${userId}/${file.fieldname}_${timestamp}_${randomString}${ext}`;
  }

  const params = {
    Bucket: BUCKET_NAME,
    Key: keyPath,
    Body: file.buffer,
    ContentType: file.mimetype
    // Removed ACL: 'public-read' because bucket doesn't allow ACLs
  };

  try {
    console.log('🚀 Uploading to S3:', keyPath);
    const result = await s3.upload(params).promise();
    console.log('✅ S3 upload successful:', result.Location);
    return result.Location;
  } catch (error) {
    console.error('❌ S3 upload failed:', error);
    throw error;
  }
};

// Helper function to delete file from S3
const deleteFromS3 = async (fileUrl) => {
  try {
    // Extract key from URL
    const urlParts = fileUrl.split('/');
    const key = urlParts.slice(3).join('/'); // Remove protocol and domain
    
    const params = {
      Bucket: BUCKET_NAME,
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
  uploadToMemory,
  uploadToS3,
  deleteFromS3,
  s3
};
