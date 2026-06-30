const app = require('./app');
const prisma = require('./config/prisma');

const PORT = process.env.PORT || 3000;

// Auto-seed a default update record if the table is empty
const seedDefaultUpdate = async () => {
  try {
    const count = await prisma.appUpdate.count();
    if (count === 0) {
      await prisma.appUpdate.create({
        data: {
          version: '1.1.0',
          title: 'SmartKhata Update Available',
          description: 'Version 1.1.0 features new reports, voice-to-text notes, and UI enhancements.',
          size: '14.2 MB',
          downloadUrl: 'https://github.com/Z-oss-tech/Cashbook-UI/releases',
          isMandatory: false,
          releaseDate: new Date()
        }
      });
      console.log('Successfully seeded default app update record.');
    }
  } catch (err) {
    console.error('Error auto-seeding app update:', err.message);
  }
};

app.listen(PORT, '0.0.0.0', async () => {
  console.log(`Server is running on port ${PORT} and accessible on LAN`);
  await seedDefaultUpdate();
});
