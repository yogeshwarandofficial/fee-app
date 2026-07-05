const mongoose = require('mongoose');

const { Schema } = mongoose;

const MasterConfigSchema = new Schema(
  {
    type: {
      type:     String,
      enum:     ['grade', 'section', 'route'],
      required: [true, 'type is required'],
    },
    name: {
      type:     String,
      required: [true, 'name is required'],
      trim:     true,
    },
    // Only sections use this — points to the parent Grade MasterConfig document.
    parent_id: {
      type:    Schema.Types.ObjectId,
      ref:     'MasterConfig',
      default: null,
    },
  },
  { timestamps: true }
);

// ── Unique compound index with case-insensitive collation ─────────────────────
// Prevents duplicate entries like "Grade X" and "grade x" from coexisting.
MasterConfigSchema.index(
  { type: 1, parent_id: 1, name: 1 },
  {
    unique:    true,
    collation: { locale: 'en', strength: 2 }, // strength 2 = case-insensitive
  }
);

module.exports = mongoose.model('MasterConfig', MasterConfigSchema);
