const express = require('express');
const router = express.Router();
const {
  previewAllocation,
  executeAllocation,
  getAllocationLog,
  exportAllocationLog,
} = require('../controllers/allocationController');

router.get('/log/export', exportAllocationLog);
router.get('/log',        getAllocationLog);
router.post('/preview',   previewAllocation);
router.post('/',          executeAllocation);

module.exports = router;
