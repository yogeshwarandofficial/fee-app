const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboardController');

router.get('/', dashboardController.getMetrics);
router.get('/export', dashboardController.exportMetrics);

module.exports = router;
