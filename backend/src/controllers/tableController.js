const prisma = require('../config/database');

// Get all tables (optionally filter by floor)
exports.getAll = async (req, res) => {
    try {
        const { floorId } = req.query;
        const where = floorId ? { floorId: parseInt(floorId) } : {};

        const tables = await prisma.table.findMany({
            where,
            include: {
                floor: { select: { id: true, name: true } },
                sessions: {
                    where: { endTime: null },
                    select: { id: true, startTime: true },
                },
            },
            orderBy: { id: 'asc' },
        });

        res.json(tables);
    } catch (error) {
        console.error('Get tables error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Get table by ID
exports.getById = async (req, res) => {
    try {
        const { id } = req.params;
        const table = await prisma.table.findUnique({
            where: { id: parseInt(id) },
            include: {
                floor: true,
                sessions: {
                    where: { endTime: null },
                    include: {
                        orders: {
                            include: {
                                items: {
                                    include: { dish: true },
                                },
                            },
                        },
                    },
                },
            },
        });

        if (!table) {
            return res.status(404).json({ error: 'Table not found' });
        }

        res.json(table);
    } catch (error) {
        console.error('Get table error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Create table
exports.create = async (req, res) => {
    try {
        const { floorId, name, x, y, hourlyRate } = req.body;

        if (!floorId || !name) {
            return res.status(400).json({ error: 'Floor ID and name are required' });
        }

        const table = await prisma.table.create({
            data: {
                floorId: parseInt(floorId),
                name,
                x: x || 0,
                y: y || 0,
                hourlyRate: hourlyRate || 0,
            },
            include: { floor: true },
        });

        res.status(201).json(table);
    } catch (error) {
        console.error('Create table error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Update table
exports.update = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, x, y, hourlyRate, status } = req.body;

        const table = await prisma.table.update({
            where: { id: parseInt(id) },
            data: { name, x, y, hourlyRate, status },
            include: { floor: true },
        });

        res.json(table);
    } catch (error) {
        console.error('Update table error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Delete table
exports.delete = async (req, res) => {
    try {
        const { id } = req.params;

        await prisma.table.delete({
            where: { id: parseInt(id) },
        });

        res.json({ message: 'Table deleted successfully' });
    } catch (error) {
        console.error('Delete table error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Book table (start session)
exports.book = async (req, res) => {
    try {
        const { id } = req.params;

        // Check if table is already occupied
        const table = await prisma.table.findUnique({
            where: { id: parseInt(id) },
            include: {
                sessions: {
                    where: { endTime: null },
                },
            },
        });

        if (!table) {
            return res.status(404).json({ error: 'Table not found' });
        }

        if (table.status === 'OCCUPIED' || table.sessions.length > 0) {
            return res.status(400).json({ error: 'Table is already occupied' });
        }

        // Create new session and update table status
        const session = await prisma.tableSession.create({
            data: {
                tableId: parseInt(id),
            },
        });

        await prisma.table.update({
            where: { id: parseInt(id) },
            data: { status: 'OCCUPIED' },
        });

        res.json({ session, message: 'Table booked successfully' });
    } catch (error) {
        console.error('Book table error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};

// Checkout table (end session and calculate charges)
exports.checkout = async (req, res) => {
    try {
        const { id } = req.params;

        // Find active session
        const table = await prisma.table.findUnique({
            where: { id: parseInt(id) },
            include: {
                sessions: {
                    where: { endTime: null },
                    include: {
                        orders: {
                            include: {
                                items: {
                                    include: { dish: true },
                                },
                            },
                        },
                    },
                },
            },
        });

        if (!table || table.sessions.length === 0) {
            return res.status(400).json({ error: 'No active session found' });
        }

        const session = table.sessions[0];
        const endTime = new Date();
        const startTime = new Date(session.startTime);
        const totalHours = (endTime - startTime) / (1000 * 60 * 60); // Convert ms to hours
        const hourlyCharge = totalHours * table.hourlyRate;

        // Calculate order total
        const orderTotal = session.orders.reduce((sum, order) => {
            return sum + order.items.reduce((orderSum, item) => {
                return orderSum + (item.price * item.quantity);
            }, 0);
        }, 0);

        // Update session
        const updatedSession = await prisma.tableSession.update({
            where: { id: session.id },
            data: {
                endTime,
                totalHours,
                hourlyCharge,
            },
        });

        // Update table status
        await prisma.table.update({
            where: { id: parseInt(id) },
            data: { status: 'EMPTY' },
        });

        res.json({
            session: updatedSession,
            hourlyCharge,
            orderTotal,
            grandTotal: hourlyCharge + orderTotal,
            message: 'Checkout completed',
        });
    } catch (error) {
        console.error('Checkout error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};
