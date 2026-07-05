const mongoose = require('mongoose');
const Student = require('../models/Student');
const Transaction = require('../models/Transaction');

/**
 * Retrieves unified dashboard metrics via aggregation.
 * @param {string} [gradeFilter] - Optional Grade ID (MasterConfig) to filter by.
 */
const getDashboardMetrics = async (gradeFilter) => {
  const matchStage = {};
  if (gradeFilter) {
    matchStage.grade_id = new mongoose.Types.ObjectId(gradeFilter);
  }

  // ── 1. Student Collection Aggregation (Strength, Paid, Pending) ────────────
  // We use $facet to run multiple aggregations on the same matched documents.
  const studentMetrics = await Student.aggregate([
    { $match: matchStage },
    {
      $facet: {
        totals: [
          {
            $group: {
              _id: null,
              studentStrength: { $sum: 1 },
              totalTuitionPaid: { $sum: '$balances.tuition.paid' },
              totalTransportPaid: { $sum: '$balances.transport.paid' },
              totalOtherPaid: { $sum: '$balances.other.paid' },
              totalTuitionDue: { $sum: '$balances.tuition.due' },
              totalTransportDue: { $sum: '$balances.transport.due' },
              totalOtherDue: { $sum: '$balances.other.due' },
            },
          },
        ],
      },
    },
  ]);

  const totals = studentMetrics[0].totals[0] || {
    studentStrength: 0,
    totalTuitionPaid: 0,
    totalTransportPaid: 0,
    totalOtherPaid: 0,
    totalTuitionDue: 0,
    totalTransportDue: 0,
    totalOtherDue: 0,
  };

  const totalPaid = totals.totalTuitionPaid + totals.totalTransportPaid + totals.totalOtherPaid;
  const pendingDue = totals.totalTuitionDue + totals.totalTransportDue + totals.totalOtherDue;

  // Calculate percentages (must sum to exactly 100)
  const totalAmount = totalPaid + pendingDue;
  let paidVsUnpaidPercentage = { paid: 0, unpaid: 0 };
  
  if (totalAmount > 0) {
    const rawPaidPct = (totalPaid / totalAmount) * 100;
    // Using Math.round to integer, and unpaid is remainder to ensure exactly 100
    const roundedPaidPct = Math.round(rawPaidPct);
    paidVsUnpaidPercentage = {
      paid: roundedPaidPct,
      unpaid: 100 - roundedPaidPct,
    };
  } else {
      // if 0 total, we can return 0/0 or 50/50. 0/0 is fine for frontend? Let's just return 0/0.
  }

  // ── 2. Transaction Collection Aggregation (Monthly Trend) ──────────────────
  // If we have a grade filter, we need to join with Student to filter transactions.
  const txPipeline = [];
  
  if (gradeFilter) {
    txPipeline.push(
      {
        $lookup: {
          from: 'students', // Ensure correct collection name
          localField: 'student_id',
          foreignField: '_id',
          as: 'student',
        },
      },
      { $unwind: '$student' },
      { $match: { 'student.grade_id': new mongoose.Types.ObjectId(gradeFilter) } }
    );
  }

  // Group by month
  txPipeline.push(
    {
      $group: {
        _id: {
          year: { $year: '$timestamp' },
          month: { $month: '$timestamp' },
        },
        amount: { $sum: '$amount_collected' },
      },
    },
    { $sort: { '_id.year': 1, '_id.month': 1 } }
  );

  const rawMonthlyTrend = await Transaction.aggregate(txPipeline);
  
  const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  const monthlyCollectionTrend = rawMonthlyTrend.map(item => ({
    month: monthNames[item._id.month - 1], // + " " + item._id.year (Optional, specs just said "Jan")
    amount: item.amount,
  }));

  // Ensure 0 values for empty dataset
  return {
    studentStrength: totals.studentStrength,
    totalPaid,
    pendingDue,
    paidVsUnpaidPercentage,
    monthlyCollectionTrend,
  };
};

module.exports = {
  getDashboardMetrics,
};
