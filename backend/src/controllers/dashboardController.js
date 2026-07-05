const dashboardService = require('../services/dashboardService');
const { generateExcelBuffer } = require('../utils/exportHelpers');
const { sendSuccess, sendError } = require('../utils/responseHelper');
const MasterConfig = require('../models/MasterConfig');

/**
 * @route   GET /api/dashboard
 * @desc    Get dashboard metrics (strength, payments, trend)
 * @access  Private
 */
const getMetrics = async (req, res, next) => {
  try {
    const { grade_id } = req.query;
    
    // Call the unified aggregation service
    const metrics = await dashboardService.getDashboardMetrics(grade_id);
    
    return sendSuccess(res, metrics, 'Dashboard metrics retrieved successfully', 200);
  } catch (err) {
    next(err);
  }
};

/**
 * @route   GET /api/dashboard/export
 * @desc    Export dashboard metrics to Excel
 * @access  Private
 */
const exportMetrics = async (req, res, next) => {
  try {
    const { grade_id } = req.query;

    // Call the service to get metrics
    const metrics = await dashboardService.getDashboardMetrics(grade_id);
    
    // Fetch grade name for the file and filter metadata
    let gradeName = 'All Grades';
    const filters = {};
    if (grade_id) {
      const grade = await MasterConfig.findById(grade_id);
      if (grade) {
        gradeName = grade.name;
        filters['Grade'] = gradeName;
      }
    }

    // ── Generate Excel Data ──────────────────────────────────────────────────
    
    // We will create a summary sheet
    const columns = [
      { key: 'metric', header: 'Metric', width: 40 },
      { key: 'value', header: 'Value', width: 25 },
    ];
    
    // Format amounts as currency
    const formatCurrency = (val) => `₹ ${val.toLocaleString('en-IN')}`;

    const rows = [
      { metric: 'Total Student Strength', value: metrics.studentStrength },
      { metric: 'Total Paid Fee', value: formatCurrency(metrics.totalPaid) },
      { metric: 'Pending/Unpaid Fee', value: formatCurrency(metrics.pendingDue) },
      { metric: 'Paid Percentage', value: `${metrics.paidVsUnpaidPercentage.paid}%` },
      { metric: 'Unpaid Percentage', value: `${metrics.paidVsUnpaidPercentage.unpaid}%` },
    ];

    // Add a blank row spacer
    rows.push({ metric: '', value: '' });
    rows.push({ metric: 'MONTHLY COLLECTION TREND', value: '' });

    metrics.monthlyCollectionTrend.forEach(trend => {
      rows.push({ metric: trend.month, value: formatCurrency(trend.amount) });
    });

    const sheetName = 'Dashboard Metrics';
    
    const buffer = await generateExcelBuffer(sheetName, columns, rows, filters);

    // ── Set response headers for file download ──────────────────────────────
    const now = new Date();
    const timestamp = now.getFullYear() +
                      String(now.getMonth() + 1).padStart(2, '0') +
                      String(now.getDate()).padStart(2, '0') + '_' +
                      String(now.getHours()).padStart(2, '0') +
                      String(now.getMinutes()).padStart(2, '0');
    const safeGradeName = gradeName.replace(/[^a-zA-Z0-9]/g, '_');
    const filename = `Dashboard_Export_${safeGradeName}_${timestamp}.xlsx`;

    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    
    return res.status(200).send(buffer);
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getMetrics,
  exportMetrics,
};
