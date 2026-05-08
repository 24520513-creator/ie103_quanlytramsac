# EV Charging Network Management System - Backend

Hệ thống quản lý mạng lưới trạm sạc xe điện và doanh nghiệp nhượng quyền

## Tech Stack

- **Runtime:** Node.js
- **Framework:** Express.js
- **Database:** Microsoft SQL Server
- **Authentication:** JWT + bcrypt
- **Documentation:** Swagger UI / OpenAPI

## Project Structure

```
backend/
├── src/
│   ├── config/
│   │   ├── db.js              # Database connection (mssql)
│   │   └── swagger.js         # Swagger/OpenAPI configuration
│   ├── controllers/
│   │   ├── auth.controller.js # Signup, Signin handlers
│   │   └── test.controller.js # Test route handlers
│   ├── middleware/
│   │   ├── auth.middleware.js  # JWT verification
│   │   └── error.middleware.js # Centralized error handler
│   ├── routes/
│   │   ├── auth.routes.js     # POST /api/auth/signup, /signin
│   │   └── test.routes.js     # GET /api/test/*
│   ├── services/
│   │   └── auth.service.js    # Auth business logic
│   ├── utils/
│   │   ├── jwt.js             # JWT token utilities
│   │   └── response.js        # Standardized response helpers
│   ├── app.js                 # Express app setup
│   └── server.js              # Entry point
├── .env
├── package.json
└── README.md
```

## Installation

```bash
npm install
```

## Environment Setup

Create a `.env` file in the `backend/` directory:

```env
PORT=3000

DB_SERVER=localhost
DB_PORT=1433
DB_USER=sa
DB_PASSWORD=your_password
DB_NAME=EV_Charging_System

JWT_SECRET=your-super-secret-key
JWT_EXPIRES_IN=8h

BCRYPT_SALT_ROUNDS=12
```

## Run Commands

```bash
# Development (with nodemon)
npm run dev

# Production
npm start
```

## API Endpoints

### Authentication

| Method | Endpoint             | Description      | Auth Required |
|--------|----------------------|------------------|---------------|
| POST   | `/api/auth/signup`   | Register new user | No            |
| POST   | `/api/auth/signin`   | Sign in           | No            |

### Test Routes

| Method | Endpoint                | Description                 | Auth Required |
|--------|-------------------------|-----------------------------|---------------|
| GET    | `/api/test/testdb`      | Test database connection    | No            |
| GET    | `/api/test/customers`   | Get top 10 customers        | No            |
| GET    | `/api/test/stations`    | Get top 10 charging stations | No            |
| GET    | `/api/test/protected`   | Test JWT-protected route    | Yes           |

## Swagger Documentation

Visit `http://localhost:3000/api-docs` when the server is running.

## API Examples

### Signup

```bash
curl -X POST http://localhost:3000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "FullName": "Nguyen Van A",
    "Email": "user@example.com",
    "Phone": "0912345678",
    "Password": "password123"
  }'
```

### Signin

```bash
curl -X POST http://localhost:3000/api/auth/signin \
  -H "Content-Type: application/json" \
  -d '{
    "Email": "user@example.com",
    "Password": "password123"
  }'
```

### Protected Route

```bash
curl http://localhost:3000/api/test/protected \
  -H "Authorization: Bearer <your-jwt-token>"
```

### Test Database

```bash
curl http://localhost:3000/api/test/testdb
```

## Response Format

**Success:**
```json
{
  "success": true,
  "message": "Registration successful",
  "data": { ... }
}
```

**Error:**
```json
{
  "success": false,
  "message": "Error description",
  "error": "Error description"
}
```
