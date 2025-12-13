const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');
const prisma = require('../config/database');

// Import from tableController since sessions are managed there
const tableController = require('../controllers/tableController');

router.use(authMiddleware);

// Get completed sessions for reporting
router.get('/completed', async (req, res) => {
    try {

        const sessions = await prisma.tableSession.findMany({
            where: {
                endTime: {
                    not: null,
                },
            },
            include: {
                table: {
                    select: {
                        id: true,
                        name: true,
                    },
                },
            },
            orderBy: {
                endTime: 'desc',
            },
        });

        res.json(sessions);
    } catch (error) {
        console.error('Get completed sessions error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

module.exports = router;
