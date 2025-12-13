const express = require('express');
const router = express.Router();
const reportController = require('../controllers/reportController');
const { authMiddleware } = require('../middleware/auth');

router.use(authMiddleware);

router.get('/revenue', reportController.revenue);
router.get('/orders', reportController.orders);
router.get('/tables', reportController.tables);

module.exports = router;
