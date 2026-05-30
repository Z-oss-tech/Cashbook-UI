const prisma = require('../config/prisma');

const getRecords = async (req, res, next) => {
  try {
    const { cashbookId } = req.query;
    
    let whereClause = { isDeleted: false };
    
    if (cashbookId) {
      // Verify ownership
      const cashbook = await prisma.cashbook.findFirst({
        where: { id: cashbookId, userId: req.user.id }
      });

      if (!cashbook) {
        res.status(404);
        throw new Error('Cashbook not found');
      }
      whereClause.cashbookId = cashbookId;
    } else {
      // Return all records for all cashbooks owned by user
      whereClause.cashbook = { userId: req.user.id };
    }

    const records = await prisma.record.findMany({
      where: whereClause,
      orderBy: {
        transactionDate: 'desc'
      }
    });

    res.json({
      success: true,
      data: records
    });
  } catch (error) {
    next(error);
  }
};

const createRecord = async (req, res, next) => {
  try {
    const { cashbookId, title, amount, type, category, paymentMethod, note, attachmentUrl, voiceText, transactionDate } = req.body;

    if (!cashbookId || !title || !amount || !type || !transactionDate) {
      res.status(400);
      throw new Error('Required fields are missing');
    }

    // Verify ownership
    const cashbook = await prisma.cashbook.findFirst({
      where: { id: cashbookId, userId: req.user.id }
    });

    if (!cashbook) {
      res.status(404);
      throw new Error('Cashbook not found');
    }

    const record = await prisma.record.create({
      data: {
        cashbookId,
        title,
        amount: parseFloat(amount),
        type,
        category,
        paymentMethod,
        note,
        attachmentUrl,
        voiceText,
        transactionDate: new Date(transactionDate)
      }
    });

    res.status(201).json({
      success: true,
      data: { record }
    });
  } catch (error) {
    next(error);
  }
};

const updateRecord = async (req, res, next) => {
  try {
    const { id } = req.params;
    
    const record = await prisma.record.findUnique({
      where: { id },
      include: { cashbook: true }
    });

    if (!record || record.cashbook.userId !== req.user.id) {
      res.status(404);
      throw new Error('Record not found');
    }

    const updatedRecord = await prisma.record.update({
      where: { id },
      data: {
        ...req.body,
        amount: req.body.amount ? parseFloat(req.body.amount) : undefined,
        transactionDate: req.body.transactionDate ? new Date(req.body.transactionDate) : undefined,
      }
    });

    res.json({
      success: true,
      data: { record: updatedRecord }
    });
  } catch (error) {
    next(error);
  }
};

const deleteRecord = async (req, res, next) => {
  try {
    const { id } = req.params;
    
    const record = await prisma.record.findUnique({
      where: { id },
      include: { cashbook: true }
    });

    if (!record || record.cashbook.userId !== req.user.id) {
      res.status(404);
      throw new Error('Record not found');
    }

    // Soft delete
    await prisma.record.update({
      where: { id },
      data: {
        isDeleted: true
      }
    });

    res.json({
      success: true,
      message: 'Record deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getRecords,
  createRecord,
  updateRecord,
  deleteRecord
};
