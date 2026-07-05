const mongoose = require('mongoose');

const { Schema } = mongoose;

const TransactionSchema = new Schema(
  {
    transaction_id: {
      type:     String,
      required: [true, 'transaction_id is required'],
      unique:   true,
      trim:     true,
    },
    student_id: {
      type:     Schema.Types.ObjectId,
      ref:      'Student',
      required: [true, 'student_id is required'],
      index:    true,
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
    amount_collected: {
      type:     Number,
      required: [true, 'amount_collected is required'],
      validate: {
        validator: (v) => v > 0,
        message:   'amount_collected must be greater than 0',
      },
    },
  },
  { timestamps: true }
);

// ── Indexes ───────────────────────────────────────────────────────────────────
// Compound index for fast per-student history lookups (most recent first).
TransactionSchema.index({ student_id: 1, timestamp: -1 });

// Single-field index for the Master Ledger's date-range filtering.
TransactionSchema.index({ timestamp: -1 });

module.exports = mongoose.model('Transaction', TransactionSchema);
