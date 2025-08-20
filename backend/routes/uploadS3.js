const express = require('express');
const router = express.Router();
const { uploadToS3, deleteFromS3 } = require('../services/s3Upload');

console.log('🔧 S3 Upload route loaded');

// Upload file to S3
router.post('/s3', uploadToS3.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ 
        success: false, 
        error: 'No file provided' 
      });
    }

    console.log('✅ File uploaded to S3:', req.file.location);
    
    res.json({
      success: true,
      url: req.file.location,
      key: req.file.key,
      bucket: req.file.bucket,
      size: req.file.size,
      etag: req.file.etag
    });
  } catch (error) {
    console.error('❌ Error uploading to S3:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to upload file to S3',
      details: error.message 
    });
  }
});

// Delete file from S3
router.delete('/s3', async (req, res) => {
  try {
    const { url } = req.body;
    
    if (!url) {
      return res.status(400).json({ 
        success: false, 
        error: 'File URL required' 
      });
    }

    await deleteFromS3(url);
    
    res.json({ 
      success: true, 
      message: 'File deleted successfully from S3' 
    });
  } catch (error) {
    console.error('❌ Error deleting from S3:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to delete file from S3',
      details: error.message 
    });
  }
});

// Test S3 connection
router.get('/s3/test', async (req, res) => {
  try {
    const { s3 } = require('../services/s3Upload');
    
    // Test S3 connection by listing buckets
    const result = await s3.listBuckets().promise();
    
    res.json({
      success: true,
      message: 'S3 connection successful',
      buckets: result.Buckets?.length || 0
    });
  } catch (error) {
    console.error('❌ S3 connection test failed:', error);
    res.status(500).json({
      success: false,
      error: 'S3 connection failed',
      details: error.message
    });
  }
});

module.exports = router;
