const bcrypt = require('bcrypt');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function seed() {
    try {
        console.log('🌱 Seeding database...');

        // Create admin user
        const hashedPassword = await bcrypt.hash('admin123', 10);
        const admin = await prisma.user.upsert({
            where: { username: 'admin' },
            update: {},
            create: {
                username: 'admin',
                password: hashedPassword,
                role: 'ADMIN',
            },
        });
        console.log('✅ Created admin user:', admin.username);

        // Create sample floor
        const floor1 = await prisma.floor.upsert({
            where: { id: 1 },
            update: {},
            create: {
                name: 'Tầng 1',
                order: 1,
            },
        });
        console.log('✅ Created floor:', floor1.name);

        // Create sample category
        const category1 = await prisma.category.upsert({
            where: { id: 1 },
            update: {},
            create: {
                name: 'Đồ uống',
                order: 1,
            },
        });
        console.log('✅ Created category:', category1.name);

        // Create sample dish
        const dish1 = await prisma.dish.upsert({
            where: { id: 1 },
            update: {},
            create: {
                categoryId: category1.id,
                name: 'Cà phê đen',
                price: 25000,
            },
        });
        console.log('✅ Created dish:', dish1.name);

        console.log('🎉 Seeding completed!');
        console.log('\nDefault credentials:');
        console.log('Username: admin');
        console.log('Password: admin123');
    } catch (error) {
        console.error('❌ Seeding failed:', error);
        process.exit(1);
    } finally {
        await prisma.$disconnect();
    }
}

seed();
