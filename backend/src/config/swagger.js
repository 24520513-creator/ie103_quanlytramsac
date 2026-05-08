const swaggerJsdoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'EV Charging Network Management API',
      version: '2.0.0',
      description: 'API documentation for the EV Charging Station Network and Franchise Management System',
      contact: {
        name: 'Development Team',
        email: 'dev@evcharger.com',
      },
    },
    servers: [
      {
        url: `http://localhost:${process.env.PORT || 3000}`,
        description: 'Development server',
      },
    ],
    components: {
      securitySchemes: {
        BearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'Enter JWT token obtained from signup or signin',
        },
      },
      schemas: {
        SignUpRequest: {
          type: 'object',
          required: ['FullName', 'Email', 'Password'],
          properties: {
            FullName: {
              type: 'string',
              example: 'Nguyen Van A',
              description: 'User full name',
            },
            Email: {
              type: 'string',
              format: 'email',
              example: 'user@example.com',
              description: 'User email address',
            },
            Phone: {
              type: 'string',
              example: '0912345678',
              description: 'User phone number (optional)',
            },
            Password: {
              type: 'string',
              minLength: 6,
              example: 'password123',
              description: 'User password (min 6 characters)',
            },
          },
        },
        SignInRequest: {
          type: 'object',
          required: ['Email', 'Password'],
          properties: {
            Email: {
              type: 'string',
              format: 'email',
              example: 'user@example.com',
            },
            Password: {
              type: 'string',
              example: 'password123',
            },
          },
        },
        AuthResponse: {
          type: 'object',
          properties: {
            success: { type: 'boolean', example: true },
            message: { type: 'string', example: 'Registration successful' },
            data: {
              type: 'object',
              properties: {
                token: {
                  type: 'string',
                  example: 'eyJhbGciOiJIUzI1NiIs...',
                },
                user: {
                  type: 'object',
                  properties: {
                    UserID: { type: 'integer', example: 1 },
                    Email: { type: 'string', example: 'user@example.com' },
                    FullName: { type: 'string', example: 'Nguyen Van A' },
                    Phone: { type: 'string', example: '0912345678' },
                  },
                },
              },
            },
          },
        },
        ErrorResponse: {
          type: 'object',
          properties: {
            success: { type: 'boolean', example: false },
            message: { type: 'string', example: 'Error description' },
            error: { type: 'string', example: 'Error description' },
          },
        },
        User: {
          type: 'object',
          properties: {
            UserID: { type: 'integer', example: 1 },
            Email: { type: 'string', example: 'user@example.com' },
            Phone: { type: 'string', example: '0912345678' },
            FullName: { type: 'string', example: 'Nguyen Van A' },
            AccountStatus: { type: 'string', example: 'Active' },
            CreatedAt: { type: 'string', format: 'date-time' },
          },
        },
        ChargingStation: {
          type: 'object',
          properties: {
            StationID: { type: 'integer', example: 1 },
            StationCode: { type: 'string', example: 'STN001' },
            StationName: { type: 'string', example: 'VinFast Trần Duy Hưng' },
            Address: { type: 'string', example: '119 Trần Duy Hưng, Cầu Giấy, Hà Nội' },
            Status: { type: 'string', example: 'Active' },
          },
        },
      },
    },
    tags: [
      { name: 'Authentication', description: 'Auth endpoints (signup, signin)' },
      { name: 'Test', description: 'Test and health-check endpoints' },
    ],
  },
  apis: [
    './src/routes/auth.routes.js',
    './src/routes/test.routes.js',
  ],
};

const swaggerSpec = swaggerJsdoc(options);

module.exports = swaggerSpec;
