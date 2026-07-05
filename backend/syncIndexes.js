require('dotenv').config();
const mongoose = require('mongoose');
const MasterConfig = require('./src/models/MasterConfig');

async function run() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log("Connected to MongoDB.");
    
    // This will create the new index and drop the old ones that are no longer in the schema.
    await MasterConfig.syncIndexes();
    console.log("Indexes synced successfully.");
    
  } catch (err) {
    console.error("Error syncing indexes:", err);
  } finally {
    await mongoose.disconnect();
    process.exit(0);
  }
}

run();
