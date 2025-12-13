const prisma = require('../config/database');

// Get all floors
exports.getAll = async (req, res) => {
    try {
        const floors = await prisma.floor.findMany({
            orderBy: { order: 'asc' },
            include: {
                tables: {
                    select: { id: true, name: true, status: true },
                },
            },
        });

        res.json(floors);
    } catch (error) {
        console.error('Get floors error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Get floor by ID
exports.getById = async (req, res) => {
    try {
        const { id } = req.params;
        const floor = await prisma.floor.findUnique({
            where: { id: parseInt(id) },
            include: {
                tables: true,
            },
        });

        if (!floor) {
            return res.status(404).json({ error: 'Floor not found' });
        }

        res.json(floor);
    } catch (error) {
        console.error('Get floor error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Create floor
exports.create = async (req, res) => {
    try {
        const { name, order } = req.body;

        if (!name) {
            return res.status(400).json({ error: 'Floor name is required' });
        }

        const floor = await prisma.floor.create({
            data: { name, order: order || 0 },
        });

        res.status(201).json(floor);
    } catch (error) {
        console.error('Create floor error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Update floor
exports.update = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, order } = req.body;

        const floor = await prisma.floor.update({
            where: { id: parseInt(id) },
            data: { name, order },
        });

        res.json(floor);
    } catch (error) {
        console.error('Update floor error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Delete floor
exports.delete = async (req, res) => {
    try {
        const { id } = req.params;

        await prisma.floor.delete({
            where: { id: parseInt(id) },
        });

        res.json({ message: 'Floor deleted successfully' });
    } catch (error) {
        console.error('Delete floor error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};
