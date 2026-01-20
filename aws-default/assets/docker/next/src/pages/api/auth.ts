import { NextApiRequest, NextApiResponse } from 'next';

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method === 'POST') {
    const { username, password } = req.body;
    
    // Имитация проверки логина
    if (username === 'demo' && password === 'password123') {
      const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyXzEyMyIsImlhdCI6MTY0NjA2NDAwMCwiZXhwIjoxNjQ2MDY3NjAwfQ.demo_token';
      
      res.status(200).json({
        success: true,
        message: 'Login successful',
        token: token,
        user: {
          id: 'user_123',
          username: 'demo',
          email: 'demo@example.com'
        },
        expiresIn: '1h'
      });
    } else {
      res.status(401).json({
        success: false,
        message: 'Invalid username or password'
      });
    }
  } else if (req.method === 'DELETE') {
    // Logout
    res.status(200).json({
      success: true,
      message: 'Logout successful'
    });
  } else {
    res.setHeader('Allow', ['POST', 'DELETE']);
    res.status(405).end(`Method ${req.method} Not Allowed`);
  }
}
