const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

exports.getLatestUpdate = async (req, res) => {
  try {
    const update = await prisma.appUpdate.findFirst({
      orderBy: {
        releaseDate: 'desc'
      }
    });

    if (!update) {
      return res.status(200).json({ updateAvailable: false, message: 'No updates found' });
    }

    res.status(200).json({
      updateAvailable: true,
      update: update
    });
  } catch (error) {
    console.error('Error fetching app update:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};
