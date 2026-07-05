const express  = require('express');
const router   = express.Router();
const { sendIndividual, sendBulk } = require('../controllers/whatsappController');

// POST /api/whatsapp/send-individual/:id  — generates a wa.me deep link
router.post('/send-individual/:id', sendIndividual);

// POST /api/whatsapp/send-bulk  — dispatches bulk reminders via provider
router.post('/send-bulk', sendBulk);

module.exports = router;
