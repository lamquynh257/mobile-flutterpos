const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');
const { authMiddleware } = require('../middleware/auth');

router.use(authMiddleware);

router.get('/', orderController.getAll);
router.post('/', orderController.create);
router.put('/:id/status', orderController.updateStatus);

module.exports = router;
