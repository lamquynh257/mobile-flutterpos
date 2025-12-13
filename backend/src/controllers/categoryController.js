const prisma = require('../config/database');

// Get all categories
exports.getAll = async (req, res) => {
    try {
        const categories = await prisma.category.findMany({
            orderBy: { order: 'asc' },
            include: {
                dishes: {
                    select: { id: true, name: true, price: true },
                },
            },
        });

        res.json(categories);
    } catch (error) {
        console.error('Get categories error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Create, update, delete similar to floor controller
exports.create = async (req, res) => {
    try {
        const { name, order } = req.body;
        const category = await prisma.category.create({
            data: { name, order: order || 0 },
        });
        res.status(201).json(category);
    } catch (error) {
        res.status(500).json({ error: 'Internal server error' });
    }
};

exports.update = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, order } = req.body;
        const category = await prisma.category.update({
            where: { id: parseInt(id) },
            data: { name, order },
        });
        res.json(category);
    } catch (error) {
        res.status(500).json({ error: 'Internal server error' });
    }
};

exports.delete = async (req, res) => {
    try {
        const { id } = req.params;
        await prisma.category.delete({ where: { id: parseInt(id) } });
        res.json({ message: 'Category deleted successfully' });
    } catch (error) {
        res.status(500).json({ error: 'Internal server error' });
    }
};
