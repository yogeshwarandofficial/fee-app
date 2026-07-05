const mongoose = require('mongoose');

/**
 * Connects to MongoDB Atlas using the MONGODB_URI environment variable.
 * Throws if the URI is missing or the connection fails.
 */
const connectDB = async () => {
  const uri = process.env.MONGODB_URI;

  if (!uri) {
    throw new Error('MONGODB_URI is not defined in environment variables.');
  }

  await mongoose.connect(uri);

  console.log(`MongoDB connected: ${mongoose.connection.host}`);
};

module.exports = connectDB;
