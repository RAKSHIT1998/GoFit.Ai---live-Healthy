import AWS from 'aws-sdk';

// Initialize S3 client
const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION || 'us-east-1'
});

// Check if S3 is configured
function isS3Configured() {
  return !!(
    process.env.S3_BUCKET_NAME &&
    process.env.AWS_ACCESS_KEY_ID &&
    process.env.AWS_SECRET_ACCESS_KEY
  );
}

/**
 * Upload a file to S3
 * @param {Object} file - Multer file object with buffer, mimetype, originalname
 * @param {String} pathPrefix - Path prefix for the file (e.g., 'progress/userId/')
 * @returns {Promise<{url: String, key: String}>} - Returns URL and key, or null if S3 not configured
 */
export async function uploadToS3(file, pathPrefix = '') {
  if (!isS3Configured()) {
    console.log('ℹ️ S3 not configured, skipping upload');
    return null;
  }

  if (!file || !file.buffer) {
    throw new Error('Invalid file object');
  }

  try {
    const filename = `${pathPrefix}${Date.now()}-${file.originalname || 'file'}`;
    const uploadParams = {
      Bucket: process.env.S3_BUCKET_NAME,
      Key: filename,
      Body: file.buffer,
      ContentType: file.mimetype || 'application/octet-stream',
      ACL: 'private'
    };

    await s3.putObject(uploadParams).promise();
    
    const region = process.env.AWS_REGION || 'us-east-1';
    const url = `https://${process.env.S3_BUCKET_NAME}.s3.${region}.amazonaws.com/${filename}`;
    
    return {
      url,
      key: filename
    };
  } catch (error) {
    console.error('⚠️ S3 upload failed:', error.message);
    throw error;
  }
}

/**
 * Delete a file from S3
 * @param {String} key - S3 object key to delete
 * @returns {Promise<void>}
 */
export async function deleteFromS3(key) {
  if (!isS3Configured()) {
    console.log('ℹ️ S3 not configured, skipping delete');
    return;
  }

  if (!key) {
    console.warn('⚠️ No S3 key provided for deletion');
    return;
  }

  try {
    const deleteParams = {
      Bucket: process.env.S3_BUCKET_NAME,
      Key: key
    };

    await s3.deleteObject(deleteParams).promise();
    console.log(`✅ Successfully deleted S3 object: ${key}`);
  } catch (error) {
    console.error('⚠️ S3 delete failed:', error.message);
    throw error;
  }
}

