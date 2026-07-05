const mongoose = require('mongoose');

const { Schema } = mongoose;

const AdminSchema = new Schema(
  {
    username: {
      type:     String,
      required: [true, 'username is required'],
      unique:   true,
      trim:     true,
    },
    password_hash: {
      type:     String,
      required: [true, 'password_hash is required'],
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Admin', AdminSchema);
