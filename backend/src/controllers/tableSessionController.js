// Get all completed sessions for reporting
exports.getCompletedSessions = async (req, res) => {
    try {
        const sessions = await prisma.tableSession.findMany({
            where: {
                endTime: {
                    not: null, // Only completed sessions
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
                endTime: 'desc', // Most recent first
            },
        });

        res.json(sessions);
    } catch (error) {
        console.error('Get completed sessions error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
};
