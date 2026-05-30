const express = require('express');
const router = express.Router();
const { getCashbooks, getCashbook, getCashbookSummary, createCashbook, updateCashbook, deleteCashbook } = require('../controllers/cashbookController');
const { protect } = require('../middlewares/authMiddleware');

router.use(protect);

router.route('/')
  .get(getCashbooks)
  .post(createCashbook);

router.get('/:id/summary', getCashbookSummary);

router.route('/:id')
  .get(getCashbook)
  .put(updateCashbook)
  .delete(deleteCashbook);

module.exports = router;
