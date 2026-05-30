const express = require('express');
const multer = require('multer');
const router = express.Router();
const { uploadImage, deleteImage } = require('../controllers/uploadController');
const { protect } = require('../middlewares/authMiddleware');

const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5 MB
  },
});

router.use(protect);

router.post('/', upload.single('image'), uploadImage);
router.delete('/', deleteImage);

module.exports = router;
