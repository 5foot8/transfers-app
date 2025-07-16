import express from 'express';

const router = express.Router();

// Mock user data for testing
const users = [
  {
    id: '1',
    email: 'admin@example.com',
    name: 'Admin User',
    role: 'admin',
    createdAt: new Date().toISOString()
  }
];

// Login endpoint (mock - in real app this would verify Firebase token)
router.post('/login', (req, res) => {
  const { email, password } = req.body;
  
  // Mock authentication - accept any valid email format
  if (email && password) {
    const user = users.find(u => u.email === email) || {
      id: Date.now().toString(),
      email,
      name: email.split('@')[0],
      role: 'user',
      createdAt: new Date().toISOString()
    };
    
    res.json({
      user,
      token: 'mock-jwt-token-' + Date.now()
    });
  } else {
    res.status(400).json({ error: 'Email and password required' });
  }
});

// Register endpoint (mock)
router.post('/register', (req, res) => {
  const { email, name, password } = req.body;
  
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password required' });
  }
  
  const existingUser = users.find(u => u.email === email);
  if (existingUser) {
    return res.status(400).json({ error: 'User already exists' });
  }
  
  const newUser = {
    id: Date.now().toString(),
    email,
    name: name || email.split('@')[0],
    role: 'user',
    createdAt: new Date().toISOString()
  };
  
  users.push(newUser);
  
  res.status(201).json({
    user: newUser,
    token: 'mock-jwt-token-' + Date.now()
  });
});

// Get user profile (mock)
router.get('/profile', (req, res) => {
  // In a real app, this would verify the JWT token
  const authHeader = req.headers.authorization;
  
  if (!authHeader) {
    return res.status(401).json({ error: 'No token provided' });
  }
  
  // Mock user - in real app this would decode the JWT
  const mockUser = {
    id: '1',
    email: 'admin@example.com',
    name: 'Admin User',
    role: 'admin',
    createdAt: new Date().toISOString()
  };
  
  res.json(mockUser);
});

// Verify token endpoint (mock)
router.post('/verify', (req, res) => {
  const { token } = req.body;
  
  if (!token) {
    return res.status(400).json({ error: 'Token required' });
  }
  
  // Mock verification - accept any token
  res.json({
    valid: true,
    user: {
      id: '1',
      email: 'admin@example.com',
      name: 'Admin User',
      role: 'admin'
    }
  });
});

export { router as authRouter }; 