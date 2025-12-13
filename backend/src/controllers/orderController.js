const prisma = require('../config/database');

// Get all orders (with filters)
exports.getAll = async (req, res) => {
    try {
        const { tableId, tableSessionId, status, startDate, endDate } = req.query;

        const where = {};
        if (tableId) where.tableId = parseInt(tableId);
        if (tableSessionId) where.tableSessionId = parseInt(tableSessionId);
        if (status) where.status = status;
        if (startDate || endDate) {
            where.createdAt = {};
            if (startDate) where.createdAt.gte = new Date(startDate);
            if (endDate) where.createdAt.lte = new Date(endDate);
        }

        const orders = await prisma.order.findMany({
            where,
            include: {
                table: { select: { id: true, name: true } },
                items: {
                    include: { dish: true },
                },
            },
            orderBy: { createdAt: 'desc' },
        });

        res.json(orders);
    } catch (error) {
        console.error('Get orders error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Create order
exports.create = async (req, res) => {
    try {
        const { tableId, tableSessionId, items, discountRate } = req.body;

        if (!tableId || !items || items.length === 0) {
            return res.status(400).json({ error: 'Table ID and items are required' });
        }

        // Calculate total
        let total = 0;
        const orderItems = [];

        for (const item of items) {
            const dish = await prisma.dish.findUnique({ where: { id: item.dishId } });
            if (!dish) {
                return res.status(400).json({ error: `Dish ${item.dishId} not found` });
            }
            const itemTotal = dish.price * item.quantity;
            total += itemTotal;
            orderItems.push({
                dishId: item.dishId,
                quantity: item.quantity,
                price: dish.price,
            });
        }

        total *= (discountRate || 1.0);

        const order = await prisma.order.create({
            data: {
                tableId: parseInt(tableId),
                tableSessionId: tableSessionId ? parseInt(tableSessionId) : null,
                total,
                discountRate: discountRate || 1.0,
                items: {
                    create: orderItems,
                },
            },
            include: {
                items: {
                    include: { dish: true },
                },
            },
        });

        res.status(201).json(order);
    } catch (error) {
        console.error('Create order error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Update order status
exports.updateStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        const order = await prisma.order.update({
            where: { id: parseInt(id) },
            data: { status },
            include: {
                items: {
                    include: { dish: true },
                },
            },
        });

        res.json(order);
    } catch (error) {
        console.error('Update order error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};
