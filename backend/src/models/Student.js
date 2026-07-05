const mongoose = require('mongoose');

const { Schema } = mongoose;

// ── Balance sub-schema ────────────────────────────────────────────────────────
const BalanceBucketSchema = new Schema(
  {
    paid: { type: Number, default: 0 },
    due:  { type: Number, default: 0 },
  },
  { _id: false }
);

// ── Custom fee sub-schema ─────────────────────────────────────────────────────
const CustomFeeSchema = new Schema(
  {
    fee_description: { type: String, required: true, trim: true },
    amount:          { type: Number, required: true },
    status:          { type: String, required: true, trim: true },
  },
  { _id: false }
);

// ── Student schema ────────────────────────────────────────────────────────────
const StudentSchema = new Schema(
  {
    student_id: {
      type:     String,
      required: [true, 'student_id is required'],
      unique:   true,
      trim:     true,
    },
    full_name: {
      type:     String,
      required: [true, 'full_name is required'],
      trim:     true,
    },
    grade_id: {
      type:     Schema.Types.ObjectId,
      ref:      'MasterConfig',
      required: [true, 'grade_id is required'],
    },
    section_id: {
      type:     Schema.Types.ObjectId,
      ref:      'MasterConfig',
      required: [true, 'section_id is required'],
    },
    phone_number: {
      type:     String,
      required: [true, 'phone_number is required'],
      validate: {
        validator: (v) => /^\d{10}$/.test(v),
        message:   'phone_number must be exactly 10 numeric digits',
      },
    },
    avatar_url: {
      type:    String,
      default: null,
    },
    transport_route_id: {
      type:    Schema.Types.ObjectId,
      ref:     'MasterConfig',
      default: null,
    },
    balances: {
      tuition:   { type: BalanceBucketSchema, default: () => ({}) },
      transport: { type: BalanceBucketSchema, default: () => ({}) },
      other:     { type: BalanceBucketSchema, default: () => ({}) },
    },
    custom_fees: {
      type:    [CustomFeeSchema],
      default: [],
    },
    // Stored/derived status: "cleared" when all dues are 0, otherwise "pending".
    status: {
      type:    String,
      default: 'pending',
      enum:    ['cleared', 'pending'],
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Student', StudentSchema);
