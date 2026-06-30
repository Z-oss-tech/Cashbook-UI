const prisma = require('../config/prisma');

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

exports.createUpdate = async (req, res) => {
  try {
    const { version, title, description, size, downloadUrl, isMandatory } = req.body;
    if (!version || !title || !description || !size || !downloadUrl) {
      return res.status(400).json({ message: 'Missing required update fields' });
    }

    // Delete any existing update with the same version to allow overwriting
    try {
      await prisma.appUpdate.deleteMany({
        where: { version }
      });
    } catch (_) {}

    const update = await prisma.appUpdate.create({
      data: {
        version,
        title,
        description,
        size,
        downloadUrl,
        isMandatory: isMandatory || false,
        releaseDate: new Date()
      }
    });

    res.status(201).json({
      success: true,
      message: 'App update record created successfully',
      update: update
    });
  } catch (error) {
    console.error('Error creating app update:', error);
    res.status(500).json({ message: 'Internal server error' });
  }
};
