const express = require('express');
const router = express.Router();
const {
  getConfig,
  createConfig,
  updateConfig,
  deleteConfig,
} = require('../controllers/masterConfigController');

router.get('/', getConfig);
router.post('/', createConfig);
router.put('/:id', updateConfig);
router.delete('/:id', deleteConfig);

module.exports = router;
