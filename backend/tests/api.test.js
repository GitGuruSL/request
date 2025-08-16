const request = require('supertest');
const app = require('../server');

describe('API Health Check', () => {
    test('GET /health should return healthy status', async () => {
        const response = await request(app)
            .get('/health')
            .expect(200);

        expect(response.body.status).toBe('healthy');
        expect(response.body.database).toBeDefined();
    });
});

describe('Authentication API', () => {
    test('POST /api/auth/register should require email or phone', async () => {
        const response = await request(app)
            .post('/api/auth/register')
            .send({
                displayName: 'Test User'
            })
            .expect(400);

        expect(response.body.success).toBe(false);
        expect(response.body.error).toContain('email or phone');
    });

    test('POST /api/auth/login should require email or phone', async () => {
        const response = await request(app)
            .post('/api/auth/login')
            .send({
                password: 'testpassword'
            })
            .expect(401);

        expect(response.body.success).toBe(false);
    });
});

describe('Categories API', () => {
    test('GET /api/categories should return categories', async () => {
        const response = await request(app)
            .get('/api/categories')
            .expect(200);

        expect(response.body.success).toBe(true);
        expect(Array.isArray(response.body.data)).toBe(true);
    });

    test('GET /api/categories with country filter', async () => {
        const response = await request(app)
            .get('/api/categories?country=LK')
            .expect(200);

        expect(response.body.success).toBe(true);
        expect(Array.isArray(response.body.data)).toBe(true);
    });
});

// Cleanup after tests
afterAll(async () => {
    // Close database connections
    const dbService = require('../services/database');
    await dbService.close();
});
