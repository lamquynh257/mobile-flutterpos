const express = require('express');
const router = express.Router();
const categoryController = require('../controllers/categoryController');
const dishController = require('../controllers/dishController');
const { authMiddleware } = require('../middleware/auth');

router.use(authMiddleware);

// Category routes
router.get('/categories', categoryController.getAll);
router.post('/categories', categoryController.create);
router.put('/categories/:id', categoryController.update);
router.delete('/categories/:id', categoryController.delete);

// Dish routes
router.get('/dishes', dishController.getAll);
router.post('/dishes', dishController.create);
router.put('/dishes/:id', dishController.update);
router.delete('/dishes/:id', dishController.delete);

module.exports = router;
