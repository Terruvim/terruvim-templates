import { NextApiRequest, NextApiResponse } from 'next';

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method === 'GET') {
    // Имитируем данные о статусе пользователя
    const userStatus = {
      id: 'user_123',
      username: 'demo_user',
      isAuthenticated: true,
      lastLogin: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(), // 2 часа назад
      permissions: ['read', 'write'],
      profile: {
        email: 'demo@example.com',
        firstName: 'Demo',
        lastName: 'User',
        avatar: null
      },
      preferences: {
        theme: 'light',
        language: 'en',
        notifications: true
      }
    };

    res.status(200).json(userStatus);
  } else if (req.method === 'PUT') {
    // Обновление настроек пользователя
    const { preferences } = req.body;
    
    res.status(200).json({
      message: 'User preferences updated successfully',
      preferences: preferences || {
        theme: 'light',
        language: 'en',
        notifications: true
      }
    });
  } else {
    res.setHeader('Allow', ['GET', 'PUT']);
    res.status(405).end(`Method ${req.method} Not Allowed`);
  }
}
