const prisma = require('../config/prisma');

const getCashbooks = async (req, res, next) => {
  try {
    const cashbooks = await prisma.cashbook.findMany({
      where: {
        userId: req.user.id,
        isArchived: false
      },
      orderBy: {
        createdAt: 'desc'
      }
    });

    res.json({
      success: true,
      data: cashbooks
    });
  } catch (error) {
    next(error);
  }
};

const getCashbook = async (req, res, next) => {
  try {
    const { id } = req.params;
    
    const cashbook = await prisma.cashbook.findFirst({
      where: {
        id,
        userId: req.user.id
      },
      include: {
        records: {
          where: { isDeleted: false },
          orderBy: { transactionDate: 'desc' }
        }
      }
    });

    if (!cashbook) {
      res.status(404);
      throw new Error('Cashbook not found');
    }

    res.json({
      success: true,
      data: cashbook
    });
  } catch (error) {
    next(error);
  }
};

const createCashbook = async (req, res, next) => {
  try {
    const { name, description, currency } = req.body;

    if (!name) {
      res.status(400);
      throw new Error('Name is required');
    }

    const cashbook = await prisma.cashbook.create({
      data: {
        userId: req.user.id,
        name,
        description,
        currency: currency || 'INR'
      }
    });

    res.status(201).json({
      success: true,
      data: { cashbook }
    });
  } catch (error) {
    next(error);
  }
};

const updateCashbook = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, description, currency, isArchived } = req.body;

    // Check ownership
    const existing = await prisma.cashbook.findFirst({
      where: { id, userId: req.user.id }
    });

    if (!existing) {
      res.status(404);
      throw new Error('Cashbook not found');
    }

    const cashbook = await prisma.cashbook.update({
      where: { id },
      data: {
        name,
        description,
        currency,
        isArchived
      }
    });

    res.json({
      success: true,
      data: { cashbook }
    });
  } catch (error) {
    next(error);
  }
};

const deleteCashbook = async (req, res, next) => {
  try {
    const { id } = req.params;
    
    const existing = await prisma.cashbook.findFirst({
      where: { id, userId: req.user.id }
    });

    if (!existing) {
      res.status(404);
      throw new Error('Cashbook not found');
    }

    await prisma.cashbook.delete({
      where: { id }
    });

    res.json({
      success: true,
      message: 'Cashbook deleted successfully'
    });
  } catch (error) {
    next(error);
  }
};

const getCashbookSummary = async (req, res, next) => {
  try {
    const { id } = req.params;
    
    const cashbook = await prisma.cashbook.findFirst({
      where: { id, userId: req.user.id }
    });

    if (!cashbook) {
      res.status(404);
      throw new Error('Cashbook not found');
    }

    const records = await prisma.record.findMany({
      where: { cashbookId: id, isDeleted: false }
    });

    let totalIncome = 0;
    let totalExpense = 0;
    
    records.forEach(r => {
      if (r.type === 'income') totalIncome += Number(r.amount);
      if (r.type === 'expense') totalExpense += Number(r.amount);
    });

    res.json({
      success: true,
      data: {
        totalIncome,
        totalExpense,
        balance: totalIncome - totalExpense,
        recordCount: records.length
      }
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getCashbooks,
  getCashbook,
  getCashbookSummary,
  createCashbook,
  updateCashbook,
  deleteCashbook
};
