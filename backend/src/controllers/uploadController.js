const cloudinary = require('cloudinary').v2;
const streamifier = require('streamifier');

// Configure Cloudinary (Will only work if env vars are present)
if (process.env.CLOUDINARY_CLOUD_NAME) {
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
  });
}

const uploadImage = async (req, res, next) => {
  try {
    if (!req.file) {
      res.status(400);
      throw new Error('No image provided');
    }

    if (!process.env.CLOUDINARY_CLOUD_NAME) {
      res.status(500);
      throw new Error('Cloudinary is not configured on the server. Please add CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, and CLOUDINARY_API_SECRET to your environment variables.');
    }

    const streamUpload = (req) => {
      return new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
          { folder: 'cashbook' },
          (error, result) => {
            if (result) {
              resolve(result);
            } else {
              // Wrap cloudinary error object in a standard Error
              reject(new Error(error.message || JSON.stringify(error)));
            }
          }
        );
        streamifier.createReadStream(req.file.buffer).pipe(stream);
      });
    };

    const result = await streamUpload(req);

    res.status(200).json({
      success: true,
      imageUrl: result.secure_url,
      public_id: result.public_id
    });
  } catch (error) {
    next(error);
  }
};

const deleteImage = async (req, res, next) => {
  try {
    const { public_id } = req.body;
    
    if (!public_id) {
      res.status(400);
      throw new Error('No public_id provided');
    }

    if (!process.env.CLOUDINARY_CLOUD_NAME) {
      res.status(500);
      throw new Error('Cloudinary is not configured on the server.');
    }

    const result = await cloudinary.uploader.destroy(public_id);
    
    res.status(200).json({
      success: true,
      result
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  uploadImage,
  deleteImage
};
