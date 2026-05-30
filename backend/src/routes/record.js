const express = require('express');
const router = express.Router();
const { getRecords, createRecord, updateRecord, deleteRecord } = require('../controllers/recordController');
const { protect } = require('../middlewares/authMiddleware');

router.use(protect);

router.route('/')
  .get(getRecords)
  .post(createRecord);

router.route('/:id')
  .put(updateRecord)
  .delete(deleteRecord);

module.exports = router;
