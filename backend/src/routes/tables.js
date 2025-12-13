const express = require('express');
const router = express.Router();
const tableController = require('../controllers/tableController');
const { authMiddleware } = require('../middleware/auth');

router.use(authMiddleware);

router.get('/', tableController.getAll);
router.get('/:id', tableController.getById);
router.post('/', tableController.create);
router.put('/:id', tableController.update);
router.delete('/:id', tableController.delete);

// Special routes for table booking
router.post('/:id/book', tableController.book);
router.get('/:id/preview-checkout', tableController.previewCheckout); // Preview without ending session
router.post('/:id/checkout', tableController.checkout);

module.exports = router;
