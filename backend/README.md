# Flutter POS Backend API

Backend API server for Flutter POS application built with Node.js, Express, and Prisma ORM.

## Features

- ✅ JWT Authentication
- ✅ User Management (Admin only)
- ✅ Floor & Table Management
- ✅ Menu Management (Categories & Dishes)
- ✅ Table Booking & Checkout with hourly billing
- ✅ Order Management
- ✅ Reporting (Revenue, Orders, Table Usage)

## Tech Stack

- **Runtime**: Node.js
- **Framework**: Express.js
- **ORM**: Prisma
- **Database**: MySQL
- **Authentication**: JWT (jsonwebtoken)
- **Password Hashing**: bcrypt

## Installation

```bash
# Install dependencies
npm install

# Generate Prisma Client
npm run prisma:generate

# Run database migrations
npm run prisma:migrate

# Start development server
npm run dev

# Start production server
npm start
```

## Environment Variables

Create a `.env` file in the backend directory:

```env
DATABASE_URL="mysql://flutterpos:Thanhlam2025@203.205.33.59:33066/flutterpos"
JWT_SECRET="your-secret-key-change-this-in-production"
JWT_EXPIRES_IN="7d"
PORT=3000
NODE_ENV="development"
```

## API Endpoints

### Authentication
- `POST /api/auth/login` - Login with username/password
- `POST /api/auth/logout` - Logout
- `GET /api/auth/me` - Get current user info (requires auth)

### Users (Admin only)
- `GET /api/users` - Get all users
- `GET /api/users/:id` - Get user by ID
- `POST /api/users` - Create new user
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user

### Floors
- `GET /api/floors` - Get all floors
- `GET /api/floors/:id` - Get floor by ID
- `POST /api/floors` - Create floor
- `PUT /api/floors/:id` - Update floor
- `DELETE /api/floors/:id` - Delete floor

### Tables
- `GET /api/tables?floorId=1` - Get all tables (optional filter by floor)
- `GET /api/tables/:id` - Get table by ID with active session
- `POST /api/tables` - Create table
- `PUT /api/tables/:id` - Update table
- `DELETE /api/tables/:id` - Delete table
- `POST /api/tables/:id/book` - Book table (start session)
- `POST /api/tables/:id/checkout` - Checkout table (end session, calculate charges)

### Menu
- `GET /api/menu/categories` - Get all categories
- `POST /api/menu/categories` - Create category
- `PUT /api/menu/categories/:id` - Update category
- `DELETE /api/menu/categories/:id` - Delete category
- `GET /api/menu/dishes?categoryId=1` - Get all dishes (optional filter by category)
- `POST /api/menu/dishes` - Create dish
- `PUT /api/menu/dishes/:id` - Update dish
- `DELETE /api/menu/dishes/:id` - Delete dish

### Orders
- `GET /api/orders?tableId=1&status=PENDING&startDate=2024-01-01&endDate=2024-12-31` - Get orders with filters
- `POST /api/orders` - Create order
- `PUT /api/orders/:id/status` - Update order status

### Reports
- `GET /api/reports/revenue?startDate=2024-01-01&endDate=2024-12-31` - Revenue report
- `GET /api/reports/orders?startDate=2024-01-01&endDate=2024-12-31` - Order statistics
- `GET /api/reports/tables?startDate=2024-01-01&endDate=2024-12-31` - Table usage report

## Database Schema

See `prisma/schema.prisma` for complete schema.

### Main Models:
- **User**: Authentication and authorization
- **Floor**: Organize tables by floors/areas
- **Table**: Tables with position, hourly rate, and status
- **Category**: Menu categories
- **Dish**: Menu items
- **TableSession**: Track table usage time
- **Order**: Customer orders
- **OrderItem**: Items in an order
- **Payment**: Payment records

## Default Admin User

After running migrations, create an admin user manually or use Prisma Studio:

```bash
npm run prisma:studio
```

Then create a user with:
- username: admin
- password: (hashed with bcrypt)
- role: ADMIN

## Development

```bash
# Watch mode with auto-reload
npm run dev

# Open Prisma Studio (database GUI)
npm run prisma:studio

# Create new migration
npx prisma migrate dev --name migration_name
```

## Testing

Use Postman, curl, or any HTTP client to test endpoints.

Example login:
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"your_password"}'
```

Use the returned token in subsequent requests:
```bash
curl -X GET http://localhost:3000/api/floors \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## License

MIT
