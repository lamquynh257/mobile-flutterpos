const express = require('express');
const router = express.Router();
const floorController = require('../controllers/floorController');
const { authMiddleware } = require('../middleware/auth');

router.use(authMiddleware);

router.get('/', floorController.getAll);
router.get('/:id', floorController.getById);
router.post('/', floorController.create);
router.put('/:id', floorController.update);
router.delete('/:id', floorController.delete);

module.exports = router;
