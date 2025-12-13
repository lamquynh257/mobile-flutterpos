const prisma = require('../config/database');

// Revenue report
exports.revenue = async (req, res) => {
    try {
        const { startDate, endDate } = req.query;

        const where = {};
        if (startDate || endDate) {
            where.paidAt = {};
            if (startDate) where.paidAt.gte = new Date(startDate);
            if (endDate) where.paidAt.lte = new Date(endDate);
        }

        const payments = await prisma.payment.findMany({
            where,
            include: {
                order: {
                    include: {
                        items: {
                            include: { dish: true },
                        },
                    },
                },
                tableSession: {
                    include: {
                        table: true,
                    },
                },
            },
            orderBy: { paidAt: 'desc' },
        });

        const totalRevenue = payments.reduce((sum, payment) => sum + payment.amount, 0);

        res.json({
            totalRevenue,
            paymentCount: payments.length,
            payments,
        });
    } catch (error) {
        console.error('Revenue report error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Order statistics
exports.orders = async (req, res) => {
    try {
        const { startDate, endDate } = req.query;

        const where = {};
        if (startDate || endDate) {
            where.createdAt = {};
            if (startDate) where.createdAt.gte = new Date(startDate);
            if (endDate) where.createdAt.lte = new Date(endDate);
        }

        const orders = await prisma.order.findMany({
            where,
            include: {
                items: {
                    include: { dish: true },
                },
            },
        });

        // Calculate popular dishes
        const dishStats = {};
        orders.forEach(order => {
            order.items.forEach(item => {
                if (!dishStats[item.dishId]) {
                    dishStats[item.dishId] = {
                        dish: item.dish,
                        quantity: 0,
                        revenue: 0,
                    };
                }
                dishStats[item.dishId].quantity += item.quantity;
                dishStats[item.dishId].revenue += item.price * item.quantity;
            });
        });

        const popularDishes = Object.values(dishStats)
            .sort((a, b) => b.quantity - a.quantity)
            .slice(0, 10);

        res.json({
            totalOrders: orders.length,
            popularDishes,
        });
    } catch (error) {
        console.error('Order report error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Table usage report
exports.tables = async (req, res) => {
    try {
        const { startDate, endDate } = req.query;

        const where = {};
        if (startDate || endDate) {
            where.startTime = {};
            if (startDate) where.startTime.gte = new Date(startDate);
            if (endDate) where.startTime.lte = new Date(endDate);
        }

        const sessions = await prisma.tableSession.findMany({
            where,
            include: {
                table: true,
            },
        });

        const tableStats = {};
        sessions.forEach(session => {
            if (!tableStats[session.tableId]) {
                tableStats[session.tableId] = {
                    table: session.table,
                    sessionCount: 0,
                    totalHours: 0,
                    totalRevenue: 0,
                };
            }
            tableStats[session.tableId].sessionCount++;
            tableStats[session.tableId].totalHours += session.totalHours || 0;
            tableStats[session.tableId].totalRevenue += session.hourlyCharge || 0;
        });

        res.json({
            tableUsage: Object.values(tableStats),
        });
    } catch (error) {
        console.error('Table report error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};
