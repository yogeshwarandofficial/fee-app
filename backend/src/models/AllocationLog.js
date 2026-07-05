const mongoose = require('mongoose');

const { Schema } = mongoose;

const AllocationLogSchema = new Schema(
  {
    log_id: {
      type:     String,
      required: [true, 'log_id is required'],
      unique:   true,
      trim:     true,
    },
    timestamp: {
      type:    Date,
      default: Date.now,
    },
    fee_category: {
      type:     String,
      enum:     ['tuition', 'transport', 'other'],
      required: [true, 'fee_category is required'],
    },
    // Flexible object — stores whatever cohort was targeted by this allocation.
    // Examples:
    //   { grade_id: ObjectId, label: "Grade 5 — All Sections" }
    //   { section_id: ObjectId, label: "Grade 3 — Section A" }
    //   { route_id: ObjectId, label: "Route: Koramangala" }
    target_scope: {
      type: Schema.Types.Mixed,
    },
    amount: {
      type:     Number,
      required: [true, 'amount is required'],
      validate: {
        validator: (v) => v > 0,
        message:   'amount must be greater than 0',
      },
    },
    description: {
      type:     String,
      required: [true, 'description is required'],
      trim:     true,
      validate: {
        validator: (v) => v && v.trim().length > 0,
        message:   'description cannot be empty or whitespace-only',
      },
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('AllocationLog', AllocationLogSchema);
