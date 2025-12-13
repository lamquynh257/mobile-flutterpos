const prisma = require('../config/database');

// Get all dishes (optionally filter by category)
exports.getAll = async (req, res) => {
    try {
        const { categoryId } = req.query;
        const where = categoryId ? { categoryId: parseInt(categoryId) } : {};

        const dishes = await prisma.dish.findMany({
            where,
            include: {
                category: { select: { id: true, name: true } },
            },
            orderBy: { id: 'asc' },
        });

        res.json(dishes);
    } catch (error) {
        console.error('Get dishes error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Create dish
exports.create = async (req, res) => {
    try {
        const { categoryId, name, price, image } = req.body;

        if (!categoryId || !name || price === undefined) {
            return res.status(400).json({ error: 'Category ID, name, and price are required' });
        }

        const dish = await prisma.dish.create({
            data: {
                categoryId: parseInt(categoryId),
                name,
                price: parseFloat(price),
                image,
            },
            include: { category: true },
        });

        res.status(201).json(dish);
    } catch (error) {
        console.error('Create dish error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Update dish
exports.update = async (req, res) => {
    try {
        const { id } = req.params;
        const { categoryId, name, price, image } = req.body;

        const updateData = {};
        if (categoryId) updateData.categoryId = parseInt(categoryId);
        if (name) updateData.name = name;
        if (price !== undefined) updateData.price = parseFloat(price);
        if (image !== undefined) updateData.image = image;

        const dish = await prisma.dish.update({
            where: { id: parseInt(id) },
            data: updateData,
            include: { category: true },
        });

        res.json(dish);
    } catch (error) {
        console.error('Update dish error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Delete dish
exports.delete = async (req, res) => {
    try {
        const { id } = req.params;
        await prisma.dish.delete({ where: { id: parseInt(id) } });
        res.json({ message: 'Dish deleted successfully' });
    } catch (error) {
        console.error('Delete dish error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};
